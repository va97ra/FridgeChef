import 'chef_rules.dart';

enum ChefTitleStyle { anchorWithSecondary, anchorWithFocus, inventoryLead }

enum ChefStepStyle {
  eggSkillet,
  potatoSkillet,
  freshSalad,
  coldSoup,
  grainPan,
  pastaPan,
  soup,
  bake,
  closedPie,
  shawarmaWrap,
  breakfast,
  panBatter,
  fritterBatter,
  syrniki,
  draniki,
  porridge,
  cutlets,
  stew,
  // Minimalist step styles — professional techniques for 1-2 ingredients
  perfectOmelette,
  butterEgg,
  potatoPuree,
  caramelizedOnion,
  shakshuka,
  breadEggSkillet,
  aglioEOlio,
  cucumberSmetana,
  potatoEggHash,
  simpleRiceKasha,
}

enum ChefDishFamily {
  eggSkillet,
  potatoSkillet,
  freshSalad,
  coldSoup,
  okroshkaColdSoup,
  okroshkaKvassColdSoup,
  olivierSalad,
  vinegretSalad,
  grainPan,
  pastaPan,
  navyPasta,
  soup,
  cabbageSoup,
  borschtSoup,
  fishSoup,
  pickleSoup,
  solyankaSoup,
  bake,
  curdBake,
  savoryClosedPie,
  shawarmaWrap,
  breakfast,
  panBatter,
  bliniPan,
  fritterBatter,
  oladyiFritter,
  curdFritter,
  potatoFritter,
  porridge,
  lazyCabbageRollStew,
  tefteliSauceStew,
  homeCutletDinner,
  zrazyStuffedCutlets,
  bitochkiGravyCutlets,
  zharkoeStew,
  goulashSauceStew,
  stroganoffSauceStew,
  cutlets,
  stew,
  // Minimalist dish families
  perfectOmeletteSkillet,
  butterEggSkillet,
  potatoPureeSide,
  caramelizedOnionToast,
  shakshukaSkillet,
  breadEggSkillet,
  aglioEOlioPasta,
  cucumberSmetanaSalad,
  potatoEggHash,
  simpleRiceKasha,
}

enum ChefSauceStyle {
  tomatoSourCreamGravy,
  mildOnionGravy,
  paprikaTomatoGravy,
  sourCreamPanSauce,
}

enum ChefCutletStyle {
  homeCutlets,
  stuffedZrazy,
  gravyBitochki,
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
  final ChefDishFamily? family;
  final ChefSauceStyle? sauceStyle;
  final ChefCutletStyle? cutletStyle;
  final List<ChefSlot> slots;

