import 'ingredient_knowledge.dart';
import 'offline_chef_blueprints.dart';
import 'recipe.dart';

class ChefDishValidationResult {
  final ChefDishFamily family;
  final List<String> violations;

  const ChefDishValidationResult({
    required this.family,
    this.violations = const [],
  });

  bool get isValid => violations.isEmpty;
}

ChefDishValidationResult validateChefDish({
  required ChefBlueprint blueprint,
  required Recipe recipe,
  required Set<String> recipeCanonicals,
}) {
  final canonicals = recipeCanonicals
      .map(normalizeIngredientText)
      .where((value) => value.isNotEmpty)
      .toSet();
  final normalizedTitle = normalizeIngredientText(recipe.title);
  final normalizedSteps = recipe.steps
      .map(normalizeIngredientText)
      .where((value) => value.isNotEmpty)
      .toList(growable: false);
  final violations = <String>[];
  final family = blueprint.dishFamily;

  void requireCanonical(String canonical, String message) {
    if (!_containsCanonical(canonicals, canonical)) {
      violations.add(message);
    }
  }

  void requireAnyCanonical(Iterable<String> options, String message) {
    if (!options
        .any((canonical) => _containsCanonical(canonicals, canonical))) {
      violations.add(message);
    }
  }

  void forbidCanonical(String canonical, String message) {
    if (_containsCanonical(canonicals, canonical)) {
      violations.add(message);
    }
  }

  void requireAnyStep(Iterable<String> fragments, String message) {
    if (!_stepsContainAny(normalizedSteps, fragments)) {
      violations.add(message);
    }
  }

  void requireStepWithAll(List<String> fragments, String message) {
    if (!_stepsContainAll(normalizedSteps, fragments)) {
      violations.add(message);
    }
  }

  void forbidAnyStep(Iterable<String> fragments, String message) {
    if (_stepsContainAny(normalizedSteps, fragments)) {
      violations.add(message);
    }
  }

  void forbidStepWithAll(List<String> fragments, String message) {
    if (_stepsContainAll(normalizedSteps, fragments)) {
      violations.add(message);
    }
  }

  switch (family) {
    case ChefDishFamily.eggSkillet:
      requireCanonical('яйцо', 'Для яичной сковороды обязательны яйца.');
      _validateEggSkilletTechnique(
        violations: violations,
        steps: normalizedSteps,
      );
      forbidAnyStep(
        ['духовк', 'запекай'],
        'Яичная сковорода не должна уходить в запекание.',
      );
      break;
    case ChefDishFamily.potatoSkillet:
      requireCanonical(
        'картофель',
        'Картофельная сковорода требует картофельной основы.',
      );
      _validatePotatoSkilletTechnique(
        violations: violations,
        steps: normalizedSteps,
      );
      forbidAnyStep(
        ['духовк', 'запекай'],
        'Картофельная сковорода не должна превращаться в запеканку.',
      );
      break;
    case ChefDishFamily.freshSalad:
      _validateFreshSaladTechnique(
        violations: violations,
        steps: normalizedSteps,
      );
      break;
    case ChefDishFamily.olivierSalad:
      _validateFreshSaladTechnique(
        violations: violations,
        steps: normalizedSteps,
      );
      requireCanonical(
        'картофель',
        'Оливье без картофеля теряет обязательную основу.',
      );
      requireCanonical(
          'яйцо', 'Оливье требует яйца как часть классической базы.');
      requireCanonical(
        'огурец',
        'Оливье требует огуречный акцент для узнаваемого вкуса.',
      );
      requireAnyCanonical(
        ['горошек', 'колбаса'],
        'Оливье требует хотя бы один праздничный акцент: горошек или колбасу.',
      );
      requireAnyCanonical(
        ['майонез'],
        'Оливье должно собираться через майонезную заправку.',
      );
      forbidCanonical(
        'свекла',
        'Оливье не должно уходить в свекольную основу винегрета.',
      );
      break;
    case ChefDishFamily.vinegretSalad:
      _validateFreshSaladTechnique(
        violations: violations,
        steps: normalizedSteps,
      );
      requireCanonical(
        'свекла',
        'Винегрет без свёклы теряет свою обязательную основу.',
      );
      requireCanonical(
        'картофель',
        'Винегрету нужен картофель для собранной корнеплодной базы.',
      );
      requireAnyCanonical(
        ['огурец', 'капуста'],
        'Винегрету нужен солёный или квашеный акцент.',
      );
      requireAnyCanonical(
        ['масло', 'оливковое масло'],
        'Винегрет должен собираться на спокойной масляной заправке.',
      );
      forbidCanonical(
        'майонез',
        'Винегрет не должен уходить в майонезную заправку.',
      );
      break;
    case ChefDishFamily.coldSoup:
      _validateColdSoupTechnique(
        violations: violations,
        steps: normalizedSteps,
      );
      break;
    case ChefDishFamily.okroshkaColdSoup:
      _validateColdSoupTechnique(
        violations: violations,
        steps: normalizedSteps,
      );
      requireCanonical('кефир', 'Окрошка требует кефирную основу.');
      requireCanonical(
        'картофель',
        'Окрошка требует картофельную опору в холодной основе.',
      );
      requireCanonical(
          'яйцо', 'Окрошке нужно яйцо для классической структуры.');
      requireCanonical(
        'огурец',
        'Окрошка требует свежий огуречный акцент.',
      );
      requireAnyCanonical(
        ['укроп', 'зелень'],
        'Окрошке нужна свежая зелень для правильного холодного профиля.',
      );
      requireStepWithAll(
        ['влей', 'кефир'],
        'Окрошка должна собираться через вливание кефира в холодную базу.',
      );
      forbidAnyStep(
        ['кипяти', 'доведи до кипения'],
        'Окрошка не должна кипятиться после сборки.',
      );
      break;
    case ChefDishFamily.okroshkaKvassColdSoup:
      _validateColdSoupTechnique(
        violations: violations,
        steps: normalizedSteps,
      );
      requireCanonical('квас', 'Окрошка на квасе требует квасную основу.');
      requireCanonical(
        'картофель',
        'Окрошка на квасе требует картофельную опору в холодной основе.',
      );
      requireCanonical(
        'яйцо',
        'Окрошке на квасе нужно яйцо для классической структуры.',
      );
      requireCanonical(
        'огурец',
        'Окрошка на квасе требует свежий огуречный акцент.',
      );
      requireAnyCanonical(
        ['укроп', 'зелень'],
        'Окрошке на квасе нужна свежая зелень для правильного холодного профиля.',
      );
      requireStepWithAll(
        ['влей', 'квас'],
        'Окрошка на квасе должна собираться через вливание кваса в холодную базу.',
      );
      forbidAnyStep(
        ['кипяти', 'доведи до кипения'],
        'Окрошка на квасе не должна кипятиться после сборки.',
      );
      break;
    case ChefDishFamily.grainPan:
      requireAnyCanonical(
        ['рис', 'гречка', 'кускус', 'перловка'],
        'Зерновая миска требует крупяную основу.',
      );
      _validateGrainPanTechnique(
        violations: violations,
        steps: normalizedSteps,
      );
      break;
    case ChefDishFamily.pastaPan:
      requireCanonical('макароны', 'Паста требует макаронную основу.');
      _validatePastaPanTechnique(
        violations: violations,
        steps: normalizedSteps,
      );
      break;
    case ChefDishFamily.navyPasta:
      requireCanonical(
        'макароны',
        'Макароны по-флотски требуют макаронную основу.',
      );
      requireCanonical('фарш', 'Макароны по-флотски требуют мясной фарш.');
      requireCanonical(
        'лук',
        'Макароны по-флотски без лука теряют обязательную ароматическую базу.',
      );
      requireStepWithAll(
        ['отвари', '8-10 минут'],
        'Макароны по-флотски должны начинаться с отваривания пасты.',
      );
      requireAnyStep(
        ['сковород', 'прогрей'],
        'Макароны по-флотски должны собираться через короткую мясную поджарку.',
      );
      forbidCanonical(
        'сахар',
        'Макароны по-флотски не должны уходить в сладкий профиль.',
      );
      break;
    case ChefDishFamily.soup:
      _validateHotSoupTechnique(
        violations: violations,
        steps: normalizedSteps,
      );
      break;
    case ChefDishFamily.cabbageSoup:
      _validateHotSoupTechnique(
        violations: violations,
        steps: normalizedSteps,
      );
      requireCanonical('капуста', 'Щи требуют капустную основу.');
      requireAnyCanonical(
        ['картофель', 'морковь', 'лук'],
        'Щам нужна спокойная овощная база из корнеплодов.',
      );
      requireAnyCanonical(
        ['сметана', 'укроп', 'лавровый лист'],
        'Щам нужен спокойный домашний финиш через сметану, укроп или лавровый лист.',
      );
      forbidCanonical(
        'свекла',
        'Щи не должны уходить в свекольную основу борща.',
      );
      break;
    case ChefDishFamily.borschtSoup:
      _validateHotSoupTechnique(
        violations: violations,
        steps: normalizedSteps,
      );
      requireCanonical('свекла', 'Борщ требует свекольную основу.');
      requireCanonical('капуста', 'Борщу нужна капустная опора.');
      requireAnyCanonical(
        ['картофель', 'морковь', 'лук'],
        'Борщу нужна корнеплодная овощная база.',
      );
      requireAnyCanonical(
        ['томатная паста', 'сметана'],
        'Борщу нужна томатная глубина или мягкий кислый акцент.',
      );
      requireAnyStep(
        ['томатн', 'сметан'],
        'Борщ должен явно собираться через томатную глубину или мягкий сметанный финиш.',
      );
      forbidCanonical(
        'оливки',
        'Борщ не должен уходить в соляночный профиль с оливками.',
      );
      break;
    case ChefDishFamily.fishSoup:
      _validateHotSoupTechnique(
        violations: violations,
        steps: normalizedSteps,
      );
      requireCanonical('рыба', 'Уха требует рыбную основу.');
      requireAnyCanonical(
        ['картофель', 'морковь', 'лук'],
        'Ухе нужна овощная база из корнеплодов.',
      );
      requireStepWithAll(
        ['затем добавь', 'рыбу'],
        'Уха должна добавлять рыбу после овощной базы, а не варить всё вместе с начала.',
      );
      requireAnyCanonical(
        ['укроп', 'лимон'],
        'Ухе нужен чистый финиш через укроп или лимон.',
      );
      break;
    case ChefDishFamily.pickleSoup:
      _validateHotSoupTechnique(
        violations: violations,
        steps: normalizedSteps,
      );
      requireCanonical(
        'перловка',
        'Рассольник требует перловую основу.',
      );
      requireCanonical(
        'огурец',
        'Рассольник требует солёный огурец.',
      );
      requireAnyCanonical(
        ['картофель', 'морковь', 'лук'],
        'Рассольнику нужна спокойная овощная база.',
      );
      requireAnyStep(
        ['последние 5-6 минут', 'последние 5 минут'],
        'Рассольник должен добавлять солёный акцент ближе к концу варки.',
      );
      break;
    case ChefDishFamily.solyankaSoup:
      _validateHotSoupTechnique(
        violations: violations,
        steps: normalizedSteps,
      );
      requireAnyCanonical(
        ['колбаса', 'сосиски', 'говядина'],
        'Солянке нужна мясная или колбасная основа.',
      );
      requireCanonical('огурец', 'Солянка требует солёный огурец.');
      requireCanonical(
        'томатная паста',
        'Солянке нужна томатная глубина для собранного кислого бульона.',
      );
      requireAnyCanonical(
        ['оливки', 'лимон'],
        'Солянке нужен яркий соляно-кислый финиш через оливки или лимон.',
      );
      final hasLateFinishCue = _stepsContainAny(
        normalizedSteps,
        ['в конце', 'перед подачей', 'затем дай ей настояться'],
      );
      final hasBrightFinish = _stepsContainAny(
        normalizedSteps,
        ['олив', 'маслин', 'лимон'],
      );
      if (!hasLateFinishCue || !hasBrightFinish) {
        violations.add(
          'Солянка должна доводиться ярким финишем через оливки или лимон.',
        );
      }
      forbidCanonical(
        'свекла',
        'Солянка не должна уходить в свекольный профиль борща.',
      );
      break;
    case ChefDishFamily.bake:
      _validateBakeTechnique(
        violations: violations,
        steps: normalizedSteps,
      );
      break;
    case ChefDishFamily.curdBake:
      requireCanonical(
        'творог',
        'Творожная запеканка требует творожную основу.',
      );
      requireCanonical(
        'яйцо',
        'Творожной запеканке нужно яйцо для связки.',
      );
      requireCanonical(
        'манная крупа',
        'Творожной запеканке нужна манка для правильной структуры.',
      );
      requireAnyStep(
        ['запекай', 'духовк'],
        'Творожная запеканка должна готовиться в духовке.',
      );
      forbidAnyStep(
        ['обжарь их', 'сковород'],
        'Творожная запеканка не должна превращаться в жареное блюдо.',
      );
      break;
    case ChefDishFamily.savoryClosedPie:
      _validateSavoryClosedPieTechnique(
        violations: violations,
        steps: normalizedSteps,
      );
      requireCanonical('мука', 'Закрытому пирогу нужна мучная оболочка.');
      requireCanonical(
        'капуста',
        'Пирогу с капустой и яйцом нужна капустная начинка.',
      );
      requireCanonical(
        'яйцо',
        'Пирогу с капустой и яйцом нужны яйца для начинки и смазки.',
      );
      requireAnyCanonical(
        [
          'масло сливочное',
          'масло',
          'оливковое масло',
          'сметана',
          'кефир',
          'молоко'
        ],
        'Закрытому пирогу нужна мягкая жировая или молочная опора для теста.',
      );
      forbidAnyStep(
        ['вылей в форму', 'смешай всё и запекай', 'ровным слоем'],
        'Пирог не должен собираться как наливная запеканка без раскатки и закрытия.',
      );
      break;
    case ChefDishFamily.shawarmaWrap:
      requireCanonical('курица', 'Шаурме нужна куриная мясная часть.');
      requireCanonical('лаваш', 'Шаурме нужен лаваш для правильной сборки.');
      requireAnyCanonical(
        ['сметана', 'йогурт'],
        'Шаурме нужен отдельный холодный соус на сметане или йогурте.',
      );
      final freshCount = ['капуста', 'огурец', 'помидор', 'лук']
          .where((canonical) => _containsCanonical(canonicals, canonical))
          .length;
      if (freshCount < 2) {
        violations.add(
          'Шаурме нужна свежая часть минимум из двух компонентов, чтобы вкус не был плоским и сухим.',
        );
      }
      _validateShawarmaWrapTechnique(
        violations: violations,
        steps: normalizedSteps,
        requiresGarlicInSauce: _containsCanonical(canonicals, 'чеснок'),
      );
      forbidAnyStep(
        ['духовк', 'запекай'],
        'Шаурма не должна уходить в духовочную технику вместо горячей сковороды.',
      );
      break;
    case ChefDishFamily.breakfast:
      _validateBreakfastTechnique(
        violations: violations,
        steps: normalizedSteps,
      );
      break;
    case ChefDishFamily.panBatter:
      _validatePanBatterTechnique(
        violations: violations,
        steps: normalizedSteps,
      );
      break;
    case ChefDishFamily.bliniPan:
      _validatePanBatterTechnique(
        violations: violations,
        steps: normalizedSteps,
      );
      requireCanonical('мука', 'Блины требуют мучную основу.');
      requireCanonical('яйцо', 'Блинам нужно яйцо для блинного теста.');
      requireCanonical('молоко', 'Блинам нужна молочная жидкая база.');
      requireAnyStep(
        ['1-2 минуты с каждой стороны'],
        'Блины должны быстро пропекаться с двух сторон на сковороде.',
      );
      forbidAnyStep(
        ['духовк', 'запекай'],
        'Блины не должны превращаться в духовочную выпечку.',
      );
      break;
    case ChefDishFamily.fritterBatter:
      _validateSharedSkilletFritterTechnique(
        violations: violations,
        steps: normalizedSteps,
      );
      _validateFritterBatterTechnique(
        violations: violations,
        steps: normalizedSteps,
      );
      break;
    case ChefDishFamily.oladyiFritter:
      _validateSharedSkilletFritterTechnique(
        violations: violations,
        steps: normalizedSteps,
      );
      _validateFritterBatterTechnique(
        violations: violations,
        steps: normalizedSteps,
      );
      requireCanonical('мука', 'Оладьи требуют мучную основу.');
      requireCanonical('яйцо', 'Оладьям нужно яйцо для связки.');
      requireCanonical('кефир', 'Оладьи на кефире требуют кефирную базу.');
      requireAnyStep(
        ['2-3 минуты с каждой стороны'],
        'Оладьи должны жариться коротко с двух сторон.',
      );
      forbidAnyStep(
        ['шайбы', 'творожную массу', 'картофельную массу', 'натри'],
        'Оладьи не должны превращаться в сырники или драники.',
      );
      forbidAnyStep(
        ['духовк', 'запекай'],
        'Оладьи не должны превращаться в духовочную выпечку.',
      );
      break;
    case ChefDishFamily.curdFritter:
      _validateSharedSkilletFritterTechnique(
        violations: violations,
        steps: normalizedSteps,
      );
      _validateCurdFritterTechnique(
        violations: violations,
        steps: normalizedSteps,
      );
      requireCanonical('творог', 'Сырники требуют творожную основу.');
      requireCanonical('яйцо', 'Сырники требуют яйцо для связки.');
      requireAnyStep(
        ['шайбы', 'обжарь их'],
        'Сырники должны формоваться и жариться порционно.',
      );
      requireAnyStep(
        ['2-3 минуты с каждой стороны'],
        'Сырники должны жариться коротко с двух сторон.',
      );
      forbidAnyStep(
        ['ложкой', 'густое тесто', 'вылей'],
        'Сырники не должны жариться как оладьи из жидкой массы.',
      );
      forbidAnyStep(
        ['духовк', 'запекай'],
        'Сырники не должны уходить в запекание.',
      );
      break;
    case ChefDishFamily.potatoFritter:
      _validateSharedSkilletFritterTechnique(
        violations: violations,
        steps: normalizedSteps,
      );
      _validatePotatoFritterTechnique(
        violations: violations,
        steps: normalizedSteps,
      );
      requireCanonical('картофель', 'Драники требуют картофельную основу.');
      requireCanonical('лук', 'Драники требуют луковый ароматический акцент.');
      requireAnyStep(
        ['натри', 'картофельную массу'],
        'Для драников нужна тёртая картофельная масса.',
      );
      requireAnyStep(
        ['3-4 минуты с каждой стороны'],
        'Драники должны жариться коротко с двух сторон.',
      );
      forbidAnyStep(
        ['постоять 5-7 минут', 'густое тесто', 'без комков'],
        'Драники не должны идти по логике блинного теста.',
      );
      forbidAnyStep(
        ['духовк', 'запекай'],
        'Драники не должны превращаться в запеканку.',
      );
      break;
    case ChefDishFamily.porridge:
      requireAnyCanonical(
        ['пшено', 'рис', 'манная крупа', 'овсяные хлопья'],
        'Каша требует крупяную или хлопьевую основу.',
      );
      requireAnyStep(
        ['вари кашу', 'тонкой струйкой', 'на спокойном огне'],
        'Каша требует спокойной варки с контролем текстуры.',
      );
      break;
    case ChefDishFamily.lazyCabbageRollStew:
      requireCanonical(
          'фарш', 'Ленивым голубцам нужна мясная основа из фарша.');
      requireCanonical(
          'рис', 'Ленивым голубцам нужен рис для правильной структуры.');
      requireCanonical(
        'капуста',
        'Ленивые голубцы требуют капустную основу.',
      );
      requireAnyCanonical(
        ['томатная паста', 'сметана'],
        'Ленивым голубцам нужна томатная глубина или мягкий сметанный финиш.',
      );
      requireAnyStep(
        ['соедини', 'собери плотную основу'],
        'Ленивые голубцы должны сначала собирать общую мясо-рисовую массу.',
      );
      requireAnyStep(
        ['туши ленивые голубцы', '18-22 минуты', 'под крышкой'],
        'Ленивые голубцы должны спокойно тушиться под крышкой.',
      );
      forbidAnyStep(
        ['духовк', 'запекай', 'влей воду и вари суп'],
        'Ленивые голубцы не должны уходить в запекание или суповую технику.',
      );
      break;
    case ChefDishFamily.tefteliSauceStew:
      requireCanonical('фарш', 'Тефтелям нужна мясная основа из фарша.');
      requireCanonical('рис', 'Тефтелям нужен рис для правильной структуры.');
      requireAnyCanonical(
        ['томатная паста', 'сметана'],
        'Тефтелям нужен соус через томатную пасту или сметану.',
      );
      requireAnyStep(
        ['сформируй небольшие тефтели', 'сформируй тефтели'],
        'Тефтели должны формоваться отдельно, а не тушиться россыпью.',
      );
      requireAnyStep(
        ['туши их под крышкой', '18-22 минуты', 'в соус'],
        'Тефтели должны спокойно доходить в соусе под крышкой.',
      );
      forbidAnyStep(
        ['духовк', 'запекай', 'влей воду и вари суп'],
        'Тефтели не должны уходить в запекание или суповую технику.',
      );
      break;
    case ChefDishFamily.homeCutletDinner:
      requireAnyCanonical(
        ['фарш', 'говядина', 'свинина', 'курица'],
        'Домашним котлетам нужна мясная основа.',
      );
      requireAnyCanonical(
        ['картофель', 'гречка', 'рис'],
        'Котлетному ужину нужен отдельный гарнир.',
      );
      requireAnyStep(
        ['сформируй котлеты', '4-5 минут с каждой стороны'],
        'Котлетный ужин требует формовки и обжаривания котлет.',
      );
      requireAnyStep(
        ['гарнир', 'вместе с гарниром'],
        'Котлетный ужин должен явно подаваться вместе с гарниром.',
      );
      requireAnyStep(
        ['6-8 минут', 'отдохнуть 1-2 минуты'],
        'Котлетам нужна мягкая доводка и короткий отдых перед подачей.',
      );
      forbidAnyStep(
        ['духовк', 'запекай', 'влей воду и вари'],
        'Котлетный ужин не должен превращаться в запеканку или варёное блюдо.',
      );
      break;
    case ChefDishFamily.zrazyStuffedCutlets:
      requireCanonical('фарш', 'Зразам нужна мясная основа из фарша.');
      requireAnyCanonical(
        ['картофель', 'гречка'],
        'Зразам нужен отдельный гарнир.',
      );
      requireAnyCanonical(
        ['яйцо', 'грибы'],
        'Зразам нужна отдельная начинка через яйцо или грибы.',
      );
      requireAnyStep(
        ['в центр', 'закрой края', 'начинка'],
        'Зразы должны закрывать начинку внутри мясной оболочки.',
      );
      requireAnyStep(
        ['сформируй зразы', 'обжарь зразы', '4-5 минут с каждой стороны'],
        'Зразы требуют отдельной формовки и обжаривания с двух сторон.',
      );
      requireAnyStep(
        ['гарнир', 'вместе с гарниром'],
        'Зразы должны подаваться с отдельным гарниром.',
      );
      forbidAnyStep(
        ['влей воду и вари суп', 'охлад', 'бурно кипяти'],
        'Зразы не должны уходить в суповую, холодную или грубую кипящую технику.',
      );
      break;
    case ChefDishFamily.bitochkiGravyCutlets:
      requireCanonical('фарш', 'Биточкам нужна мясная основа из фарша.');
      requireAnyCanonical(
        ['картофель', 'гречка'],
        'Биточкам нужен отдельный гарнир.',
      );
      requireAnyCanonical(
        ['лук', 'морковь', 'сметана'],
        'Биточкам нужна мягкая подливка на овощной или сметанной базе.',
      );
      requireAnyStep(
        ['круглые биточки', 'сформируй биточки'],
        'Биточки должны формоваться отдельно и сохранять свою круглую форму.',
      );
      requireAnyStep(
        ['3-4 минуты с каждой стороны', '3-4 минуты'],
        'Биточкам нужна короткая первичная обжарка, а не долгая сухая жарка.',
      );
      requireAnyStep(
        ['подлив', 'обволоч', '8-10 минут'],
        'Биточки должны дойти в мягкой подливке после короткой обжарки.',
      );
      requireAnyStep(
        ['гарнир', 'вместе с гарниром'],
        'Биточки должны подаваться вместе с гарниром.',
      );
      forbidAnyStep(
        ['в центр', 'закрой края', 'начинка'],
        'Биточки не должны уходить в технику зраз с начинкой.',
      );
      break;
    case ChefDishFamily.zharkoeStew:
      requireCanonical('картофель', 'Жаркому нужна картофельная основа.');
      requireAnyCanonical(
        ['говядина', 'свинина', 'курица'],
        'Жаркому нужна мясная основа.',
      );
      requireAnyCanonical(
        ['лук', 'морковь', 'грибы'],
        'Жаркому нужна домашняя овощная или грибная подложка.',
      );
      requireAnyStep(
        ['обжарь', '5-6 минут'],
        'Жаркому нужен отдельный этап обжарки мяса перед тушением.',
      );
      requireAnyStep(
        ['туши жаркое', '22-26 минут', 'под крышкой'],
        'Жаркое должно спокойно доходить под крышкой после обжарки.',
      );
      forbidAnyStep(
        ['влей воду и вари суп', 'охлад', 'запекай'],
        'Жаркое не должно уходить в суповую, холодную или духовочную технику.',
      );
      break;
    case ChefDishFamily.goulashSauceStew:
      requireAnyCanonical(
        ['говядина', 'свинина'],
        'Гуляшу нужна мясная основа из говядины или свинины.',
      );
      requireCanonical('лук', 'Гуляшу нужен лук для соусной базы.');
      requireAnyCanonical(
        ['паприка', 'томатная паста'],
        'Гуляшу нужна паприка или томатная глубина.',
      );
      requireAnyStep(
        ['обжарь мясо', '5-6 минут'],
        'Гуляшу нужен отдельный этап обжарки мяса перед тушением.',
      );
      requireAnyStep(
        ['туши гуляш', '25-30 минут', 'под крышкой'],
        'Гуляш должен спокойно доходить под крышкой в густом соусе.',
      );
      forbidAnyStep(
        [
          'тонкими полосками',
          'быстро обжарь мясо 3-4 минуты',
          'держи бефстроганов',
        ],
        'Гуляш не должен уходить в технику бефстроганова.',
      );
      break;
    case ChefDishFamily.stroganoffSauceStew:
      requireCanonical('говядина', 'Бефстроганов требует говяжью основу.');
      requireCanonical(
          'лук', 'Бефстроганову нужен лук для мягкой соусной базы.');
      requireCanonical(
        'сметана',
        'Бефстроганову нужен сметанный соус.',
      );
      requireAnyStep(
        ['тонкими полосками', 'полосками'],
        'Бефстроганов требует тонко нарезанное мясо.',
      );
      requireAnyStep(
        ['3-4 минуты', 'быстро обжарь'],
        'Бефстроганов должен быстро обжаривать мясо, а не долго тушить его с начала.',
      );
      requireAnyStep(
        ['5-7 минут', 'не давая соусу бурно кипеть', 'мягком огне'],
        'Бефстроганов должен аккуратно дойти в сметанном соусе без сильного кипения.',
      );
      forbidCanonical(
        'томатная паста',
        'Бефстроганов не должен уходить в томатный профиль гуляша.',
      );
      break;
    case ChefDishFamily.cutlets:
      requireAnyCanonical(
        ['фарш', 'говядина', 'свинина', 'курица'],
        'Котлеты требуют мясную основу.',
      );
      _validateCutletTechnique(
        violations: violations,
        steps: normalizedSteps,
      );
      break;
    case ChefDishFamily.stew:
      _validateStewTechnique(
        violations: violations,
        steps: normalizedSteps,
      );
      break;
    case ChefDishFamily.perfectOmeletteSkillet:
      requireCanonical('яйцо', 'Классическому омлету нужна яичная основа.');
      _validatePerfectOmeletteTechnique(
        violations: violations,
        steps: normalizedSteps,
      );
      break;
    case ChefDishFamily.butterEggSkillet:
      requireCanonical(
        'яйцо',
        'Яйцам в сливочном масле нужна яичная основа.',
      );
      _validateButterEggTechnique(
        violations: violations,
        steps: normalizedSteps,
      );
      break;
    case ChefDishFamily.potatoPureeSide:
      requireCanonical(
          'картофель', 'Картофельному пюре нужна картофельная основа.');
      _validatePotatoPureeTechnique(
        violations: violations,
        steps: normalizedSteps,
      );
      break;
    case ChefDishFamily.caramelizedOnionToast:
      requireCanonical(
        'лук',
        'Тосту с карамелизированным луком нужна луковая основа.',
      );
      requireAnyCanonical(
        ['хлеб', 'лаваш'],
        'Тосту с карамелизированным луком нужна хлебная подача.',
      );
      _validateCaramelizedOnionToastTechnique(
        violations: violations,
        steps: normalizedSteps,
      );
      break;
    case ChefDishFamily.shakshukaSkillet:
      requireCanonical('яйцо', 'Шакшуке нужны яйца.');
      requireAnyCanonical(
        ['помидор', 'томатная паста'],
        'Шакшуке нужна томатная основа.',
      );
      _validateShakshukaTechnique(
        violations: violations,
        steps: normalizedSteps,
      );
      break;
    case ChefDishFamily.breadEggSkillet:
      requireAnyCanonical(
        ['хлеб', 'лаваш'],
        'Яйцу в хлебе нужна хлебная основа.',
      );
      requireCanonical('яйцо', 'Яйцу в хлебе нужно яйцо.');
      _validateBreadEggTechnique(
        violations: violations,
        steps: normalizedSteps,
      );
      break;
    case ChefDishFamily.aglioEOlioPasta:
      requireCanonical(
        'макароны',
        'Aglio e olio требует макаронную основу.',
      );
      requireCanonical(
        'чеснок',
        'Aglio e olio требует чесночную основу.',
      );
      _validateAglioEOlioTechnique(
        violations: violations,
        steps: normalizedSteps,
      );
      break;
    case ChefDishFamily.cucumberSmetanaSalad:
      requireCanonical('огурец', 'Огурцам со сметаной нужна огуречная основа.');
      requireAnyCanonical(
        ['сметана', 'йогурт', 'творог'],
        'Огурцам со сметаной нужна мягкая молочная заправка.',
      );
      _validateCucumberSmetanaTechnique(
        violations: violations,
        steps: normalizedSteps,
      );
      break;
    case ChefDishFamily.potatoEggHash:
      requireCanonical(
        'картофель',
        'Картофельному хэшу нужна картофельная основа.',
      );
      requireCanonical('яйцо', 'Картофельному хэшу нужно яйцо.');
      _validatePotatoEggHashTechnique(
        violations: violations,
        steps: normalizedSteps,
      );
      break;
    case ChefDishFamily.simpleRiceKasha:
      requireCanonical('рис', 'Простой рисовой каше нужна рисовая основа.');
      _validateSimpleRiceKashaTechnique(
        violations: violations,
        steps: normalizedSteps,
      );
      break;
  }

  switch (blueprint.sauceStyle) {
    case ChefSauceStyle.tomatoSourCreamGravy:
      requireAnyStep(
        ['обволакива', 'обволочь тефтели', 'соус успеет собраться'],
        'Тефтелям нужен собранный соус, который мягко обволакивает их, а не остаётся водянистым.',
      );
      break;
    case ChefSauceStyle.mildOnionGravy:
      requireAnyStep(
        ['подлив', 'обволоч', 'мягком огне'],
        'Биточкам нужна мягкая подливка, которая спокойно собирается вокруг мясной части.',
      );
      break;
    case ChefSauceStyle.paprikaTomatoGravy:
      requireStepWithAll(
        ['соус', 'гуще'],
        'Гуляшу нужно уварить соус до более густого состояния.',
      );
      requireAnyStep(
        ['глубже', 'выпар'],
        'Гуляшу нужно собрать соус до глубины без лишней воды.',
      );
      forbidAnyStep(
        ['белом соусе', 'белый соус'],
        'Гуляш не должен уходить в белый сметанный соус.',
      );
      break;
    case ChefSauceStyle.sourCreamPanSauce:
      requireAnyStep(
        ['гладк', 'собраться 1-2 минуты'],
        'Бефстроганову нужен гладкий сметанный соус, который спокойно собирается на сковороде.',
      );
      forbidStepWithAll(
        ['под крышкой', '25-30 минут'],
        'Бефстроганов не должен уходить в долгую тушёную технику гуляша.',
      );
      forbidAnyStep(
        ['бурно кипяти'],
        'Бефстроганов не должен бурно кипятить сметанный соус.',
      );
      break;
    case null:
      break;
  }

  if (family == ChefDishFamily.freshSalad ||
      family == ChefDishFamily.olivierSalad ||
      family == ChefDishFamily.vinegretSalad) {
    forbidAnyStep(
      ['запекай', 'духовк'],
      'Холодный салат не должен уходить в духовочную технику.',
    );
  }

  if ((family == ChefDishFamily.soup ||
          family == ChefDishFamily.cabbageSoup ||
          family == ChefDishFamily.borschtSoup ||
          family == ChefDishFamily.coldSoup ||
          family == ChefDishFamily.okroshkaColdSoup ||
          family == ChefDishFamily.okroshkaKvassColdSoup ||
          family == ChefDishFamily.fishSoup ||
          family == ChefDishFamily.pickleSoup ||
          family == ChefDishFamily.solyankaSoup) &&
      normalizedTitle.contains('салат')) {
    violations.add('Суп не должен терять свою подачу и превращаться в салат.');
  }

  return ChefDishValidationResult(
    family: family,
    violations: violations,
  );
}

