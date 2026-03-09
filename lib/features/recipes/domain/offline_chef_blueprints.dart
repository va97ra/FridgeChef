import 'chef_rules.dart';

enum ChefTitleStyle { anchorWithSecondary, anchorWithFocus, inventoryLead }

enum ChefStepStyle {
  eggSkillet,
  potatoSkillet,
  freshSalad,
  grainPan,
  pastaPan,
  soup,
  bake,
  breakfast,
  stew,
}

class ChefSlot {
  final String key;
  final List<String> candidates;
  final int minCount;
  final int maxCount;
  final bool isAnchor;

  const ChefSlot({
    required this.key,
    required this.candidates,
    required this.minCount,
    required this.maxCount,
    this.isAnchor = false,
  });
}

class ChefBlueprint {
  final String id;
  final DishProfile profile;
  final String titlePrefix;
  final String description;
  final int timeMin;
  final int servingsBase;
  final List<String> tags;
  final String anchorSlot;
  final String? secondaryAnchorSlot;
  final String? supportSlot;
  final List<String> preferredStarters;
  final int maxImplicitPantryStarters;
  final ChefTitleStyle titleStyle;
  final ChefStepStyle stepStyle;
  final List<ChefSlot> slots;

  const ChefBlueprint({
    required this.id,
    required this.profile,
    required this.titlePrefix,
    required this.description,
    required this.timeMin,
    required this.servingsBase,
    required this.tags,
    required this.anchorSlot,
    this.secondaryAnchorSlot,
    this.supportSlot,
    required this.preferredStarters,
    this.maxImplicitPantryStarters = 2,
    required this.titleStyle,
    required this.stepStyle,
    required this.slots,
  });
}