  ChefDishFamily get dishFamily {
    if (family != null) {
      return family!;
    }
    switch (stepStyle) {
      case ChefStepStyle.eggSkillet:
        return ChefDishFamily.eggSkillet;
      case ChefStepStyle.potatoSkillet:
        return ChefDishFamily.potatoSkillet;
      case ChefStepStyle.freshSalad:
        return ChefDishFamily.freshSalad;
      case ChefStepStyle.coldSoup:
        return ChefDishFamily.coldSoup;
      case ChefStepStyle.grainPan:
        return ChefDishFamily.grainPan;
      case ChefStepStyle.pastaPan:
        return ChefDishFamily.pastaPan;
      case ChefStepStyle.soup:
        return ChefDishFamily.soup;
      case ChefStepStyle.bake:
        return ChefDishFamily.bake;
      case ChefStepStyle.closedPie:
        return ChefDishFamily.savoryClosedPie;
      case ChefStepStyle.shawarmaWrap:
        return ChefDishFamily.shawarmaWrap;
      case ChefStepStyle.breakfast:
        return ChefDishFamily.breakfast;
      case ChefStepStyle.panBatter:
        return ChefDishFamily.panBatter;
      case ChefStepStyle.fritterBatter:
        return ChefDishFamily.fritterBatter;
      case ChefStepStyle.syrniki:
        return ChefDishFamily.curdFritter;
      case ChefStepStyle.draniki:
        return ChefDishFamily.potatoFritter;
      case ChefStepStyle.porridge:
        return ChefDishFamily.porridge;
      case ChefStepStyle.cutlets:
        return ChefDishFamily.cutlets;
      case ChefStepStyle.stew:
        return ChefDishFamily.stew;
      // Minimalist step styles — family is always set explicitly on the blueprint
      case ChefStepStyle.perfectOmelette:
        return ChefDishFamily.perfectOmeletteSkillet;
      case ChefStepStyle.butterEgg:
        return ChefDishFamily.butterEggSkillet;
      case ChefStepStyle.potatoPuree:
        return ChefDishFamily.potatoPureeSide;
      case ChefStepStyle.caramelizedOnion:
        return ChefDishFamily.caramelizedOnionToast;
      case ChefStepStyle.shakshuka:
        return ChefDishFamily.shakshukaSkillet;
      case ChefStepStyle.breadEggSkillet:
        return ChefDishFamily.breadEggSkillet;
      case ChefStepStyle.aglioEOlio:
        return ChefDishFamily.aglioEOlioPasta;
      case ChefStepStyle.cucumberSmetana:
        return ChefDishFamily.cucumberSmetanaSalad;
      case ChefStepStyle.potatoEggHash:
        return ChefDishFamily.potatoEggHash;
      case ChefStepStyle.simpleRiceKasha:
        return ChefDishFamily.simpleRiceKasha;
    }
  }

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
    this.family,
    this.sauceStyle,
    this.cutletStyle,
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
    preferredStarters: ['масло', 'соль', 'перец', 'паприка'],
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
    preferredStarters: ['масло', 'соль', 'перец', 'паприка', 'чеснок'],
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
    id: 'olivier',
    profile: DishProfile.salad,
    titlePrefix: 'Оливье по-домашнему',
    description:
        'Русский салатный формат, который собирает картофель, яйца и праздничные добавки в знакомый домашний вкус.',
    timeMin: 18,
    servingsBase: 3,
    tags: ['salad', 'russian_classic', 'generated_local'],
    anchorSlot: 'base',
    secondaryAnchorSlot: 'addons',
    preferredStarters: ['соль', 'перец', 'майонез'],
    maxImplicitPantryStarters: 3,
    titleStyle: ChefTitleStyle.inventoryLead,
    stepStyle: ChefStepStyle.freshSalad,
    family: ChefDishFamily.olivierSalad,
    slots: [
      ChefSlot(
        key: 'base',
        candidates: ['картофель', 'яйцо', 'огурец'],
        minCount: 3,
        maxCount: 3,
        isAnchor: true,
      ),
      ChefSlot(
        key: 'addons',
        candidates: ['горошек', 'колбаса'],
        minCount: 1,
        maxCount: 2,
      ),
    ],
  ),
  ChefBlueprint(
    id: 'vinegret',
    profile: DishProfile.salad,
    titlePrefix: 'Винегрет домашний',
    description:
        'Русский корнеплодный салат, который любит свеклу, солёный акцент и спокойную масляную заправку.',
    timeMin: 18,
    servingsBase: 3,
    tags: ['salad', 'russian_classic', 'generated_local'],
    anchorSlot: 'base',
    secondaryAnchorSlot: 'addons',
    preferredStarters: ['масло', 'соль', 'перец', 'укроп'],
    maxImplicitPantryStarters: 4,
    titleStyle: ChefTitleStyle.inventoryLead,
    stepStyle: ChefStepStyle.freshSalad,
    family: ChefDishFamily.vinegretSalad,
    slots: [
      ChefSlot(
        key: 'base',
        candidates: ['свекла', 'картофель'],
        minCount: 2,
        maxCount: 2,
        isAnchor: true,
      ),
      ChefSlot(
        key: 'addons',
        candidates: ['морковь', 'огурец', 'горошек', 'капуста'],
        minCount: 2,
        maxCount: 3,
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
    id: 'grechka_rustic',
    profile: DishProfile.grainBowl,
    titlePrefix: 'Гречка по-домашнему',
    description:
        'Русская сытная гречка, которая лучше всего работает с грибами, луком и простой домашней заправкой.',
    timeMin: 24,
    servingsBase: 2,
    tags: ['russian_classic', 'generated_local'],
    anchorSlot: 'grain',
    secondaryAnchorSlot: 'addons',
    supportSlot: 'veg',
    preferredStarters: ['соль', 'перец', 'масло', 'укроп'],
    maxImplicitPantryStarters: 3,
    titleStyle: ChefTitleStyle.anchorWithFocus,
    stepStyle: ChefStepStyle.grainPan,
    slots: [
      ChefSlot(
        key: 'grain',
        candidates: ['гречка'],
        minCount: 1,
        maxCount: 1,
        isAnchor: true,
      ),
      ChefSlot(
        key: 'addons',
        candidates: ['грибы', 'курица', 'сосиски', 'говядина'],
        minCount: 1,
        maxCount: 1,
      ),
      ChefSlot(
        key: 'veg',
        candidates: ['лук', 'морковь'],
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
    preferredStarters: ['соль', 'перец', 'масло', 'чеснок'],
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
    id: 'makarony_po_flotski',
    profile: DishProfile.pasta,
    titlePrefix: 'Макароны по-флотски',
    description:
        'Домашняя русская классика, где макароны собираются с фаршем, луком и спокойной мясной поджаркой.',
    timeMin: 24,
    servingsBase: 3,
    tags: ['one_pan', 'russian_classic', 'generated_local'],
    anchorSlot: 'base',
    secondaryAnchorSlot: 'protein',
    supportSlot: 'veg',
    preferredStarters: ['соль', 'перец', 'масло', 'чеснок'],
    maxImplicitPantryStarters: 3,
    titleStyle: ChefTitleStyle.anchorWithFocus,
    stepStyle: ChefStepStyle.pastaPan,
    family: ChefDishFamily.navyPasta,
    slots: [
      ChefSlot(
        key: 'base',
        candidates: ['макароны'],
        minCount: 1,
        maxCount: 1,
        isAnchor: true,
      ),
      ChefSlot(
        key: 'protein',
        candidates: ['фарш'],
        minCount: 1,
        maxCount: 1,
      ),
      ChefSlot(
        key: 'veg',
        candidates: ['лук', 'морковь', 'томатная паста'],
        minCount: 1,
        maxCount: 2,
      ),
    ],
  ),
  ChefBlueprint(
    id: 'shchi',
    profile: DishProfile.soup,
    titlePrefix: 'Щи домашние',
    description:
        'Капустный суп в русском домашнем стиле, который любит простую овощную базу, лавровый лист и ложку сметаны.',
    timeMin: 38,
    servingsBase: 3,
    tags: ['russian_classic', 'generated_local'],
    anchorSlot: 'base',
    secondaryAnchorSlot: 'protein',
    supportSlot: 'veg',
    preferredStarters: ['соль', 'перец', 'лавровый лист', 'укроп', 'сметана'],
    maxImplicitPantryStarters: 3,
    titleStyle: ChefTitleStyle.anchorWithFocus,
    stepStyle: ChefStepStyle.soup,
    family: ChefDishFamily.cabbageSoup,
    slots: [
      ChefSlot(
        key: 'base',
        candidates: ['капуста'],
        minCount: 1,
        maxCount: 1,
        isAnchor: true,
      ),
      ChefSlot(
        key: 'protein',
        candidates: ['курица', 'говядина'],
        minCount: 0,
        maxCount: 1,
      ),
      ChefSlot(
        key: 'veg',
        candidates: ['картофель', 'морковь', 'лук'],
        minCount: 2,
        maxCount: 3,
      ),
    ],
  ),
  ChefBlueprint(
    id: 'borscht',
    profile: DishProfile.soup,
    titlePrefix: 'Борщ по-домашнему',
    description:
        'Русско-восточноевропейский свекольный суп, который лучше всего раскрывается на капусте, корнеплодах и мягкой кислой подаче.',
    timeMin: 42,
    servingsBase: 3,
    tags: ['russian_classic', 'generated_local'],
    anchorSlot: 'base',
    secondaryAnchorSlot: 'protein',
    supportSlot: 'veg',
    preferredStarters: [
      'соль',
      'перец',
      'лавровый лист',
      'укроп',
      'сметана',
      'томатная паста',
    ],
    maxImplicitPantryStarters: 3,
    titleStyle: ChefTitleStyle.anchorWithFocus,
    stepStyle: ChefStepStyle.soup,
    family: ChefDishFamily.borschtSoup,
    slots: [
      ChefSlot(
        key: 'base',
        candidates: ['свекла', 'капуста'],
        minCount: 2,
        maxCount: 2,
        isAnchor: true,
      ),
      ChefSlot(
        key: 'protein',
        candidates: ['говядина', 'курица', 'фасоль'],
        minCount: 0,
        maxCount: 1,
      ),
      ChefSlot(
        key: 'veg',
        candidates: ['картофель', 'морковь', 'лук'],
        minCount: 2,
        maxCount: 3,
      ),
      ChefSlot(
        key: 'depth',
        candidates: ['томатная паста'],
        minCount: 1,
        maxCount: 1,
      ),
    ],
  ),
  ChefBlueprint(
    id: 'ukha',
    profile: DishProfile.soup,
    titlePrefix: 'Уха домашняя',
    description:
        'Русский рыбный суп, который опирается на чистый вкус рыбы, корнеплоды и свежий укропный финиш.',
    timeMin: 34,
    servingsBase: 3,
    tags: ['russian_classic', 'generated_local'],
    anchorSlot: 'base',
    secondaryAnchorSlot: 'veg',
    preferredStarters: ['соль', 'перец', 'лавровый лист', 'укроп', 'лимон'],
    maxImplicitPantryStarters: 4,
    titleStyle: ChefTitleStyle.anchorWithFocus,
    stepStyle: ChefStepStyle.soup,
    family: ChefDishFamily.fishSoup,
    slots: [
      ChefSlot(
        key: 'base',
        candidates: ['рыба'],
        minCount: 1,
        maxCount: 1,
        isAnchor: true,
      ),
      ChefSlot(
        key: 'veg',
        candidates: ['картофель', 'лук', 'морковь'],
        minCount: 2,
        maxCount: 3,
      ),
    ],
  ),
  ChefBlueprint(
    id: 'rassolnik',
    profile: DishProfile.soup,
    titlePrefix: 'Рассольник домашний',
    description:
        'Русский суп с перловкой и солёным огурцом, который любит спокойную овощную базу и мягкий сметанный финиш.',
    timeMin: 40,
    servingsBase: 3,
    tags: ['russian_classic', 'generated_local'],
    anchorSlot: 'base',
    secondaryAnchorSlot: 'pickles',
    supportSlot: 'veg',
    preferredStarters: ['соль', 'перец', 'лавровый лист', 'сметана'],
    maxImplicitPantryStarters: 4,
    titleStyle: ChefTitleStyle.anchorWithFocus,
    stepStyle: ChefStepStyle.soup,
    family: ChefDishFamily.pickleSoup,
    slots: [
      ChefSlot(
        key: 'base',
        candidates: ['перловка'],
        minCount: 1,
        maxCount: 1,
        isAnchor: true,
      ),
      ChefSlot(
        key: 'pickles',
        candidates: ['огурец'],
        minCount: 1,
        maxCount: 1,
      ),
      ChefSlot(
        key: 'veg',
        candidates: ['картофель', 'морковь', 'лук'],
        minCount: 2,
        maxCount: 3,
      ),
    ],
  ),
  ChefBlueprint(
    id: 'okroshka_kefir',
    profile: DishProfile.soup,
    titlePrefix: 'Окрошка на кефире',
    description:
        'Холодный русский суп, где кефирная основа держит картофель, яйцо, огурец и зелень в собранной летней подаче.',
    timeMin: 28,
    servingsBase: 3,
    tags: ['quick', 'cold', 'no_oven', 'russian_classic', 'generated_local'],
    anchorSlot: 'base',
    secondaryAnchorSlot: 'fresh',
    supportSlot: 'herbs',
    preferredStarters: ['соль', 'перец'],
    maxImplicitPantryStarters: 2,
    titleStyle: ChefTitleStyle.inventoryLead,
    stepStyle: ChefStepStyle.coldSoup,
    family: ChefDishFamily.okroshkaColdSoup,
    slots: [
      ChefSlot(
        key: 'base',
        candidates: ['кефир'],
        minCount: 1,
        maxCount: 1,
        isAnchor: true,
      ),
      ChefSlot(
        key: 'fresh',
        candidates: ['картофель', 'яйцо', 'огурец'],
        minCount: 3,
        maxCount: 3,
      ),
      ChefSlot(
        key: 'protein',
        candidates: ['колбаса'],
        minCount: 0,
        maxCount: 1,
      ),
      ChefSlot(
        key: 'herbs',
        candidates: ['зелень', 'укроп'],
        minCount: 1,
        maxCount: 2,
      ),
    ],
  ),
  ChefBlueprint(
    id: 'okroshka_kvass',
    profile: DishProfile.soup,
    titlePrefix: 'Окрошка на квасе',
    description:
        'Классический холодный русский суп, где квас даёт лёгкую резкость, а картофель, яйцо, огурец и зелень держат узнаваемую структуру.',
    timeMin: 28,
    servingsBase: 3,
    tags: ['quick', 'cold', 'no_oven', 'russian_classic', 'generated_local'],
    anchorSlot: 'base',
    secondaryAnchorSlot: 'fresh',
    supportSlot: 'herbs',
    preferredStarters: ['соль', 'перец', 'сметана'],
    maxImplicitPantryStarters: 3,
    titleStyle: ChefTitleStyle.inventoryLead,
    stepStyle: ChefStepStyle.coldSoup,
    family: ChefDishFamily.okroshkaKvassColdSoup,
    slots: [
      ChefSlot(
        key: 'base',
        candidates: ['квас'],
        minCount: 1,
        maxCount: 1,
        isAnchor: true,
      ),
      ChefSlot(
        key: 'fresh',
        candidates: ['картофель', 'яйцо', 'огурец'],
        minCount: 3,
        maxCount: 3,
      ),
      ChefSlot(
        key: 'protein',
        candidates: ['колбаса'],
        minCount: 0,
        maxCount: 1,
      ),
      ChefSlot(
        key: 'herbs',
        candidates: ['зелень', 'укроп'],
        minCount: 1,
        maxCount: 2,
      ),
    ],
  ),
  ChefBlueprint(
    id: 'solyanka',
    profile: DishProfile.soup,
    titlePrefix: 'Солянка домашняя',
    description:
        'Русский наваристый суп, где колбасный акцент, солёный огурец и томатная глубина собираются в яркую домашнюю тарелку.',
    timeMin: 36,
    servingsBase: 3,
    tags: ['russian_classic', 'generated_local'],
    anchorSlot: 'protein',
    secondaryAnchorSlot: 'pickles',
    supportSlot: 'veg',
    preferredStarters: ['соль', 'перец', 'лавровый лист', 'сметана', 'лимон'],
    maxImplicitPantryStarters: 4,
    titleStyle: ChefTitleStyle.anchorWithFocus,
    stepStyle: ChefStepStyle.soup,
    family: ChefDishFamily.solyankaSoup,
    slots: [
      ChefSlot(
        key: 'protein',
        candidates: ['колбаса', 'сосиски', 'говядина'],
        minCount: 1,
        maxCount: 2,
        isAnchor: true,
      ),
      ChefSlot(
        key: 'pickles',
        candidates: ['огурец'],
        minCount: 1,
        maxCount: 1,
      ),
      ChefSlot(
        key: 'veg',
        candidates: ['лук', 'томатная паста'],
        minCount: 2,
        maxCount: 2,
      ),
      ChefSlot(
        key: 'finish',
        candidates: ['оливки', 'лимон'],
        minCount: 1,
        maxCount: 2,
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
    preferredStarters: [
      'соль',
      'перец',
      'масло',
      'чеснок',
      'лавровый лист',
      'укроп'
    ],
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
    preferredStarters: ['соль', 'перец', 'масло', 'паприка', 'чеснок'],
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
        candidates: [
          'сыр',
          'сметана',
          'лук',
          'помидор',
          'перец сладкий',
          'грибы'
        ],
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
    id: 'tvorozhnaya_zapekanka',
    profile: DishProfile.bake,
    titlePrefix: 'Творожная запеканка',
    description:
        'Русская домашняя выпечка, где творог держится на яйце и манке, а мягкие сладкие добавки делают вкус собранным.',
    timeMin: 34,
    servingsBase: 3,
    tags: ['oven', 'breakfast', 'russian_classic', 'generated_local'],
    anchorSlot: 'base',
    secondaryAnchorSlot: 'binder',
    supportSlot: 'addons',
    preferredStarters: ['сахар', 'сметана', 'корица'],
    maxImplicitPantryStarters: 3,
    titleStyle: ChefTitleStyle.anchorWithFocus,
    stepStyle: ChefStepStyle.bake,
    family: ChefDishFamily.curdBake,
    slots: [
      ChefSlot(
        key: 'base',
        candidates: ['творог'],
        minCount: 1,
        maxCount: 1,
        isAnchor: true,
      ),
      ChefSlot(
        key: 'binder',
        candidates: ['яйцо', 'манная крупа'],
        minCount: 2,
        maxCount: 2,
      ),
      ChefSlot(
        key: 'addons',
        candidates: ['сметана', 'молоко', 'яблоко', 'банан', 'корица'],
        minCount: 1,
        maxCount: 2,
      ),
    ],
  ),
  ChefBlueprint(
    id: 'cabbage_egg_pie',
    profile: DishProfile.bake,
    titlePrefix: 'Пирог домашний',
    description:
        'Закрытый русский пирог, где мягкое тесто держит отдельно приготовленную капустно-яичную начинку без лишней влаги.',
    timeMin: 72,
    servingsBase: 4,
    tags: ['oven', 'pie', 'russian_classic', 'generated_local'],
    anchorSlot: 'filling',
    secondaryAnchorSlot: 'binder',
    supportSlot: 'dough',
    preferredStarters: ['соль', 'масло сливочное'],
    maxImplicitPantryStarters: 2,
    titleStyle: ChefTitleStyle.anchorWithFocus,
    stepStyle: ChefStepStyle.closedPie,
    family: ChefDishFamily.savoryClosedPie,
    slots: [
      ChefSlot(
        key: 'filling',
        candidates: ['капуста'],
        minCount: 1,
        maxCount: 1,
        isAnchor: true,
      ),
      ChefSlot(
        key: 'binder',
        candidates: ['яйцо'],
        minCount: 1,
        maxCount: 1,
      ),
      ChefSlot(
        key: 'dough',
        candidates: ['мука'],
        minCount: 1,
        maxCount: 1,
      ),
      ChefSlot(
        key: 'aromatic',
        candidates: ['лук'],
        minCount: 0,
        maxCount: 1,
      ),
      ChefSlot(
        key: 'softener',
        candidates: ['сметана', 'кефир', 'молоко'],
        minCount: 0,
        maxCount: 1,
      ),
    ],
  ),
  ChefBlueprint(
    id: 'millet_kasha',
    profile: DishProfile.breakfast,
    titlePrefix: 'Пшённая каша',
    description:
        'Домашняя сладкая каша на молоке, где пшено собирается с маслом и мягким сладким финишем.',
    timeMin: 22,
    servingsBase: 2,
    tags: ['breakfast', 'russian_classic', 'generated_local'],
    anchorSlot: 'grain',
    secondaryAnchorSlot: 'creamy',
    supportSlot: 'addons',
    preferredStarters: ['сахар', 'корица'],
    maxImplicitPantryStarters: 2,
    titleStyle: ChefTitleStyle.anchorWithFocus,
    stepStyle: ChefStepStyle.porridge,
    slots: [
      ChefSlot(
        key: 'grain',
        candidates: ['пшено'],
        minCount: 1,
        maxCount: 1,
        isAnchor: true,
      ),
      ChefSlot(
        key: 'creamy',
        candidates: ['молоко', 'масло сливочное', 'сахар'],
        minCount: 2,
        maxCount: 3,
      ),
      ChefSlot(
        key: 'addons',
        candidates: ['яблоко', 'банан', 'корица'],
        minCount: 0,
        maxCount: 1,
      ),
    ],
  ),
  ChefBlueprint(
    id: 'rice_kasha',
    profile: DishProfile.breakfast,
    titlePrefix: 'Рисовая каша',
    description:
        'Спокойная молочная каша по-домашнему, где рис держит мягкую текстуру и любит сливочный финиш.',
    timeMin: 24,
    servingsBase: 2,
    tags: ['breakfast', 'russian_classic', 'generated_local'],
    anchorSlot: 'grain',
    secondaryAnchorSlot: 'creamy',
    supportSlot: 'addons',
    preferredStarters: ['сахар', 'корица'],
    maxImplicitPantryStarters: 2,
    titleStyle: ChefTitleStyle.anchorWithFocus,
    stepStyle: ChefStepStyle.porridge,
    slots: [
      ChefSlot(
        key: 'grain',
        candidates: ['рис'],
        minCount: 1,
        maxCount: 1,
        isAnchor: true,
      ),
      ChefSlot(
        key: 'creamy',
        candidates: ['молоко', 'масло сливочное', 'сахар'],
        minCount: 2,
        maxCount: 3,
      ),
      ChefSlot(
        key: 'addons',
        candidates: ['яблоко', 'банан', 'корица'],
        minCount: 0,
        maxCount: 1,
      ),
    ],
  ),
  ChefBlueprint(
    id: 'manna_kasha',
    profile: DishProfile.breakfast,
    titlePrefix: 'Манная каша',
    description:
        'Классическая домашняя манка, которая держится на молоке, сливочном масле и мягкой сладкой подаче.',
    timeMin: 12,
    servingsBase: 2,
    tags: ['breakfast', 'russian_classic', 'generated_local'],
    anchorSlot: 'grain',
    secondaryAnchorSlot: 'creamy',
    supportSlot: 'addons',
    preferredStarters: ['сахар', 'корица'],
    maxImplicitPantryStarters: 2,
    titleStyle: ChefTitleStyle.anchorWithFocus,
    stepStyle: ChefStepStyle.porridge,
    slots: [
      ChefSlot(
        key: 'grain',
        candidates: ['манная крупа'],
        minCount: 1,
        maxCount: 1,
        isAnchor: true,
      ),
      ChefSlot(
        key: 'creamy',
        candidates: ['молоко', 'масло сливочное', 'сахар'],
        minCount: 2,
        maxCount: 3,
      ),
      ChefSlot(
        key: 'addons',
        candidates: ['яблоко', 'банан', 'корица'],
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
    id: 'blini',
    profile: DishProfile.breakfast,
    titlePrefix: 'Блины домашние',
    description:
        'Русское тонкое тесто на сковороде, где мука, молоко и яйцо должны собраться в гладкий блин без комков.',
    timeMin: 22,
    servingsBase: 3,
    tags: ['breakfast', 'one_pan', 'russian_classic', 'generated_local'],
    anchorSlot: 'batter',
    secondaryAnchorSlot: 'liquid',
    supportSlot: 'binder',
    preferredStarters: ['соль', 'сахар', 'масло'],
    maxImplicitPantryStarters: 3,
    titleStyle: ChefTitleStyle.inventoryLead,
    stepStyle: ChefStepStyle.panBatter,
    family: ChefDishFamily.bliniPan,
    slots: [
      ChefSlot(
        key: 'batter',
        candidates: ['мука'],
        minCount: 1,
        maxCount: 1,
        isAnchor: true,
      ),
      ChefSlot(
        key: 'liquid',
        candidates: ['молоко'],
        minCount: 1,
        maxCount: 1,
      ),
      ChefSlot(
        key: 'binder',
        candidates: ['яйцо'],
        minCount: 1,
        maxCount: 1,
      ),
      ChefSlot(
        key: 'addons',
        candidates: ['сахар', 'масло сливочное'],
        minCount: 0,
        maxCount: 2,
      ),
    ],
  ),
  ChefBlueprint(
    id: 'oladyi',
    profile: DishProfile.breakfast,
    titlePrefix: 'Оладьи на кефире',
    description:
        'Густое домашнее тесто на кефире, которое жарится небольшими порциями и должно оставаться пышным внутри.',
    timeMin: 20,
    servingsBase: 3,
    tags: ['breakfast', 'one_pan', 'russian_classic', 'generated_local'],
    anchorSlot: 'batter',
    secondaryAnchorSlot: 'liquid',
    supportSlot: 'binder',
    preferredStarters: ['соль', 'сахар', 'масло'],
    maxImplicitPantryStarters: 3,
    titleStyle: ChefTitleStyle.inventoryLead,
    stepStyle: ChefStepStyle.fritterBatter,
    family: ChefDishFamily.oladyiFritter,
    slots: [
      ChefSlot(
        key: 'batter',
        candidates: ['мука'],
        minCount: 1,
        maxCount: 1,
        isAnchor: true,
      ),
      ChefSlot(
        key: 'liquid',
        candidates: ['кефир'],
        minCount: 1,
        maxCount: 1,
      ),
      ChefSlot(
        key: 'binder',
        candidates: ['яйцо'],
        minCount: 1,
        maxCount: 1,
      ),
      ChefSlot(
        key: 'addons',
        candidates: ['сахар', 'масло сливочное'],
        minCount: 0,
        maxCount: 2,
      ),
    ],
  ),
  ChefBlueprint(
    id: 'syrniki',
    profile: DishProfile.breakfast,
    titlePrefix: 'Сырники',
    description:
        'Русский творожный завтрак, который собирается вокруг творога, яйца и мягкого сладкого финиша.',
    timeMin: 18,
    servingsBase: 2,
    tags: ['quick', 'breakfast', 'russian_classic', 'generated_local'],
    anchorSlot: 'base',
    secondaryAnchorSlot: 'binder',
    supportSlot: 'addons',
    preferredStarters: ['сахар', 'сметана', 'корица'],
    maxImplicitPantryStarters: 3,
    titleStyle: ChefTitleStyle.anchorWithFocus,
    stepStyle: ChefStepStyle.syrniki,
    family: ChefDishFamily.curdFritter,
    slots: [
      ChefSlot(
        key: 'base',
        candidates: ['творог'],
        minCount: 1,
        maxCount: 1,
        isAnchor: true,
      ),
      ChefSlot(
        key: 'binder',
        candidates: ['яйцо'],
        minCount: 1,
        maxCount: 1,
      ),
      ChefSlot(
        key: 'addons',
        candidates: ['яблоко', 'банан', 'корица'],
        minCount: 0,
        maxCount: 1,
      ),
    ],
  ),
  ChefBlueprint(
    id: 'draniki',
    profile: DishProfile.skillet,
    titlePrefix: 'Драники',
    description:
        'Русско-белорусская картофельная сковорода, где тёртый картофель собирается с луком и мягким домашним финишем.',
    timeMin: 20,
    servingsBase: 2,
    tags: ['quick', 'russian_classic', 'generated_local'],
    anchorSlot: 'base',
    secondaryAnchorSlot: 'binder',
    supportSlot: 'aromatics',
    preferredStarters: ['соль', 'перец', 'сметана', 'масло'],
    maxImplicitPantryStarters: 4,
    titleStyle: ChefTitleStyle.anchorWithFocus,
    stepStyle: ChefStepStyle.draniki,
    family: ChefDishFamily.potatoFritter,
    slots: [
      ChefSlot(
        key: 'base',
        candidates: ['картофель'],
        minCount: 1,
        maxCount: 1,
        isAnchor: true,
      ),
      ChefSlot(
        key: 'binder',
        candidates: ['яйцо', 'мука'],
        minCount: 1,
        maxCount: 2,
      ),
      ChefSlot(
        key: 'aromatics',
        candidates: ['лук'],
        minCount: 1,
        maxCount: 1,
      ),
    ],
  ),
  ChefBlueprint(
    id: 'lazy_cabbage_rolls',
    profile: DishProfile.stew,
    titlePrefix: 'Ленивые голубцы',
    description:
        'Домашнее тушёное блюдо, где капуста, фарш и рис собираются в спокойный томатный вкус без лишней возни.',
    timeMin: 34,
    servingsBase: 3,
    tags: ['russian_classic', 'generated_local'],
    anchorSlot: 'protein',
    secondaryAnchorSlot: 'grain',
    supportSlot: 'veg',
    preferredStarters: [
      'соль',
      'перец',
      'томатная паста',
      'сметана',
      'лавровый лист',
    ],
    maxImplicitPantryStarters: 4,
    titleStyle: ChefTitleStyle.anchorWithFocus,
    stepStyle: ChefStepStyle.stew,
    family: ChefDishFamily.lazyCabbageRollStew,
    slots: [
      ChefSlot(
        key: 'protein',
        candidates: ['фарш'],
        minCount: 1,
        maxCount: 1,
        isAnchor: true,
      ),
      ChefSlot(
        key: 'grain',
        candidates: ['рис'],
        minCount: 1,
        maxCount: 1,
      ),
      ChefSlot(
        key: 'veg',
        candidates: ['капуста', 'лук', 'морковь', 'томатная паста'],
        minCount: 3,
        maxCount: 4,
      ),
    ],
  ),
  ChefBlueprint(
    id: 'tefteli',
    profile: DishProfile.stew,
    titlePrefix: 'Тефтели в соусе',
    description:
        'Домашние тефтели, где фарш и рис собираются в спокойный томатно-сметанный соус без лишней тяжести.',
    timeMin: 34,
    servingsBase: 3,
    tags: ['russian_classic', 'generated_local'],
    anchorSlot: 'protein',
    secondaryAnchorSlot: 'grain',
    supportSlot: 'sauce',
    preferredStarters: [
      'соль',
      'перец',
      'томатная паста',
      'сметана',
      'лавровый лист',
    ],
    maxImplicitPantryStarters: 4,
    titleStyle: ChefTitleStyle.anchorWithFocus,
    stepStyle: ChefStepStyle.stew,
    family: ChefDishFamily.tefteliSauceStew,
    sauceStyle: ChefSauceStyle.tomatoSourCreamGravy,
    slots: [
      ChefSlot(
        key: 'protein',
        candidates: ['фарш'],
        minCount: 1,
        maxCount: 1,
        isAnchor: true,
      ),
      ChefSlot(
        key: 'grain',
        candidates: ['рис'],
        minCount: 1,
        maxCount: 1,
      ),
      ChefSlot(
        key: 'sauce',
        candidates: ['лук', 'морковь', 'томатная паста', 'сметана'],
        minCount: 1,
        maxCount: 3,
      ),
    ],
  ),
  ChefBlueprint(
    id: 'kotlet_dinner',
    profile: DishProfile.stew,
    titlePrefix: 'Котлеты по-домашнему',
    description:
        'Домашний котлетный ужин, где мясная основа идёт вместе с простым гарниром и спокойной овощной поджаркой.',
    timeMin: 30,
    servingsBase: 3,
    tags: ['russian_classic', 'generated_local'],
    anchorSlot: 'protein',
    secondaryAnchorSlot: 'side',
    supportSlot: 'veg',
    preferredStarters: ['соль', 'перец', 'масло', 'сметана'],
    maxImplicitPantryStarters: 4,
    titleStyle: ChefTitleStyle.anchorWithFocus,
    stepStyle: ChefStepStyle.cutlets,
    family: ChefDishFamily.homeCutletDinner,
    cutletStyle: ChefCutletStyle.homeCutlets,
    slots: [
      ChefSlot(
        key: 'protein',
        candidates: ['фарш'],
        minCount: 1,
        maxCount: 1,
        isAnchor: true,
      ),
      ChefSlot(
        key: 'side',
        candidates: ['картофель', 'гречка'],
        minCount: 1,
        maxCount: 1,
      ),
      ChefSlot(
        key: 'veg',
        candidates: ['лук', 'морковь'],
        minCount: 1,
        maxCount: 2,
      ),
    ],
  ),
  ChefBlueprint(
    id: 'zrazy',
    profile: DishProfile.stew,
    titlePrefix: 'Зразы по-домашнему',
    description:
        'Домашние зразы, где мясная оболочка держит начинку внутри, а блюдо подаётся с отдельным гарниром.',
    timeMin: 38,
    servingsBase: 3,
    tags: ['russian_classic', 'generated_local'],
    anchorSlot: 'protein',
    secondaryAnchorSlot: 'side',
    supportSlot: 'filling',
    preferredStarters: ['соль', 'перец', 'масло', 'сметана'],
    maxImplicitPantryStarters: 4,
    titleStyle: ChefTitleStyle.anchorWithFocus,
    stepStyle: ChefStepStyle.cutlets,
    family: ChefDishFamily.zrazyStuffedCutlets,
    cutletStyle: ChefCutletStyle.stuffedZrazy,
    slots: [
      ChefSlot(
        key: 'protein',
        candidates: ['фарш'],
        minCount: 1,
        maxCount: 1,
        isAnchor: true,
      ),
      ChefSlot(
        key: 'side',
        candidates: ['картофель', 'гречка'],
        minCount: 1,
        maxCount: 1,
      ),
      ChefSlot(
        key: 'filling',
        candidates: ['яйцо', 'грибы'],
        minCount: 1,
        maxCount: 1,
      ),
      ChefSlot(
        key: 'veg',
        candidates: ['лук'],
        minCount: 0,
        maxCount: 1,
      ),
    ],
  ),
  ChefBlueprint(
    id: 'bitochki',
    profile: DishProfile.stew,
    titlePrefix: 'Биточки с подливкой',
    description:
        'Мягкие биточки, которые сначала схватываются на сковороде, а потом доходят в спокойной домашней подливке с гарниром.',
    timeMin: 34,
    servingsBase: 3,
    tags: ['russian_classic', 'generated_local'],
    anchorSlot: 'protein',
    secondaryAnchorSlot: 'side',
    supportSlot: 'sauce',
    preferredStarters: ['соль', 'перец', 'масло', 'сметана'],
    maxImplicitPantryStarters: 4,
    titleStyle: ChefTitleStyle.anchorWithFocus,
    stepStyle: ChefStepStyle.cutlets,
    family: ChefDishFamily.bitochkiGravyCutlets,
    sauceStyle: ChefSauceStyle.mildOnionGravy,
    cutletStyle: ChefCutletStyle.gravyBitochki,
    slots: [
      ChefSlot(
        key: 'protein',
        candidates: ['фарш'],
        minCount: 1,
        maxCount: 1,
        isAnchor: true,
      ),
      ChefSlot(
        key: 'side',
        candidates: ['картофель', 'гречка'],
        minCount: 1,
        maxCount: 1,
      ),
      ChefSlot(
        key: 'sauce',
        candidates: ['лук', 'морковь', 'сметана'],
        minCount: 2,
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
    preferredStarters: [
      'соль',
      'перец',
      'масло',
      'паприка',
      'чеснок',
      'томатная паста'
    ],
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
  ChefBlueprint(
    id: 'zharkoe',
    profile: DishProfile.stew,
    titlePrefix: 'Жаркое по-домашнему',
    description:
        'Классическое русское жаркое, где картофель собирает мясо, корнеплоды и спокойный густой соус.',
    timeMin: 36,
    servingsBase: 3,
    tags: ['russian_classic', 'generated_local'],
    anchorSlot: 'base',
    secondaryAnchorSlot: 'protein',
    supportSlot: 'veg',
    preferredStarters: ['соль', 'перец', 'лавровый лист', 'чеснок', 'сметана'],
    maxImplicitPantryStarters: 3,
    titleStyle: ChefTitleStyle.anchorWithFocus,
    stepStyle: ChefStepStyle.stew,
    family: ChefDishFamily.zharkoeStew,
    slots: [
      ChefSlot(
        key: 'base',
        candidates: ['картофель'],
        minCount: 1,
        maxCount: 1,
        isAnchor: true,
      ),
      ChefSlot(
        key: 'protein',
        candidates: ['говядина', 'свинина', 'курица'],
        minCount: 1,
        maxCount: 1,
      ),
      ChefSlot(
        key: 'veg',
        candidates: ['лук', 'морковь', 'грибы', 'перец сладкий'],
        minCount: 1,
        maxCount: 2,
      ),
    ],
  ),
  ChefBlueprint(
    id: 'goulash',
    profile: DishProfile.stew,
    titlePrefix: 'Гуляш по-домашнему',
    description:
        'Густой домашний гуляш, где мясо собирается через лук, паприку и томатную глубину в мягкий соус.',
    timeMin: 40,
    servingsBase: 3,
    tags: ['russian_classic', 'generated_local'],
    anchorSlot: 'protein',
    secondaryAnchorSlot: 'aromatic',
    supportSlot: 'sauce',
    preferredStarters: [
      'соль',
      'перец',
      'паприка',
      'томатная паста',
      'лавровый лист',
      'масло',
    ],
    maxImplicitPantryStarters: 4,
    titleStyle: ChefTitleStyle.anchorWithFocus,
    stepStyle: ChefStepStyle.stew,
    family: ChefDishFamily.goulashSauceStew,
    sauceStyle: ChefSauceStyle.paprikaTomatoGravy,
    slots: [
      ChefSlot(
        key: 'protein',
        candidates: ['говядина', 'свинина'],
        minCount: 1,
        maxCount: 1,
        isAnchor: true,
      ),
      ChefSlot(
        key: 'aromatic',
        candidates: ['лук'],
        minCount: 1,
        maxCount: 1,
      ),
      ChefSlot(
        key: 'veg',
        candidates: ['морковь', 'перец сладкий'],
        minCount: 0,
        maxCount: 2,
      ),
      ChefSlot(
        key: 'sauce',
        candidates: ['томатная паста', 'чеснок', 'паприка'],
        minCount: 0,
        maxCount: 2,
      ),
    ],
  ),
  ChefBlueprint(
    id: 'beef_stroganoff',
    profile: DishProfile.stew,
    titlePrefix: 'Бефстроганов',
    description:
        'Тонко нарезанная говядина в мягком сметанном соусе с луком и при желании грибной глубиной.',
    timeMin: 28,
    servingsBase: 3,
    tags: ['russian_classic', 'generated_local'],
    anchorSlot: 'protein',
    secondaryAnchorSlot: 'aromatic',
    supportSlot: 'sauce',
    preferredStarters: ['соль', 'перец', 'масло', 'сметана', 'горчица'],
    maxImplicitPantryStarters: 4,
    titleStyle: ChefTitleStyle.anchorWithFocus,
    stepStyle: ChefStepStyle.stew,
    family: ChefDishFamily.stroganoffSauceStew,
    sauceStyle: ChefSauceStyle.sourCreamPanSauce,
    slots: [
      ChefSlot(
        key: 'protein',
        candidates: ['говядина'],
        minCount: 1,
        maxCount: 1,
        isAnchor: true,
      ),
      ChefSlot(
        key: 'aromatic',
        candidates: ['лук'],
        minCount: 1,
        maxCount: 1,
      ),
      ChefSlot(
        key: 'veg',
        candidates: ['грибы'],
        minCount: 0,
        maxCount: 2,
      ),
      ChefSlot(
        key: 'sauce',
        candidates: ['сметана', 'горчица', 'мука'],
        minCount: 0,
        maxCount: 2,
      ),
    ],
  ),
  ChefBlueprint(
    id: 'stewed_cabbage',
    profile: DishProfile.stew,
    titlePrefix: 'Тушёная капуста',
    description:
        'Домашняя тушёная капуста, которая любит лук, морковь, томатную глубину и при желании колбасный акцент.',
    timeMin: 28,
    servingsBase: 3,
    tags: ['russian_classic', 'generated_local'],
    anchorSlot: 'base',
    secondaryAnchorSlot: 'protein',
    supportSlot: 'veg',
    preferredStarters: [
      'соль',
      'перец',
      'лавровый лист',
      'томатная паста',
    ],
    maxImplicitPantryStarters: 4,
    titleStyle: ChefTitleStyle.anchorWithFocus,
    stepStyle: ChefStepStyle.stew,
    slots: [
      ChefSlot(
        key: 'base',
        candidates: ['капуста'],
        minCount: 1,
        maxCount: 1,
        isAnchor: true,
      ),
      ChefSlot(
        key: 'protein',
        candidates: ['колбаса', 'сосиски', 'курица', 'свинина'],
        minCount: 0,
        maxCount: 1,
      ),
      ChefSlot(
        key: 'veg',
        candidates: ['лук', 'морковь', 'томатная паста'],
        minCount: 2,
        maxCount: 3,
      ),
    ],
  ),

  // ─── MINIMALIST BLUEPRINTS ──────────────────────────────────────────────────
  // These blueprints are designed for 1-2 fridge ingredients + pantry.
  // Tagged 'minimal' so the engine applies a lower chef-score threshold.

  ChefBlueprint(
    id: 'perfect_omelette',
    profile: DishProfile.skillet,
    titlePrefix: 'Омлет классический',
    description:
        'Французский омлет по технике Эскофье: минимум ингредиентов, максимум вкуса. '
        'Тихий огонь, постоянное движение, нежный рулет.',
    timeMin: 8,
    servingsBase: 1,
    tags: ['quick', 'breakfast', 'one_pan', 'minimal', 'generated_local'],
    anchorSlot: 'base',
    secondaryAnchorSlot: 'addons',
    preferredStarters: ['масло сливочное', 'соль', 'перец', 'укроп'],
    maxImplicitPantryStarters: 3,
    titleStyle: ChefTitleStyle.anchorWithSecondary,
    stepStyle: ChefStepStyle.perfectOmelette,
    family: ChefDishFamily.perfectOmeletteSkillet,
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
        candidates: ['сыр', 'помидор', 'грибы', 'зелень'],
        minCount: 0,
        maxCount: 1,
      ),
    ],
  ),

  ChefBlueprint(
    id: 'butter_egg',
    profile: DishProfile.skillet,
    titlePrefix: 'Яйца в сливочном масле',
    description: 'Яйца, медленно приготовленные в пенящемся сливочном масле. '
        'Классика французской домашней кухни: нежный желток, хрустящий белок.',
    timeMin: 6,
    servingsBase: 1,
    tags: ['quick', 'breakfast', 'one_pan', 'minimal', 'generated_local'],
    anchorSlot: 'base',
    secondaryAnchorSlot: 'finish',
    preferredStarters: ['масло сливочное', 'соль', 'перец'],
    maxImplicitPantryStarters: 3,
    titleStyle: ChefTitleStyle.anchorWithSecondary,
    stepStyle: ChefStepStyle.butterEgg,
    family: ChefDishFamily.butterEggSkillet,
    slots: [
      ChefSlot(
        key: 'base',
        candidates: ['яйцо'],
        minCount: 1,
        maxCount: 1,
        isAnchor: true,
      ),
      ChefSlot(
        key: 'finish',
        candidates: ['зелень', 'укроп', 'хлеб'],
        minCount: 0,
        maxCount: 1,
      ),
    ],
  ),

  ChefBlueprint(
    id: 'potato_puree',
    profile: DishProfile.general,
    titlePrefix: 'Картофельное пюре',
    description:
        'Шёлковое картофельное пюре — горячее молоко, холодное сливочное масло, '
        'протёртое через сито. Французская техника, домашний вкус.',
    timeMin: 22,
    servingsBase: 2,
    tags: ['quick', 'minimal', 'generated_local'],
    anchorSlot: 'base',
    secondaryAnchorSlot: 'creamy',
    preferredStarters: ['масло сливочное', 'молоко', 'соль', 'мускатный орех'],
    maxImplicitPantryStarters: 4,
    titleStyle: ChefTitleStyle.anchorWithFocus,
    stepStyle: ChefStepStyle.potatoPuree,
    family: ChefDishFamily.potatoPureeSide,
    slots: [
      ChefSlot(
        key: 'base',
        candidates: ['картофель'],
        minCount: 1,
        maxCount: 1,
        isAnchor: true,
      ),
      ChefSlot(
        key: 'creamy',
        candidates: ['молоко', 'масло сливочное'],
        minCount: 0,
        maxCount: 2,
      ),
    ],
  ),

  ChefBlueprint(
    id: 'caramelized_onion_toast',
    profile: DishProfile.skillet,
    titlePrefix: 'Тост с карамелизированным луком',
    description:
        'Лук, томлённый на медленном огне до янтарной сладости, на поджаренном хлебе. '
        'Простое блюдо с невероятно глубоким вкусом.',
    timeMin: 24,
    servingsBase: 2,
    tags: ['quick', 'minimal', 'generated_local'],
    anchorSlot: 'base',
    secondaryAnchorSlot: 'topping',
    preferredStarters: ['масло сливочное', 'соль', 'перец', 'сахар'],
    maxImplicitPantryStarters: 4,
    titleStyle: ChefTitleStyle.anchorWithSecondary,
    stepStyle: ChefStepStyle.caramelizedOnion,
    family: ChefDishFamily.caramelizedOnionToast,
    slots: [
      ChefSlot(
        key: 'base',
        candidates: ['лук'],
        minCount: 1,
        maxCount: 1,
        isAnchor: true,
      ),
      ChefSlot(
        key: 'topping',
        candidates: ['хлеб', 'сыр', 'лаваш'],
        minCount: 1,
        maxCount: 1,
      ),
    ],
  ),

  ChefBlueprint(
    id: 'shakshuka_light',
    profile: DishProfile.skillet,
    titlePrefix: 'Шакшука',
    description:
        'Яйца, припущенные прямо в томатном соусе с паприкой и чесноком. '
        'Ближневосточная классика: сытно, ярко, готовится за 15 минут.',
    timeMin: 16,
    servingsBase: 2,
    tags: ['quick', 'one_pan', 'minimal', 'generated_local'],
    anchorSlot: 'sauce',
    secondaryAnchorSlot: 'base',
    preferredStarters: ['масло', 'паприка', 'чеснок', 'соль', 'перец'],
    maxImplicitPantryStarters: 4,
    titleStyle: ChefTitleStyle.anchorWithSecondary,
    stepStyle: ChefStepStyle.shakshuka,
    family: ChefDishFamily.shakshukaSkillet,
    slots: [
      ChefSlot(
        key: 'sauce',
        candidates: ['помидор', 'томатная паста'],
        minCount: 1,
        maxCount: 1,
        isAnchor: true,
      ),
      ChefSlot(
        key: 'base',
        candidates: ['яйцо'],
        minCount: 1,
        maxCount: 1,
      ),
      ChefSlot(
        key: 'addons',
        candidates: ['лук', 'перец сладкий', 'сыр'],
        minCount: 0,
        maxCount: 2,
      ),
    ],
  ),

  ChefBlueprint(
    id: 'bread_egg_skillet',
    profile: DishProfile.skillet,
    titlePrefix: 'Яйцо в хлебе',
    description:
        'Ломтик хлеба с вырезанным центром, яйцо жарится прямо в отверстии. '
        'Хрустящий хлеб, мягкий желток — завтрак за 5 минут.',
    timeMin: 6,
    servingsBase: 1,
    tags: ['quick', 'breakfast', 'one_pan', 'minimal', 'generated_local'],
    anchorSlot: 'base',
    secondaryAnchorSlot: 'protein',
    preferredStarters: ['масло сливочное', 'соль', 'перец'],
    maxImplicitPantryStarters: 3,
    titleStyle: ChefTitleStyle.anchorWithSecondary,
    stepStyle: ChefStepStyle.breadEggSkillet,
    family: ChefDishFamily.breadEggSkillet,
    slots: [
      ChefSlot(
        key: 'base',
        candidates: ['хлеб', 'лаваш'],
        minCount: 1,
        maxCount: 1,
        isAnchor: true,
      ),
      ChefSlot(
        key: 'protein',
        candidates: ['яйцо'],
        minCount: 1,
        maxCount: 1,
      ),
      ChefSlot(
        key: 'finish',
        candidates: ['сыр', 'помидор'],
        minCount: 0,
        maxCount: 1,
      ),
    ],
  ),

  ChefBlueprint(
    id: 'aglio_e_olio',
    profile: DishProfile.pasta,
    titlePrefix: 'Паста с чесноком и маслом',
    description:
        'Знаменитая итальянская паста aglio e olio: чеснок томится в оливковом масле '
        'до золотистого, паста заканчивается прямо на сковороде. '
        'Минимум ингредиентов, максимум вкуса.',
    timeMin: 15,
    servingsBase: 2,
    tags: ['quick', 'one_pan', 'minimal', 'generated_local'],
    anchorSlot: 'base',
    secondaryAnchorSlot: 'aromatic',
    preferredStarters: ['оливковое масло', 'масло', 'соль', 'перец', 'чеснок'],
    maxImplicitPantryStarters: 4,
    titleStyle: ChefTitleStyle.anchorWithSecondary,
    stepStyle: ChefStepStyle.aglioEOlio,
    family: ChefDishFamily.aglioEOlioPasta,
    slots: [
      ChefSlot(
        key: 'base',
        candidates: ['макароны'],
        minCount: 1,
        maxCount: 1,
        isAnchor: true,
      ),
      ChefSlot(
        key: 'aromatic',
        candidates: ['чеснок'],
        minCount: 1,
        maxCount: 1,
      ),
      ChefSlot(
        key: 'finish',
        candidates: ['сыр', 'зелень', 'помидор'],
        minCount: 0,
        maxCount: 1,
      ),
    ],
  ),

  ChefBlueprint(
    id: 'chicken_shawarma_wrap',
    profile: DishProfile.skillet,
    titlePrefix: 'Шаурма домашняя',
    description:
        'Курица, быстро обжаренная до корочки, хрустящая свежая часть, '
        'холодный соус и лаваш, который запечатывается швом на сковороде. '
        'Шаурма как у профи, а не случайный рулет.',
    timeMin: 24,
    servingsBase: 2,
    tags: ['quick', 'street_food', 'generated_local'],
    anchorSlot: 'protein',
    secondaryAnchorSlot: 'wrap',
    supportSlot: 'fresh',
    preferredStarters: ['масло', 'паприка', 'чеснок', 'соль', 'перец'],
    maxImplicitPantryStarters: 5,
    titleStyle: ChefTitleStyle.anchorWithSecondary,
    stepStyle: ChefStepStyle.shawarmaWrap,
    family: ChefDishFamily.shawarmaWrap,
    slots: [
      ChefSlot(
        key: 'protein',
        candidates: ['курица'],
        minCount: 1,
        maxCount: 1,
        isAnchor: true,
      ),
      ChefSlot(
        key: 'wrap',
        candidates: ['лаваш'],
        minCount: 1,
        maxCount: 1,
      ),
      ChefSlot(
        key: 'fresh',
        candidates: ['капуста', 'огурец', 'помидор', 'лук'],
        minCount: 2,
        maxCount: 4,
      ),
      ChefSlot(
        key: 'sauce',
        candidates: ['сметана', 'йогурт'],
        minCount: 1,
        maxCount: 1,
      ),
    ],
  ),

  ChefBlueprint(
    id: 'cucumber_smetana',
    profile: DishProfile.salad,
    titlePrefix: 'Огурцы со сметаной',
    description:
        'Классический домашний салат: хрустящий огурец, сметана, укроп и соль. '
        'Никакой готовки, идеальный баланс свежести и кислинки.',
    timeMin: 5,
    servingsBase: 2,
    tags: ['quick', 'no_oven', 'minimal', 'generated_local'],
    anchorSlot: 'base',
    secondaryAnchorSlot: 'dressing',
    preferredStarters: ['соль', 'перец', 'укроп'],
    maxImplicitPantryStarters: 3,
    titleStyle: ChefTitleStyle.anchorWithSecondary,
    stepStyle: ChefStepStyle.cucumberSmetana,
    family: ChefDishFamily.cucumberSmetanaSalad,
    slots: [
      ChefSlot(
        key: 'base',
        candidates: ['огурец'],
        minCount: 1,
        maxCount: 1,
        isAnchor: true,
      ),
      ChefSlot(
        key: 'dressing',
        candidates: ['сметана', 'йогурт', 'творог'],
        minCount: 1,
        maxCount: 1,
      ),
    ],
  ),

  ChefBlueprint(
    id: 'potato_egg_hash',
    profile: DishProfile.skillet,
    titlePrefix: 'Картофельный хэш с яйцом',
    description: 'Картофель кубиком, обжаренный до корочки, с яйцом сверху. '
        'Американская классика с русским духом — сытный завтрак или ужин из двух продуктов.',
    timeMin: 20,
    servingsBase: 2,
    tags: ['quick', 'breakfast', 'one_pan', 'minimal', 'generated_local'],
    anchorSlot: 'base',
    secondaryAnchorSlot: 'protein',
    preferredStarters: ['масло', 'соль', 'перец', 'паприка', 'чеснок'],
    maxImplicitPantryStarters: 4,
    titleStyle: ChefTitleStyle.anchorWithSecondary,
    stepStyle: ChefStepStyle.potatoEggHash,
    family: ChefDishFamily.potatoEggHash,
    slots: [
      ChefSlot(
        key: 'base',
        candidates: ['картофель'],
        minCount: 1,
        maxCount: 1,
        isAnchor: true,
      ),
      ChefSlot(
        key: 'protein',
        candidates: ['яйцо'],
        minCount: 1,
        maxCount: 1,
      ),
      ChefSlot(
        key: 'addons',
        candidates: ['лук', 'перец сладкий', 'сыр'],
        minCount: 0,
        maxCount: 1,
      ),
    ],
  ),
];