void _validateFreshSaladTechnique({
  required List<String> violations,
  required List<String> steps,
}) {
  if (!_stepsContainAny(steps, ['нареж', 'подготовь и нарежь'])) {
    violations.add('Салат требует явной нарезки ингредиентов.');
  }
  if (!_stepsContainAny(steps, ['миску', 'перемешивай', 'перемешай'])) {
    violations.add('Салат должен собираться через аккуратное смешивание.');
  }
  if (!_stepsContainAny(steps, ['подавай сразу', 'перед подачей заправь'])) {
    violations.add('Салат должен собираться непосредственно перед подачей.');
  }
}

void _validateEggSkilletTechnique({
  required List<String> violations,
  required List<String> steps,
}) {
  if (!_stepsContainAny(steps, ['сковород', 'обжар'])) {
    violations.add('Яичная сковорода должна готовиться на сковороде.');
  }
  if (!_stepsContainAny(steps, ['слегка взбей', 'взбей'])) {
    violations.add(
      'Яичной сковороде нужна мягко собранная яичная масса, а не случайная подача сырого яйца.',
    );
  }
  if (!_stepsContainAny(
      steps, ['среднем огне', 'умеренном огне', 'добавкам схватиться'])) {
    violations.add(
      'Яичная сковорода требует умеренного огня и короткой подготовки добавок.',
    );
  }
  if (!_stepsContainAny(
      steps, ['ведя лопаткой от краев к центру', 'веди лопаткой'])) {
    violations.add(
      'Яичную сковороду нужно собирать лопаткой, чтобы текстура оставалась нежной.',
    );
  }
  if (!_stepsContainAny(
    steps,
    [
      'сними с огня',
      'подавай сразу',
      'затем дай блюду 1 минуту стабилизироваться и подавай'
    ],
  )) {
    violations.add(
      'Яичную сковороду нужно снимать вовремя и подавать сразу, пока она не пересохла.',
    );
  }
  if (_stepsContainAny(
      steps, ['сильном огне', 'румяной корочки', 'до корочки'])) {
    violations.add(
      'Яичная сковорода не должна зажариваться на сильном огне до грубой корочки.',
    );
  }
}