const chefBlueprints = <ChefBlueprint>[
  ChefBlueprint(
    id: 'egg_skillet',
    profile: DishProfile.skillet,
    titlePrefix: 'Яичная сковорода',
    description:
        'Быстрое блюдо на одной сковороде, которое помогает пустить в дело яйца и удачные домашние добавки.',
    timeMin: 12,
    servingsBase: 2,
    tags: ['quick', 'breakfast', 'one_pan', 'no_oven', 'generated_local'],
    anchorSlot: 'base',
    secondaryAnchorSlot: 'addons',
    preferredStarters: ['соль', 'перец', 'масло', 'паприка'],
    titleStyle: ChefTitleStyle.anchorWithSecondary,
    stepStyle: ChefStepStyle.eggSkillet,
    slots: [
      ChefSlot(
        key: 'base',
        candidates: ['яйцо'],
        minCount: 1,
        maxCount: 1,
        isAnchor: true,
      ),
      ChefSlot(
        key: 'addons',
        candidates: [
          'помидор',
          'сыр',
          'лук',
          'перец сладкий',
          'грибы',
          'кабачок',
          'брокколи',
        ],
        minCount: 1,
        maxCount: 2,
      ),
    ],
  ),
  ChefBlueprint(
    id: 'potato_skillet',
    profile: DishProfile.skillet,
    titlePrefix: 'Румяный картофель',
    description:
        'Домашняя сковорода, которая хорошо собирает скоропортящиеся продукты в один сытный ужин.',
    timeMin: 24,
    servingsBase: 2,
    tags: ['one_pan', 'no_oven', 'generated_local'],
    anchorSlot: 'base',
    secondaryAnchorSlot: 'addons',
    preferredStarters: ['соль', 'перец', 'масло', 'паприка', 'чеснок'],
    titleStyle: ChefTitleStyle.anchorWithSecondary,
    stepStyle: ChefStepStyle.potatoSkillet,
    slots: [
      ChefSlot(
        key: 'base',
        candidates: ['картофель'],
        minCount: 1,
        maxCount: 1,
        isAnchor: true,
      ),
      ChefSlot(
        key: 'addons',
        candidates: [
          'лук',
          'грибы',
          'сыр',
          'сметана',
          'сосиски',
          'фарш',
          'курица',
          'перец сладкий',
        ],
        minCount: 1,
        maxCount: 2,
      ),
    ],
  ),
  ChefBlueprint(
    id: 'fresh_salad',
    profile: DishProfile.salad,
    titlePrefix: 'Салат из того, что есть',
    description:
        'Свежий вариант, когда нужно быстро собрать полноценное блюдо без долгой готовки.',
    timeMin: 10,
    servingsBase: 2,
    tags: ['quick', 'light', 'no_oven', 'generated_local'],
    anchorSlot: 'fresh',
    secondaryAnchorSlot: 'protein',
    preferredStarters: [
      'соль',
      'перец',
      'оливковое масло',
      'сметана',
      'йогурт',
      'укроп',
    ],
    titleStyle: ChefTitleStyle.inventoryLead,
    stepStyle: ChefStepStyle.freshSalad,
    slots: [
      ChefSlot(
        key: 'fresh',
        candidates: ['огурец', 'помидор', 'капуста', 'перец сладкий'],
        minCount: 2,
        maxCount: 3,
        isAnchor: true,
      ),
      ChefSlot(
        key: 'protein',
        candidates: ['яйцо', 'тунец', 'сыр', 'фасоль', 'кукуруза', 'творог'],
        minCount: 1,
        maxCount: 2,
      ),
    ],
  ),
  ChefBlueprint(
    id: 'grain_pan',
    profile: DishProfile.grainBowl,
    titlePrefix: 'Сытная миска',
    description:
        'Тёплое блюдо, которое использует крупу как основу и собирает вокруг неё самые удачные домашние добавки.',
    timeMin: 22,
    servingsBase: 2,
    tags: ['one_pan', 'generated_local'],
    anchorSlot: 'grain',
    secondaryAnchorSlot: 'protein',
    supportSlot: 'veg',
    preferredStarters: ['соль', 'перец', 'масло', 'паприка', 'чеснок'],
    titleStyle: ChefTitleStyle.anchorWithFocus,
    stepStyle: ChefStepStyle.grainPan,
    slots: [
      ChefSlot(
        key: 'grain',
        candidates: ['рис', 'гречка', 'кускус'],
        minCount: 1,
        maxCount: 1,
        isAnchor: true,
      ),
      ChefSlot(
        key: 'protein',
        candidates: ['курица', 'тунец', 'яйцо', 'фасоль', 'чечевица', 'сыр'],
        minCount: 1,
        maxCount: 1,
      ),
      ChefSlot(
        key: 'veg',
        candidates: [
          'морковь',
          'лук',
          'грибы',
          'перец сладкий',
          'помидор',
          'брокколи',
          'кабачок',
        ],
        minCount: 1,
        maxCount: 2,
      ),
    ],
  ),
  ChefBlueprint(
    id: 'pasta_pan',
    profile: DishProfile.pasta,
    titlePrefix: 'Макароны на скорую руку',
    description:
        'Быстрое тёплое блюдо, которое хорошо работает, если дома есть паста и пара ярких добавок.',
    timeMin: 18,
    servingsBase: 2,
    tags: ['quick', 'one_pan', 'generated_local'],
    anchorSlot: 'base',
    secondaryAnchorSlot: 'addons',
    preferredStarters: ['соль', 'перец', 'масло', 'базилик', 'орегано'],
    titleStyle: ChefTitleStyle.anchorWithSecondary,
    stepStyle: ChefStepStyle.pastaPan,
    slots: [
      ChefSlot(
        key: 'base',
        candidates: ['макароны'],
        minCount: 1,
        maxCount: 1,
        isAnchor: true,
      ),
      ChefSlot(
        key: 'addons',
        candidates: [
          'сыр',
          'помидор',
          'тунец',
          'курица',
          'грибы',
          'чеснок',
          'брокколи',
          'томатная паста',
        ],
        minCount: 2,
        maxCount: 3,
      ),
    ],
  ),
  ChefBlueprint(
    id: 'home_soup',
    profile: DishProfile.soup,
    titlePrefix: 'Домашний суп',
    description:
        'Спокойный суп из текущих запасов, который помогает собрать овощи и базовые продукты в понятную домашнюю тарелку.',
    timeMin: 30,
    servingsBase: 3,
    tags: ['generated_local'],
    anchorSlot: 'base',
    secondaryAnchorSlot: 'veg',
    supportSlot: 'extra',
    preferredStarters: ['соль', 'перец', 'масло', 'чеснок', 'лавровый лист', 'укроп'],
    titleStyle: ChefTitleStyle.anchorWithFocus,
    stepStyle: ChefStepStyle.soup,
    slots: [
      ChefSlot(
        key: 'base',
        candidates: ['курица', 'рыба', 'чечевица', 'картофель'],
        minCount: 1,
        maxCount: 1,
        isAnchor: true,
      ),
      ChefSlot(
        key: 'veg',
        candidates: [
          'морковь',
          'лук',
          'картофель',
          'помидор',
          'капуста',
          'брокколи',
          'кабачок',
          'перец сладкий',
        ],
        minCount: 2,
        maxCount: 3,
      ),
      ChefSlot(
        key: 'extra',
        candidates: ['рис', 'гречка', 'чечевица', 'фасоль'],
        minCount: 0,
        maxCount: 1,
      ),
    ],
  ),
  ChefBlueprint(
    id: 'bake',
    profile: DishProfile.bake,
    titlePrefix: 'Запеканка',
    description:
        'Запечённый вариант для тех случаев, когда хочется собрать холодильник в одно более насыщенное блюдо.',
    timeMin: 34,
    servingsBase: 3,
    tags: ['oven', 'generated_local'],
    anchorSlot: 'base',
    secondaryAnchorSlot: 'addons',
    supportSlot: 'binder',
    preferredStarters: ['соль', 'перец', 'масло', 'паприка', 'итальянские травы'],
    titleStyle: ChefTitleStyle.anchorWithFocus,
    stepStyle: ChefStepStyle.bake,
    slots: [
      ChefSlot(
        key: 'base',
        candidates: ['курица', 'картофель', 'кабачок', 'брокколи', 'фарш'],
        minCount: 1,
        maxCount: 1,
        isAnchor: true,
      ),
      ChefSlot(
        key: 'addons',
        candidates: ['сыр', 'сметана', 'лук', 'помидор', 'перец сладкий', 'грибы'],
        minCount: 2,
        maxCount: 3,
      ),
      ChefSlot(
        key: 'binder',
        candidates: ['яйцо', 'сыр', 'сметана'],
        minCount: 0,
        maxCount: 1,
      ),
    ],
  ),
  ChefBlueprint(
    id: 'breakfast',
    profile: DishProfile.breakfast,
    titlePrefix: 'Домашний завтрак',
    description:
        'Мягкий формат завтрака, который собирается из творога или хлопьев с тем, что уже есть дома.',
    timeMin: 15,
    servingsBase: 2,
    tags: ['quick', 'breakfast', 'generated_local'],
    anchorSlot: 'base',
    secondaryAnchorSlot: 'addons',
    preferredStarters: ['сахар', 'корица'],
    titleStyle: ChefTitleStyle.anchorWithFocus,
    stepStyle: ChefStepStyle.breakfast,
    slots: [
      ChefSlot(
        key: 'base',
        candidates: ['творог', 'овсяные хлопья'],
        minCount: 1,
        maxCount: 1,
        isAnchor: true,
      ),
      ChefSlot(
        key: 'addons',
        candidates: [
          'яблоко',
          'банан',
          'корица',
          'молоко',
          'йогурт',
          'сметана',
          'апельсин',
        ],
        minCount: 1,
        maxCount: 3,
      ),
    ],
  ),
  ChefBlueprint(
    id: 'stew',
    profile: DishProfile.stew,
    titlePrefix: 'Домашнее рагу',
    description:
        'Густое блюдо для тех случаев, когда хочется использовать основу и овощи без лишней сложности.',
    timeMin: 32,
    servingsBase: 3,
    tags: ['generated_local'],
    anchorSlot: 'base',
    secondaryAnchorSlot: 'veg',
    supportSlot: 'extra',
    preferredStarters: ['соль', 'перец', 'масло', 'паприка', 'чеснок', 'томатная паста'],
    titleStyle: ChefTitleStyle.anchorWithFocus,
    stepStyle: ChefStepStyle.stew,
    slots: [
      ChefSlot(
        key: 'base',
        candidates: ['чечевица', 'фасоль', 'картофель', 'фарш'],
        minCount: 1,
        maxCount: 1,
        isAnchor: true,
      ),
      ChefSlot(
        key: 'veg',
        candidates: [
          'лук',
          'морковь',
          'помидор',
          'капуста',
          'перец сладкий',
          'чеснок',
          'кабачок',
        ],
        minCount: 2,
        maxCount: 3,
      ),
      ChefSlot(
        key: 'extra',
        candidates: ['курица', 'рис', 'грибы'],
        minCount: 0,
        maxCount: 1,
      ),
    ],
  ),
];
