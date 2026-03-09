import 'package:flutter_test/flutter_test.dart';
import 'package:help_to_cook/features/recipes/domain/chef_rules.dart';

void main() {
  test('chef rules reward aromatic base and shelf seasonings for soup', () {
    final assessment = assessChefRules(
      profile: DishProfile.soup,
      recipeCanonicals: const {'курица', 'картофель', 'лук', 'морковь'},
      matchedCanonicals: const {'курица', 'картофель', 'лук', 'морковь'},
      supportCanonicals: const {'соль', 'перец', 'укроп'},
      displayByCanonical: const {
        'курица': 'Курица',
        'картофель': 'Картофель',
        'лук': 'Лук',
        'морковь': 'Морковь',
        'соль': 'Соль',
        'перец': 'Перец',
        'укроп': 'Укроп',
      },
      steps: const [
        'Нарежь овощи и курицу.',
        'Вари на умеренном огне до мягкости.',
        'Подавай с укропом.',
      ],
    );

    expect(assessment.structureScore, greaterThan(0.7));
    expect(assessment.seasoningScore, greaterThan(0.6));
    expect(assessment.techniqueScore, greaterThan(0.6));
    expect(
      assessment.reasons.any((reason) => reason.contains('ароматическая база')),
      isTrue,
    );
    expect(
      assessment.reasons
          .any((reason) => reason.contains('полка усиливает вкус')),
      isTrue,
    );
  });

  test('chef rules penalize structurally weak dish', () {
    final assessment = assessChefRules(
      profile: DishProfile.skillet,
      recipeCanonicals: const {'соль', 'сахар'},
      matchedCanonicals: const {'соль', 'сахар'},
      supportCanonicals: const {},
      displayByCanonical: const {
        'соль': 'Соль',
        'сахар': 'Сахар',
      },
      steps: const ['Смешай и подай.'],
    );

    expect(assessment.score, lessThan(0.45));
    expect(
      assessment.warnings,
      contains('не хватает опорного ингредиента'),
    );
  });

  test('chef rules penalize salad without dressing support', () {
    final weakSalad = assessChefRules(
      profile: DishProfile.salad,
      recipeCanonicals: const {'огурец', 'помидор'},
      matchedCanonicals: const {'огурец', 'помидор'},
      supportCanonicals: const {},
      displayByCanonical: const {
        'огурец': 'Огурец',
        'помидор': 'Помидор',
      },
      steps: const ['Нарежь овощи.', 'Смешай и подай.'],
    );

    final balancedSalad = assessChefRules(
      profile: DishProfile.salad,
      recipeCanonicals: const {'огурец', 'помидор'},
      matchedCanonicals: const {'огурец', 'помидор'},
      supportCanonicals: const {'оливковое масло', 'лимон', 'соль'},
      displayByCanonical: const {
        'огурец': 'Огурец',
        'помидор': 'Помидор',
        'оливковое масло': 'Оливковое масло',
        'лимон': 'Лимон',
        'соль': 'Соль',
      },
      steps: const ['Нарежь овощи.', 'Смешай и заправь перед подачей.'],
    );

    expect(
      weakSalad.warnings,
      contains('для салата не хватает заправки или соуса'),
    );
    expect(weakSalad.score, lessThan(balancedSalad.score));
    expect(balancedSalad.balanceScore, greaterThan(weakSalad.balanceScore));
  });

  test('chef rules reward flavor-balanced pasta over dry neutral base', () {
    final balancedPasta = assessChefRules(
      profile: DishProfile.pasta,
      recipeCanonicals: const {'макароны', 'сыр', 'помидор'},
      matchedCanonicals: const {'макароны', 'сыр', 'помидор'},
      supportCanonicals: const {'оливковое масло', 'соль'},
      displayByCanonical: const {
        'макароны': 'Макароны',
        'сыр': 'Сыр',
        'помидор': 'Помидор',
        'оливковое масло': 'Оливковое масло',
        'соль': 'Соль',
      },
      steps: const [
        'Отвари макароны.',
        'Смешай с сыром и томатами.',
        'Подавай.'
      ],
    );

    final dryPasta = assessChefRules(
      profile: DishProfile.pasta,
      recipeCanonicals: const {'макароны'},
      matchedCanonicals: const {'макароны'},
      supportCanonicals: const {'соль'},
      displayByCanonical: const {
        'макароны': 'Макароны',
        'соль': 'Соль',
      },
      steps: const ['Отвари макароны.', 'Подавай.'],
    );

    expect(balancedPasta.flavorScore, greaterThan(dryPasta.flavorScore));
    expect(balancedPasta.score, greaterThan(dryPasta.score));
    expect(
      dryPasta.warnings.any((warning) => warning.contains('не хватает')),
      isTrue,
    );
  });

  test('chef rules penalize chicken skillet without proper heat treatment', () {
    final weakSkillet = assessChefRules(
      profile: DishProfile.skillet,
      recipeCanonicals: const {'курица', 'лук'},
      matchedCanonicals: const {'курица', 'лук'},
      supportCanonicals: const {'соль', 'перец'},
      displayByCanonical: const {
        'курица': 'Курица',
        'лук': 'Лук',
        'соль': 'Соль',
        'перец': 'Перец',
      },
      steps: const [
        'Нарежь курицу и лук.',
        'Смешай и подай.',
      ],
    );

    final properSkillet = assessChefRules(
      profile: DishProfile.skillet,
      recipeCanonicals: const {'курица', 'лук'},
      matchedCanonicals: const {'курица', 'лук'},
      supportCanonicals: const {'соль', 'перец'},
      displayByCanonical: const {
        'курица': 'Курица',
        'лук': 'Лук',
        'соль': 'Соль',
        'перец': 'Перец',
      },
      steps: const [
        'Нарежь курицу и лук.',
        'Обжарь курицу до готовности, затем добавь лук.',
        'Приправь и подавай горячей.',
      ],
    );

    expect(
        properSkillet.techniqueScore, greaterThan(weakSkillet.techniqueScore));
    expect(properSkillet.score, greaterThan(weakSkillet.score));
    expect(
      weakSkillet.warnings,
      contains('основному белку не хватает явной термообработки до готовности'),
    );
  });

  test('chef rules reward baked fish with acid and moisture protection', () {
    final weakBake = assessChefRules(
      profile: DishProfile.bake,
      recipeCanonicals: const {'рыба', 'картофель'},
      matchedCanonicals: const {'рыба', 'картофель'},
      supportCanonicals: const {'соль'},
      displayByCanonical: const {
        'рыба': 'Рыба',
        'картофель': 'Картофель',
        'соль': 'Соль',
      },
      steps: const [
        'Выложи рыбу и картофель в форму.',
        'Запекай и подай.',
      ],
    );

    final strongBake = assessChefRules(
      profile: DishProfile.bake,
      recipeCanonicals: const {'рыба', 'картофель', 'лимон', 'масло'},
      matchedCanonicals: const {'рыба', 'картофель', 'лимон', 'масло'},
      supportCanonicals: const {'соль', 'перец'},
      displayByCanonical: const {
        'рыба': 'Рыба',
        'картофель': 'Картофель',
        'лимон': 'Лимон',
        'масло': 'Масло',
        'соль': 'Соль',
        'перец': 'Перец',
      },
      steps: const [
        'Сбрызни рыбу лимоном и маслом.',
        'Накрой форму и запекай до готовности.',
        'Открой форму, дай слегка подрумяниться и подай.',
      ],
    );

    expect(strongBake.techniqueScore, greaterThan(weakBake.techniqueScore));
    expect(strongBake.flavorScore, greaterThan(weakBake.flavorScore));
    expect(strongBake.score, greaterThan(weakBake.score));
    expect(
      weakBake.warnings.any((warning) => warning.contains('рыбе часто нужен')),
      isTrue,
    );
  });

  test('chef rules reward crunchy herby salad over soft flat salad', () {
    final livelySalad = assessChefRules(
      profile: DishProfile.salad,
      recipeCanonicals: const {'капуста', 'яблоко', 'йогурт', 'укроп'},
      matchedCanonicals: const {'капуста', 'яблоко', 'йогурт', 'укроп'},
      supportCanonicals: const {'соль'},
      displayByCanonical: const {
        'капуста': 'Капуста',
        'яблоко': 'Яблоко',
        'йогурт': 'Йогурт',
        'укроп': 'Укроп',
        'соль': 'Соль',
      },
      steps: const [
        'Нашинкуй капусту.',
        'Смешай с яблоком.',
        'Заправь йогуртом и укропом перед подачей.',
      ],
    );

    final flatSalad = assessChefRules(
      profile: DishProfile.salad,
      recipeCanonicals: const {'помидор', 'сыр'},
      matchedCanonicals: const {'помидор', 'сыр'},
      supportCanonicals: const {'соль'},
      displayByCanonical: const {
        'помидор': 'Помидор',
        'сыр': 'Сыр',
        'соль': 'Соль',
      },
      steps: const [
        'Нарежь помидор.',
        'Смешай с сыром и подай.',
      ],
    );

    expect(livelySalad.flavorScore, greaterThan(flatSalad.flavorScore));
    expect(livelySalad.score, greaterThan(flatSalad.score));
    expect(
      livelySalad.reasons.any((reason) => reason.contains('хруст')),
      isTrue,
    );
  });

  test('chef rules reward fish with herbs and acid over plain fish', () {
    final plainFish = assessChefRules(
      profile: DishProfile.bake,
      recipeCanonicals: const {'рыба', 'картофель'},
      matchedCanonicals: const {'рыба', 'картофель'},
      supportCanonicals: const {'соль'},
      displayByCanonical: const {
        'рыба': 'Рыба',
        'картофель': 'Картофель',
        'соль': 'Соль',
      },
      steps: const [
        'Выложи в форму.',
        'Запекай до готовности.',
        'Подавай.',
      ],
    );

    final brightFish = assessChefRules(
      profile: DishProfile.bake,
      recipeCanonicals: const {'рыба', 'лимон', 'укроп', 'сметана'},
      matchedCanonicals: const {'рыба', 'лимон', 'укроп', 'сметана'},
      supportCanonicals: const {'соль', 'перец'},
      displayByCanonical: const {
        'рыба': 'Рыба',
        'лимон': 'Лимон',
        'укроп': 'Укроп',
        'сметана': 'Сметана',
        'соль': 'Соль',
        'перец': 'Перец',
      },
      steps: const [
        'Сбрызни рыбу лимоном.',
        'Накрой и запекай до готовности.',
        'Доведи сметаной с укропом и подай.',
      ],
    );

    expect(brightFish.balanceScore, greaterThan(plainFish.balanceScore));
    expect(brightFish.flavorScore, greaterThan(plainFish.flavorScore));
    expect(brightFish.score, greaterThan(plainFish.score));
  });

  test('chef rules penalize sweet breakfast without fresh contrast', () {
    final flatBreakfast = assessChefRules(
      profile: DishProfile.breakfast,
      recipeCanonicals: const {'овсяные хлопья', 'молоко', 'сахар'},
      matchedCanonicals: const {'овсяные хлопья', 'молоко', 'сахар'},
      supportCanonicals: const {'соль'},
      displayByCanonical: const {
        'овсяные хлопья': 'Овсяные хлопья',
        'молоко': 'Молоко',
        'сахар': 'Сахар',
        'соль': 'Соль',
      },
      steps: const [
        'Свари кашу на молоке.',
        'Добавь сахар и подай.',
      ],
    );

    final brightBreakfast = assessChefRules(
      profile: DishProfile.breakfast,
      recipeCanonicals: const {
        'овсяные хлопья',
        'молоко',
        'апельсин',
        'корица'
      },
      matchedCanonicals: const {
        'овсяные хлопья',
        'молоко',
        'апельсин',
        'корица'
      },
      supportCanonicals: const {'соль'},
      displayByCanonical: const {
        'овсяные хлопья': 'Овсяные хлопья',
        'молоко': 'Молоко',
        'апельсин': 'Апельсин',
        'корица': 'Корица',
        'соль': 'Соль',
      },
      steps: const [
        'Свари кашу на молоке.',
        'Добавь апельсин и корицу вне сильного кипения.',
        'Подавай сразу.',
      ],
    );

    expect(
      flatBreakfast.warnings
          .any((warning) => warning.contains('свежего контраста')),
      isTrue,
    );
    expect(brightBreakfast.flavorScore, greaterThan(flatBreakfast.flavorScore));
    expect(brightBreakfast.score, greaterThan(flatBreakfast.score));
  });

  test('chef rules reward lentil soup with tomato depth and herbs', () {
    final flatSoup = assessChefRules(
      profile: DishProfile.soup,
      recipeCanonicals: const {'чечевица', 'вода'},
      matchedCanonicals: const {'чечевица'},
      supportCanonicals: const {'соль'},
      displayByCanonical: const {
        'чечевица': 'Чечевица',
        'соль': 'Соль',
      },
      steps: const [
        'Промой чечевицу.',
        'Вари до мягкости.',
        'Подавай.',
      ],
    );

    final strongSoup = assessChefRules(
      profile: DishProfile.soup,
      recipeCanonicals: const {
        'чечевица',
        'лук',
        'морковь',
        'томатная паста',
        'укроп',
      },
      matchedCanonicals: const {
        'чечевица',
        'лук',
        'морковь',
        'томатная паста',
      },
      supportCanonicals: const {'соль', 'перец', 'укроп'},
      displayByCanonical: const {
        'чечевица': 'Чечевица',
        'лук': 'Лук',
        'морковь': 'Морковь',
        'томатная паста': 'Томатная паста',
        'укроп': 'Укроп',
        'соль': 'Соль',
        'перец': 'Перец',
      },
      steps: const [
        'Прогрей лук и морковь.',
        'Добавь томатную пасту и чечевицу.',
        'Вари на умеренном огне до мягкости и подавай с укропом.',
      ],
    );

    expect(strongSoup.balanceScore, greaterThan(flatSoup.balanceScore));
    expect(strongSoup.flavorScore, greaterThan(flatSoup.flavorScore));
    expect(strongSoup.score, greaterThan(flatSoup.score));
    expect(
      flatSoup.warnings.any((warning) => warning.contains('бобовому супу')),
      isTrue,
    );
  });

  test('chef rules reward red meat with aromatics and warm spice', () {
    final flatMeat = assessChefRules(
      profile: DishProfile.stew,
      recipeCanonicals: const {'говядина', 'картофель'},
      matchedCanonicals: const {'говядина', 'картофель'},
      supportCanonicals: const {'соль'},
      displayByCanonical: const {
        'говядина': 'Говядина',
        'картофель': 'Картофель',
        'соль': 'Соль',
      },
      steps: const [
        'Сложи всё вместе.',
        'Туши до готовности.',
        'Подавай.',
      ],
    );

    final layeredMeat = assessChefRules(
      profile: DishProfile.stew,
      recipeCanonicals: const {
        'говядина',
        'лук',
        'грибы',
        'сметана',
        'паприка',
      },
      matchedCanonicals: const {
        'говядина',
        'лук',
        'грибы',
        'сметана',
        'паприка',
      },
      supportCanonicals: const {'соль', 'перец'},
      displayByCanonical: const {
        'говядина': 'Говядина',
        'лук': 'Лук',
        'грибы': 'Грибы',
        'сметана': 'Сметана',
        'паприка': 'Паприка',
        'соль': 'Соль',
        'перец': 'Перец',
      },
      steps: const [
        'Обжарь лук и грибы.',
        'Добавь говядину, паприку и мягко туши до готовности.',
        'В конце вмешай сметану и подавай.',
      ],
    );

    expect(layeredMeat.balanceScore, greaterThan(flatMeat.balanceScore));
    expect(layeredMeat.flavorScore, greaterThan(flatMeat.flavorScore));
    expect(layeredMeat.score, greaterThan(flatMeat.score));
  });

  test('chef rules penalize heavy stew without bright finishing contrast', () {
    final heavyStew = assessChefRules(
      profile: DishProfile.stew,
      recipeCanonicals: const {'говядина', 'картофель', 'сметана'},
      matchedCanonicals: const {'говядина', 'картофель', 'сметана'},
      supportCanonicals: const {'соль', 'перец'},
      displayByCanonical: const {
        'говядина': 'Говядина',
        'картофель': 'Картофель',
        'сметана': 'Сметана',
        'соль': 'Соль',
        'перец': 'Перец',
      },
      steps: const [
        'Обжарь говядину.',
        'Добавь картофель и сметану.',
        'Туши до мягкости и подай.',
      ],
    );

    final balancedStew = assessChefRules(
      profile: DishProfile.stew,
      recipeCanonicals: const {
        'говядина',
        'лук',
        'грибы',
        'сметана',
        'паприка',
        'лимон',
        'укроп',
      },
      matchedCanonicals: const {
        'говядина',
        'лук',
        'грибы',
        'сметана',
        'паприка',
        'лимон',
        'укроп',
      },
      supportCanonicals: const {'соль', 'перец', 'чеснок'},
      displayByCanonical: const {
        'говядина': 'Говядина',
        'лук': 'Лук',
        'грибы': 'Грибы',
        'сметана': 'Сметана',
        'паприка': 'Паприка',
        'лимон': 'Лимон',
        'укроп': 'Укроп',
        'соль': 'Соль',
        'перец': 'Перец',
        'чеснок': 'Чеснок',
      },
      steps: const [
        'Обжарь говядину с луком и грибами.',
        'Добавь паприку и сметану, затем мягко туши до готовности.',
        'В конце добавь лимон и укроп, затем подай.',
      ],
    );

    expect(balancedStew.flavorScore, greaterThan(heavyStew.flavorScore));
    expect(balancedStew.score, greaterThan(heavyStew.score));
    expect(
      heavyStew.warnings.any(
        (warning) =>
            warning.contains('яркого финиша') ||
            warning.contains('тяжёлой'),
      ),
      isTrue,
    );
  });

  test('chef rules penalize fish overloaded by spice without bright support', () {
    final overloadedFish = assessChefRules(
      profile: DishProfile.skillet,
      recipeCanonicals: const {'рыба', 'паприка', 'перец'},
      matchedCanonicals: const {'рыба', 'паприка', 'перец'},
      supportCanonicals: const {'соль'},
      displayByCanonical: const {
        'рыба': 'Рыба',
        'паприка': 'Паприка',
        'перец': 'Перец',
        'соль': 'Соль',
      },
      steps: const [
        'Приправь рыбу специями.',
        'Обжарь на сковороде и подай.',
      ],
    );

    final cleanFish = assessChefRules(
      profile: DishProfile.skillet,
      recipeCanonicals: const {'рыба', 'лимон', 'укроп'},
      matchedCanonicals: const {'рыба', 'лимон', 'укроп'},
      supportCanonicals: const {'соль', 'перец'},
      displayByCanonical: const {
        'рыба': 'Рыба',
        'лимон': 'Лимон',
        'укроп': 'Укроп',
        'соль': 'Соль',
        'перец': 'Перец',
      },
      steps: const [
        'Сбрызни рыбу лимоном.',
        'Обжарь до готовности.',
        'Посыпь укропом и подай.',
      ],
    );

    expect(cleanFish.flavorScore, greaterThan(overloadedFish.flavorScore));
    expect(cleanFish.score, greaterThan(overloadedFish.score));
    expect(
      overloadedFish.warnings
          .any((warning) => warning.contains('рыб')),
      isTrue,
    );
  });

  test('chef rules reward sweet breakfast with creamy fresh contrast', () {
    final flatBreakfast = assessChefRules(
      profile: DishProfile.breakfast,
      recipeCanonicals: const {'овсяные хлопья', 'сахар'},
      matchedCanonicals: const {'овсяные хлопья', 'сахар'},
      supportCanonicals: const {'соль'},
      displayByCanonical: const {
        'овсяные хлопья': 'Овсяные хлопья',
        'сахар': 'Сахар',
        'соль': 'Соль',
      },
      steps: const [
        'Смешай хлопья с сахаром.',
        'Прогрей и подай.',
      ],
    );

    final balancedBreakfast = assessChefRules(
      profile: DishProfile.breakfast,
      recipeCanonicals: const {'овсяные хлопья', 'банан', 'йогурт'},
      matchedCanonicals: const {'овсяные хлопья', 'банан', 'йогурт'},
      supportCanonicals: const {'корица'},
      displayByCanonical: const {
        'овсяные хлопья': 'Овсяные хлопья',
        'банан': 'Банан',
        'йогурт': 'Йогурт',
        'корица': 'Корица',
      },
      steps: const [
        'Свари овсяные хлопья.',
        'Добавь банан и йогурт.',
        'Посыпь корицей и подай.',
      ],
    );

    expect(
      balancedBreakfast.flavorScore,
      greaterThan(flatBreakfast.flavorScore),
    );
    expect(balancedBreakfast.score, greaterThan(flatBreakfast.score));
    expect(
      flatBreakfast.warnings.any(
        (warning) =>
            warning.contains('приторным') ||
            warning.contains('свежего контраста'),
      ),
      isTrue,
    );
  });

  test('chef rules reward sauce that is actually reduced and bound', () {
    final looseSauce = assessChefRules(
      profile: DishProfile.stew,
      recipeCanonicals: const {'курица', 'грибы', 'сметана'},
      matchedCanonicals: const {'курица', 'грибы', 'сметана'},
      supportCanonicals: const {'соль', 'перец'},
      displayByCanonical: const {
        'курица': 'Курица',
        'грибы': 'Грибы',
        'сметана': 'Сметана',
        'соль': 'Соль',
        'перец': 'Перец',
      },
      steps: const [
        'Обжарь курицу.',
        'Добавь грибы и сметану.',
        'Подавай.',
      ],
    );

    final boundSauce = assessChefRules(
      profile: DishProfile.stew,
      recipeCanonicals: const {'курица', 'грибы', 'сметана'},
      matchedCanonicals: const {'курица', 'грибы', 'сметана'},
      supportCanonicals: const {'соль', 'перец'},
      displayByCanonical: const {
        'курица': 'Курица',
        'грибы': 'Грибы',
        'сметана': 'Сметана',
        'соль': 'Соль',
        'перец': 'Перец',
      },
      steps: const [
        'Обжарь курицу и грибы.',
        'Добавь сметану и мягко уварь до соуса.',
        'Вмешай соус в блюдо и подавай.',
      ],
    );

    expect(boundSauce.techniqueScore, greaterThan(looseSauce.techniqueScore));
    expect(boundSauce.score, greaterThan(looseSauce.score));
    expect(
      looseSauce.warnings.any((warning) => warning.contains('соусная часть')),
      isTrue,
    );
  });

  test('chef rules reward baked meat protected by cover and rest', () {
    final dryBake = assessChefRules(
      profile: DishProfile.bake,
      recipeCanonicals: const {'свинина', 'картофель', 'паприка'},
      matchedCanonicals: const {'свинина', 'картофель', 'паприка'},
      supportCanonicals: const {'соль', 'перец'},
      displayByCanonical: const {
        'свинина': 'Свинина',
        'картофель': 'Картофель',
        'паприка': 'Паприка',
        'соль': 'Соль',
        'перец': 'Перец',
      },
      steps: const [
        'Выложи мясо и картофель в форму.',
        'Запекай до готовности и сразу подавай.',
      ],
    );

    final protectedBake = assessChefRules(
      profile: DishProfile.bake,
      recipeCanonicals: const {'свинина', 'картофель', 'паприка', 'сметана'},
      matchedCanonicals: const {'свинина', 'картофель', 'паприка', 'сметана'},
      supportCanonicals: const {'соль', 'перец'},
      displayByCanonical: const {
        'свинина': 'Свинина',
        'картофель': 'Картофель',
        'паприка': 'Паприка',
        'сметана': 'Сметана',
        'соль': 'Соль',
        'перец': 'Перец',
      },
      steps: const [
        'Замаринуй мясо со сметаной и паприкой.',
        'Накрой форму и запекай до готовности.',
        'Дай мясу отдохнуть пару минут и подавай.',
      ],
    );

    expect(protectedBake.techniqueScore, greaterThan(dryBake.techniqueScore));
    expect(protectedBake.score, greaterThan(dryBake.score));
    expect(
      dryBake.warnings.any((warning) => warning.contains('духовке') || warning.contains('отдых')),
      isTrue,
    );
  });

  test('chef rules reward gentle fish soup over aggressive boil', () {
    final harshSoup = assessChefRules(
      profile: DishProfile.soup,
      recipeCanonicals: const {'рыба', 'картофель', 'укроп'},
      matchedCanonicals: const {'рыба', 'картофель', 'укроп'},
      supportCanonicals: const {'соль'},
      displayByCanonical: const {
        'рыба': 'Рыба',
        'картофель': 'Картофель',
        'укроп': 'Укроп',
        'соль': 'Соль',
      },
      steps: const [
        'Залей водой рыбу и картофель.',
        'Кипяти до готовности.',
        'Подавай.',
      ],
    );

    final gentleSoup = assessChefRules(
      profile: DishProfile.soup,
      recipeCanonicals: const {'рыба', 'картофель', 'лук', 'укроп', 'лимон'},
      matchedCanonicals: const {'рыба', 'картофель', 'лук', 'укроп', 'лимон'},
      supportCanonicals: const {'соль', 'перец'},
      displayByCanonical: const {
        'рыба': 'Рыба',
        'картофель': 'Картофель',
        'лук': 'Лук',
        'укроп': 'Укроп',
        'лимон': 'Лимон',
        'соль': 'Соль',
        'перец': 'Перец',
      },
      steps: const [
        'Прогрей лук и добавь воду.',
        'Вари суп на слабом огне до готовности.',
        'В конце добавь лимон и укроп, затем подавай.',
      ],
    );

    expect(gentleSoup.techniqueScore, greaterThan(harshSoup.techniqueScore));
    expect(gentleSoup.score, greaterThan(harshSoup.score));
    expect(
      harshSoup.warnings.any((warning) => warning.contains('рыбный суп')),
      isTrue,
    );
  });
}