void _validatePotatoSkilletTechnique({
  required List<String> violations,
  required List<String> steps,
}) {
  if (!_stepsContainAny(steps, ['сковород', 'обжар'])) {
    violations.add('Картофельная сковорода должна идти через обжаривание.');
  }
  if (!_stepsContainAny(steps, ['одним слоем', 'золотистая корочка'])) {
    violations.add(
      'Картофельной сковороде нужен один слой и работа на корочку, а не хаотичное тушение.',
    );
  }
  if (!_stepsContainAny(steps, ['убавь огонь', 'без лишней влаги'])) {
    violations.add(
      'Картофельная сковорода должна после корочки спокойно дойти без лишней влаги.',
    );
  }
  if (_stepsContainAny(steps, ['отвари картофель', 'пюре', 'вари картофель'])) {
    violations.add(
      'Картофельная сковорода не должна уходить в варёный картофель или пюре.',
    );
  }
}

void _validateGrainPanTechnique({
  required List<String> violations,
  required List<String> steps,
}) {
  if (!_stepsContainAny(steps, ['вари', 'под крышкой', 'залей кипятком'])) {
    violations.add(
      'Крупяная основа должна быть доведена отдельной зерновой техникой.',
    );
  }
  if (!_stepsContainAny(
      steps, ['сначала прогрей добавки', 'вмешай основу', 'впитала вкус'])) {
    violations.add(
      'Зерновое блюдо должно сначала собрать ароматическую часть, а потом принять готовую крупу.',
    );
  }
  if (!_stepsContainAny(
      steps, ['1-2 минуты постоять', 'текстура и аромат стали собраннее'])) {
    violations.add(
      'Зерновому блюду нужен короткий отдых, чтобы крупа успела собрать вкус.',
    );
  }
}

void _validatePastaPanTechnique({
  required List<String> violations,
  required List<String> steps,
}) {
  if (!_stepsContainAny(steps, ['отвари', '8-10 минут', 'al dente'])) {
    violations.add('Паста должна сначала отвариваться до нужной текстуры.');
  }
  if (!_stepsContainAny(steps, ['воды от варки', 'сохрани несколько ложек'])) {
    violations.add(
      'Пасте полезно сохранять немного воды от варки, чтобы собрать соус, а не оставить её сухой.',
    );
  }
  if (!_stepsContainAny(steps, ['сковород', 'прогрей'])) {
    violations.add('Паста должна коротко собираться с добавками на сковороде.');
  }
  if (!_stepsContainAny(
      steps, ['2-3 минуты', 'покрыли пасту', 'обволокли пасту'])) {
    violations.add(
      'Паста должна недолго дойти с добавками, чтобы соки или соус покрыли её, а не стекли мимо.',
    );
  }
  if (_stepsContainAny(steps, ['перевари', '15-20 минут на сковороде'])) {
    violations
        .add('Паста не должна перевариваться и долго тушиться после варки.');
  }
}

void _validateBakeTechnique({
  required List<String> violations,
  required List<String> steps,
}) {
  if (!_stepsContainAny(steps, ['запекай', 'духовк'])) {
    violations.add('Запеканка требует явной духовочной техники.');
  }
  if (!_stepsContainAny(steps, ['в форму', 'ровным слоем'])) {
    violations.add(
      'Запечённое блюдо должно собираться в форме ровным слоем, а не хаотично.',
    );
  }
  if (!_stepsContainAny(steps, ['не пересохло', 'держало форму'])) {
    violations.add(
      'Запеканию нужна защита от сухости через связку, покрытие или контроль влаги.',
    );
  }
  if (!_stepsContainAny(steps, ['3-4 минуты', 'отдохнуть', 'перед подачей'])) {
    violations.add(
      'Запечённому блюду нужен короткий отдых после духовки, чтобы соки стабилизировались.',
    );
  }
}

void _validateSavoryClosedPieTechnique({
  required List<String> violations,
  required List<String> steps,
}) {
  final doughStep = steps.firstWhere(
    (step) =>
        step.contains('подготовь тесто') ||
        step.contains('собери мягкое тесто') ||
        step.contains('просей'),
    orElse: () => '',
  );
  if (!_stepsContainAny(
      steps, ['подготовь тесто', 'собери мягкое тесто', 'просей'])) {
    violations.add(
      'Закрытому пирогу нужно отдельно собрать тесто, а не превращать всё в запеканку.',
    );
  }
  final hasDoughRest = doughStep.contains('отдох') ||
      doughStep.contains('в холоде') ||
      (doughStep.contains('20 минут') && doughStep.contains('тесто'));
  if (!hasDoughRest) {
    violations.add(
      'Тесту для закрытого пирога нужен отдых перед раскаткой.',
    );
  }
  if (!_stepsContainAny(steps, [
    'подготовь начинку',
    'прогрей её 8-10 минут',
    'лишняя влага не уйдёт'
  ])) {
    violations.add(
      'Начинку для пирога нужно отдельно приготовить и убрать лишнюю влагу.',
    );
  }
  if (!_stepsContainAny(steps,
      ['полностью остывшую начинку', 'остывшую начинку', 'холодную начинку'])) {
    violations.add(
      'Начинку в пирог нужно класть остывшей, иначе тесто размокнет.',
    );
  }
  if (!_stepsContainAny(steps, ['раскатай нижний пласт', 'вторым пластом'])) {
    violations.add(
      'Закрытый пирог требует нижний и верхний пласт теста, а не открытый хаос.',
    );
  }
  if (!_stepsContainAny(steps, ['защипни края', 'запечатай шов'])) {
    violations.add(
      'Закрытому пирогу нужно хорошо защипнуть края, чтобы начинка не вытекала.',
    );
  }
  if (!_stepsContainAny(
      steps, ['отверстия для выхода пара', '2-3 отверстия', 'надрез'])) {
    violations.add(
      'У закрытого пирога должен быть выход пара, иначе верх намокнет и лопнет.',
    );
  }
  if (!_stepsContainAny(steps, ['выпекай пирог', '35-40 минут', '180-190'])) {
    violations.add(
      'Пирогу нужна явная духовочная выпечка с понятным временем и температурой.',
    );
  }
  if (!_stepsContainAny(steps, ['12-15 минут', 'затем нарежь', 'подавай'])) {
    violations.add(
      'После духовки пирогу нужен отдых, чтобы начинка и соки стабилизировались.',
    );
  }
}

void _validateShawarmaWrapTechnique({
  required List<String> violations,
  required List<String> steps,
  required bool requiresGarlicInSauce,
}) {
  if (!_stepsContainAny(steps, [
    'очень горячей сковороде',
    'горячей сковороде',
    'румяной корочки',
    'уверенной корочки',
  ])) {
    violations.add(
      'Шаурме нужно быстро обжарить курицу на горячей сковороде до уверенной корочки.',
    );
  }
  if (!_stepsContainAny(steps, [
    'дай ему 2 минуты отдохнуть',
    'дай мясу 2 минуты отдохнуть',
    'короткий отдых',
  ])) {
    violations.add(
      'После жарки курице в шаурме нужен короткий отдых, чтобы сок остался внутри.',
    );
  }
  if (!_stepsContainAny(steps, [
    'тонко нашинкуй',
    'свежую часть отдельно',
    'держи свежую часть отдельно',
  ])) {
    violations.add(
      'Шаурме нужна отдельная свежая часть, а не беспорядочная общая смесь.',
    );
  }
  if (!_stepsContainAny(steps, ['лишнюю влагу', 'промокни сок', 'не текла'])) {
    violations.add(
      'В шаурме нужно контролировать влагу свежей части, иначе лаваш размокнет.',
    );
  }
  if (!_stepsContainAny(steps, [
    'густой холодный соус',
    'смажь середину соусом',
    'смешай сметану',
    'смешай йогурт',
  ])) {
    violations.add(
      'Шаурме нужен отдельный холодный соус, а не сухая сборка.',
    );
  }
  if (requiresGarlicInSauce &&
      !_stepsContainAny(steps, ['с чесноком', 'чесноч'])) {
    violations.add(
      'Если в шаурме есть чеснок, он должен уйти в холодный соус, а не потеряться в фоне.',
    );
  }
  if (!_stepsContainAny(steps, [
    'прогрей лаваш',
    'подогрей лаваш',
    '10-15 секунд',
  ])) {
    violations.add(
      'Перед сборкой шаурме нужно коротко прогреть лаваш, чтобы он не рвался.',
    );
  }
  if (!_stepsContainAny(steps, [
    'оставив сухой край',
    'подверни боковые края',
    'плотно сверни',
    'конвертом',
  ])) {
    violations.add(
      'Шаурму нужно плотно свернуть с сухим краем под шов.',
    );
  }
  if (!_stepsContainAny(steps, [
    'швом вниз',
    '1-2 минуты с каждой стороны',
    'запечатался',
  ])) {
    violations.add(
      'Шаурме нужна финишная обжарка швом вниз, чтобы запечатать рулет и дать хруст.',
    );
  }
  if (!_stepsContainAny(steps, ['подавай сразу', 'ешь сразу', 'немедленно'])) {
    violations.add(
      'Шаурму нужно подавать сразу после финишной обжарки.',
    );
  }
  if (_stepsContainAny(
    steps,
    ['отвари курицу', 'вари курицу', 'залей курицу водой'],
  )) {
    violations.add(
      'Шаурма не должна строиться на варёной курице без жареной корочки.',
    );
  }
}

void _validateBreakfastTechnique({
  required List<String> violations,
  required List<String> steps,
}) {
  if (!_stepsContainAny(steps,
      ['мягкой ровной текстуры', 'мягкую ровную текстуру', 'под крышкой'])) {
    violations.add(
      'Завтрак должен собираться в мягкую текстуру, а не быть грубо пересушенным.',
    );
  }
  if (!_stepsContainAny(steps,
      ['подавай сразу', 'спокойный домашний завтрак', '1 минуту собраться'])) {
    violations.add(
      'Завтрак должен подаваться сразу, пока текстура остаётся лёгкой и живой.',
    );
  }
  if (_stepsContainAny(steps, ['сильном огне до корочки', 'долго туши'])) {
    violations
        .add('Завтрак не должен уходить в тяжёлую или агрессивную технику.');
  }
}

void _validateColdSoupTechnique({
  required List<String> violations,
  required List<String> steps,
}) {
  if (!_stepsContainAny(steps, ['отвари', 'остуди'])) {
    violations.add(
      'Холодный суп требует отдельно сварить основу и затем её остудить.',
    );
  }
  if (!_stepsContainAny(steps, ['влей', 'залей'])) {
    violations
        .add('Холодный суп должен собираться через вливание жидкой базы.');
  }
  if (!_stepsContainAny(steps, ['в холоде', 'холодной', 'охлажд'])) {
    violations.add('Холодный суп должен явно подаваться охлаждённым.');
  }
}

void _validateHotSoupTechnique({
  required List<String> violations,
  required List<String> steps,
}) {
  if (!_stepsContainAny(
      steps, ['влей воду', 'вари суп', 'вари их', 'вари основу'])) {
    violations.add('Суп требует отдельного этапа варки в жидкости.');
  }
  if (!_stepsContainAny(
      steps, ['настояться', 'перед подачей', 'сними с огня'])) {
    violations.add('Супу нужен спокойный финиш перед подачей.');
  }
}

void _validatePanBatterTechnique({
  required List<String> violations,
  required List<String> steps,
}) {
  if (!_stepsContainAny(steps, ['тесто', 'без комков', 'размешай', 'взбей'])) {
    violations.add('Блинное тесто требует явного смешивания до гладкости.');
  }
  if (!_stepsContainAny(steps, ['постоять 8-10 минут', 'отдохнуть'])) {
    violations.add('Блинному тесту нужно коротко постоять перед жаркой.');
  }
  if (!_stepsContainAny(steps, ['сковород', 'с каждой стороны'])) {
    violations.add('Блины должны готовиться на сковороде с двух сторон.');
  }
}

void _validateFritterBatterTechnique({
  required List<String> violations,
  required List<String> steps,
}) {
  if (!_stepsContainAny(steps, ['густое тесто', 'держало форму'])) {
    violations
        .add('Оладьи требуют более густое тесто, а не жидкую блинную массу.');
  }
  if (!_stepsContainAny(steps, ['постоять 5-7 минут', 'отдохнуть'])) {
    violations.add('Тесту для оладий нужно коротко постоять перед жаркой.');
  }
  if (!_stepsContainAny(steps, ['ложкой', 'небольшими порциями'])) {
    violations
        .add('Оладьи должны выкладываться на сковороду небольшими порциями.');
  }
  if (!_stepsContainAny(steps, ['сковород', 'с каждой стороны'])) {
    violations.add('Оладьи должны жариться на сковороде с двух сторон.');
  }
}

void _validateSharedSkilletFritterTechnique({
  required List<String> violations,
  required List<String> steps,
}) {
  if (!_stepsContainAny(steps, ['сковород'])) {
    violations.add(
      'Порционное жареное блюдо должно готовиться на сковороде.',
    );
  }
  if (!_stepsContainAny(steps, ['с каждой стороны'])) {
    violations.add(
      'Порционное жареное блюдо должно доходить с двух сторон.',
    );
  }
}

void _validateCurdFritterTechnique({
  required List<String> violations,
  required List<String> steps,
}) {
  if (!_stepsContainAny(
      steps, ['творожную массу', 'плотную творожную массу'])) {
    violations
        .add('Сырникам нужна плотная творожная масса, а не жидкое тесто.');
  }
  if (!_stepsContainAny(steps, ['сформируй', 'шайбы', 'влажными руками'])) {
    violations.add('Сырники должны формоваться руками в небольшие шайбы.');
  }
}

void _validatePotatoFritterTechnique({
  required List<String> violations,
  required List<String> steps,
}) {
  if (!_stepsContainAny(steps, ['натри', 'тёрт'])) {
    violations.add('Драники требуют тёртую картофельную основу.');
  }
  if (!_stepsContainAny(steps, ['без лишней влаги', 'отожми'])) {
    violations.add(
      'Драникам нужно убрать лишнюю влагу из картофельной массы.',
    );
  }
  if (!_stepsContainAny(steps, ['небольшие порции', 'небольшими порциями'])) {
    violations.add('Драники должны жариться небольшими порциями.');
  }
}

void _validatePerfectOmeletteTechnique({
  required List<String> violations,
  required List<String> steps,
}) {
  if (!_stepsContainAny(steps, ['не до пены', 'слегка взбей'])) {
    violations.add(
        'Классическому омлету нужно мягко взбить яйца, не загоняя их в пену.');
  }
  if (!_stepsContainAny(steps, [
    'пениться, но не темнеть',
    'пениться но не темнеть',
    'должен только пениться',
    'жир должен пениться',
  ])) {
    violations.add(
        'Для классического омлета масло должно только пениться, а не темнеть.');
  }
  if (!_stepsContainAny(
      steps, ['веди лопаткой', 'мелкими движениями непрерывно'])) {
    violations.add(
        'Классический омлет требует постоянного движения лопаткой по дну сковороды.');
  }
  if (!_stepsContainAny(steps,
      ['середина еще немного влажная', 'середина еще немного влажная'])) {
    violations.add(
        'Классический омлет нельзя пересушивать до полной сухости в центре.');
  }
  if (!_stepsContainAny(steps, ['сверни омлет', 'рулетом', 'пополам'])) {
    violations.add(
        'Классический омлет должен собираться в складку или рулет, а не жариться плоско до конца.');
  }
  if (!_stepsContainAny(steps, ['подавай сразу', 'это блюдо не ждет'])) {
    violations.add(
        'Классический омлет нужно подавать сразу, пока текстура еще нежная.');
  }
  if (_stepsContainAny(
      steps, ['сильном огне', 'зажарь до корочки', 'румяной корочки'])) {
    violations.add(
        'Классический омлет не должен жариться на сильном огне до корочки.');
  }
}

void _validateButterEggTechnique({
  required List<String> violations,
  required List<String> steps,
}) {
  if (!_stepsContainAny(steps,
      ['масло начнет пениться', 'жир начнет пениться', 'пенящееся масло'])) {
    violations.add(
        'Яйца в сливочном масле требуют правильного момента пенящегося масла.');
  }
  if (!_stepsContainAny(steps, ['убавь огонь до минимума', 'убавь огонь'])) {
    violations
        .add('Яйца в сливочном масле требуют тихого огня после посадки яиц.');
  }
  if (!_stepsContainAny(steps, ['желток', 'текуч'])) {
    violations.add(
        'Яйца в сливочном масле должны сохранять текучий или живой желток.');
  }
  if (_stepsContainAny(steps, ['взбей', 'болтун', 'омлет'])) {
    violations.add(
        'Яйца в сливочном масле не должны уходить в технику болтуньи или омлета.');
  }
}

void _validatePotatoPureeTechnique({
  required List<String> violations,
  required List<String> steps,
}) {
  if (!_stepsContainAny(
      steps, ['холодной подсоленной водой', 'залей холодной'])) {
    violations.add(
        'Картофельное пюре должно начинаться из холодной подсоленной воды.');
  }
  if (!_stepsContainAny(steps, ['слей воду полностью', 'слей воду'])) {
    violations.add(
        'Картофельному пюре нужно полностью слить воду перед разминанием.');
  }
  if (!_stepsContainAny(steps, ['разомни картофель', 'толкушкой'])) {
    violations
        .add('Картофельное пюре нужно разминать, пока картофель горячий.');
  }
  if (!_stepsContainAny(steps, ['горячим', 'не холодным'])) {
    violations.add(
        'В пюре молочную или масляную часть нужно вводить горячей, а не холодной.');
  }
  if (!_stepsContainAny(
      steps, ['шелковистой текстуры', 'лишняя влага уйдет'])) {
    violations.add(
        'Картофельному пюре нужна работа на сухую и шелковистую текстуру.');
  }
  if (_stepsContainAny(steps, ['блендер', 'измельчи в блендере'])) {
    violations.add(
        'Картофельное пюре не должно идти через блендер и клейкую текстуру.');
  }
}

void _validateCaramelizedOnionToastTechnique({
  required List<String> violations,
  required List<String> steps,
}) {
  if (!_stepsContainAny(steps, ['убавь огонь', 'небольшого'])) {
    violations
        .add('Карамелизированному луку нужен слабый огонь, а не быстрый жар.');
  }
  if (!_stepsContainAny(steps, ['18-20 минут', 'томи лук'])) {
    violations.add(
        'Карамелизированный лук требует долгого томления, а не быстрой обжарки.');
  }
  if (!_stepsContainAny(steps, ['янтарным', 'не подгорать'])) {
    violations.add(
        'Карамелизированный лук должен уходить в янтарную сладость, а не в подгар.');
  }
  if (!_stepsContainAny(steps, ['поджарь', 'хлеб хрустит'])) {
    violations.add(
        'Тост с карамелизированным луком требует отдельно поджаренный хлеб.');
  }
}

void _validateShakshukaTechnique({
  required List<String> violations,
  required List<String> steps,
}) {
  if (!_stepsContainAny(steps, ['5-7 минут', 'загустеет'])) {
    violations.add(
        'Шакшуке нужно сначала собрать и немного загустить томатный соус.');
  }
  if (!_stepsContainAny(steps, ['углубления ложкой', 'углубления'])) {
    violations.add('Шакшука должна делать углубления в соусе под яйца.');
  }
  if (!_stepsContainAny(steps, ['разбей', 'яйцу'])) {
    violations.add(
        'Шакшука должна разбивать яйца прямо в соус, а не вмешивать их в него.');
  }
  if (!_stepsContainAny(steps, ['накрой крышкой'])) {
    violations.add('Шакшуке нужна короткая доводка под крышкой.');
  }
  if (!_stepsContainAny(steps, [
    'желток остаться текучим',
    'снимай с огня до полной готовности желтка'
  ])) {
    violations.add('Шакшука не должна высушивать желток до полной жесткости.');
  }
  if (_stepsContainAny(
      steps, ['взбей яйца', 'перемешай яйца с соусом', 'болтун'])) {
    violations.add(
        'Шакшука не должна превращаться в яичную болтунью в томатном соусе.');
  }
}

void _validateBreadEggTechnique({
  required List<String> violations,
  required List<String> steps,
}) {
  if (!_stepsContainAny(steps, ['вырежи кружок', 'в центре ломтя'])) {
    violations.add('Яйцу в хлебе нужно отверстие в хлебной основе.');
  }
  if (!_stepsContainAny(steps, ['в отверстие', 'прямо в отверстие'])) {
    violations.add('Яйцо в хлебе должно жариться прямо в отверстии хлеба.');
  }
  if (!_stepsContainAny(steps, ['хлеб хрустит', 'подавай сразу'])) {
    violations
        .add('Яйцо в хлебе нужно подавать сразу, пока хлеб держит хруст.');
  }
  if (_stepsContainAny(steps, ['взбей яйца', 'болтун'])) {
    violations
        .add('Яйцо в хлебе не должно превращаться в взбитую яичную массу.');
  }
}

void _validateAglioEOlioTechnique({
  required List<String> violations,
  required List<String> steps,
}) {
  if (!_stepsContainAny(steps,
      ['al dente', 'сохрани 0 5 стакана воды от варки', 'воды от варки'])) {
    violations.add(
        'Aglio e olio требует сохранить крахмальную воду от варки для эмульсии.');
  }
  if (!_stepsContainAny(steps, ['чуть янтарного', 'не коричневого'])) {
    violations.add(
        'Чеснок для aglio e olio должен стать только золотистым, а не коричневым и горьким.');
  }
  if (!_stepsContainAny(steps, ['перемешивай интенсивно', 'обволочет'])) {
    violations.add(
        'Aglio e olio требует собрать эмульсию на сковороде, а не просто полить пасту маслом.');
  }
  if (_stepsContainAny(steps, ['сливки', 'майонез'])) {
    violations
        .add('Aglio e olio не должен уходить в сливочный или майонезный соус.');
  }
}

void _validateCucumberSmetanaTechnique({
  required List<String> violations,
  required List<String> steps,
}) {
  if (!_stepsContainAny(steps, ['оставь на 5 минут', 'отдаст лишнюю воду'])) {
    violations
        .add('Огурцам со сметаной нужно кратко отдать лишнюю воду после соли.');
  }
  if (!_stepsContainAny(steps, ['слей лишнюю жидкость', 'слей лишнюю'])) {
    violations
        .add('Огурцам со сметаной нужно слить лишнюю влагу перед заправкой.');
  }
  if (!_stepsContainAny(steps, ['перемешай аккуратно', 'добавь'])) {
    violations.add('Огурцы со сметаной нужно собирать мягко, не ломая хруст.');
  }
  if (_stepsContainAny(steps, ['запекай', 'обжарь'])) {
    violations.add('Огурцы со сметаной не должны уходить в горячую технику.');
  }
}

void _validatePotatoEggHashTechnique({
  required List<String> violations,
  required List<String> steps,
}) {
  if (!_stepsContainAny(steps, ['кубиками 1 5 см', 'одним слоем'])) {
    violations.add(
        'Картофельному хэшу нужен кубик и один слой для уверенной корочки.');
  }
  if (!_stepsContainAny(steps, ['не трогай 4-5 минут', 'корочка'])) {
    violations.add(
        'Картофельному хэшу нужно дать корочке собраться до первого переворота.');
  }
  if (!_stepsContainAny(steps, ['сдвинь картофель к краям', 'разбей'])) {
    violations.add(
        'Картофельный хэш должен доводить яйцо отдельно в центре сковороды.');
  }
  if (_stepsContainAny(steps, ['отвари картофель', 'пюре'])) {
    violations.add(
        'Картофельный хэш не должен уходить в вареный картофель или пюре.');
  }
}

void _validateSimpleRiceKashaTechnique({
  required List<String> violations,
  required List<String> steps,
}) {
  if (!_stepsContainAny(steps, ['промой', 'до чистой воды'])) {
    violations.add('Простой рисовой каше нужно промыть рис до чистой воды.');
  }
  if (!_stepsContainAny(steps, ['закрой крышкой', '18 минут'])) {
    violations.add(
        'Простая рисовая каша должна доходить под крышкой без лишнего вмешательства.');
  }
  if (!_stepsContainAny(steps, ['дай постоять под крышкой', '5 минут'])) {
    violations.add(
        'Простой рисовой каше нужен короткий отдых под крышкой после огня.');
  }
}

void _validateCutletTechnique({
  required List<String> violations,
  required List<String> steps,
}) {
  if (!_stepsContainAny(steps, ['плотную мясную массу', 'собери плотную'])) {
    violations.add(
      'Котлетам нужна собранная мясная масса, а не рыхлая случайная смесь.',
    );
  }
  if (!_stepsContainAny(
      steps, ['сформируй котлеты', '4-5 минут с каждой стороны'])) {
    violations.add('Котлеты требуют формовки и обжаривания с двух сторон.');
  }
  if (!_stepsContainAny(steps, ['доведи до готовности', 'более мягком огне'])) {
    violations.add(
      'Котлеты нужно не только обжарить, но и спокойно довести до готовности.',
    );
  }
  if (!_stepsContainAny(
      steps, ['соки внутри успеют стабилизироваться', '1-2 минуты'])) {
    violations.add(
      'Котлетам нужен короткий отдых перед подачей, чтобы соки внутри не убежали.',
    );
  }
}

void _validateStewTechnique({
  required List<String> violations,
  required List<String> steps,
}) {
  if (!_stepsContainAny(steps, ['слабом огне', 'туши'])) {
    violations.add('Рагу требует спокойного тушения.');
  }
  if (!_stepsContainAny(
      steps, ['прогрей в самом начале', 'самые плотные продукты'])) {
    violations.add(
      'Рагу должно начинаться с базы и самых плотных продуктов, а не сваливаться в одну фазу.',
    );
  }
  if (!_stepsContainAny(steps, ['под крышкой', 'густой и насыщенной'])) {
    violations.add(
      'Рагу должно доходить под крышкой до густой, собранной текстуры.',
    );
  }
  if (!_stepsContainAny(steps, ['пару минут постоять', 'сними с огня'])) {
    violations.add('Рагу нужно дать коротко успокоиться перед подачей.');
  }
  if (_stepsContainAny(
      steps, ['хрустящей корочки', 'сильном огне до корочки'])) {
    violations.add('Рагу не должно уходить в жёсткую жарку вместо тушения.');
  }
}

bool _containsCanonical(Set<String> canonicals, String target) {
  for (final candidate in canonicals) {
    if (_canonicalVariants(candidate)
        .intersection(_canonicalVariants(target))
        .isNotEmpty) {
      return true;
    }
  }
  return false;
}

bool _stepsContainAny(List<String> steps, Iterable<String> fragments) {
  for (final step in steps) {
    for (final fragment in fragments) {
      if (step.contains(normalizeIngredientText(fragment))) {
        return true;
      }
    }
  }
  return false;
}

bool _stepsContainAll(List<String> steps, List<String> fragments) {
  final normalizedFragments =
      fragments.map(normalizeIngredientText).where((value) => value.isNotEmpty);
  for (final step in steps) {
    if (normalizedFragments.every(step.contains)) {
      return true;
    }
  }
  return false;
}

Set<String> _canonicalVariants(String canonical) {
  final normalized = normalizeIngredientText(canonical);
  return {
    normalized,
    toPairingKey(normalized),
    ...compatibleIngredientKeysForMatching(normalized),
  }.where((value) => value.trim().isNotEmpty).toSet();
}
