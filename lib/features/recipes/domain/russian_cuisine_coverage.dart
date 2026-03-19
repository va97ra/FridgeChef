enum RussianCuisineCoverageStatus {
  covered,
  extractFamily,
  missing,
  blockedByCatalog,
}

class RussianCuisineCoverageEntry {
  final String id;
  final String title;
  final RussianCuisineCoverageStatus status;
  final String? blueprintId;
  final String familyId;
  final String continuationNote;

  const RussianCuisineCoverageEntry({
    required this.id,
    required this.title,
    required this.status,
    required this.familyId,
    required this.continuationNote,
    this.blueprintId,
  });
}

// Source of truth for Russian cuisine roadmap. If a future agent runs out of
// context, continue from the first entry whose status is not `covered`.
const russianCuisineCoverage = <RussianCuisineCoverageEntry>[
  RussianCuisineCoverageEntry(
    id: 'olivier',
    title: 'Оливье',
    status: RussianCuisineCoverageStatus.covered,
    blueprintId: 'olivier',
    familyId: 'olivierSalad',
    continuationNote: 'Covered with dedicated salad validator and tests.',
  ),
  RussianCuisineCoverageEntry(
    id: 'vinegret',
    title: 'Винегрет',
    status: RussianCuisineCoverageStatus.covered,
    blueprintId: 'vinegret',
    familyId: 'vinegretSalad',
    continuationNote: 'Covered with dedicated salad validator and tests.',
  ),
  RussianCuisineCoverageEntry(
    id: 'shchi',
    title: 'Щи',
    status: RussianCuisineCoverageStatus.covered,
    blueprintId: 'shchi',
    familyId: 'cabbageSoup',
    continuationNote: 'Covered as classic cabbage soup family.',
  ),
  RussianCuisineCoverageEntry(
    id: 'borscht',
    title: 'Борщ',
    status: RussianCuisineCoverageStatus.covered,
    blueprintId: 'borscht',
    familyId: 'borschtSoup',
    continuationNote: 'Covered as beet-and-cabbage soup family.',
  ),
  RussianCuisineCoverageEntry(
    id: 'ukha',
    title: 'Уха',
    status: RussianCuisineCoverageStatus.covered,
    blueprintId: 'ukha',
    familyId: 'fishSoup',
    continuationNote: 'Covered as clean fish soup family.',
  ),
  RussianCuisineCoverageEntry(
    id: 'rassolnik',
    title: 'Рассольник',
    status: RussianCuisineCoverageStatus.covered,
    blueprintId: 'rassolnik',
    familyId: 'pickleSoup',
    continuationNote: 'Covered as pearl barley and pickle soup family.',
  ),
  RussianCuisineCoverageEntry(
    id: 'okroshka_kefir',
    title: 'Окрошка на кефире',
    status: RussianCuisineCoverageStatus.covered,
    blueprintId: 'okroshka_kefir',
    familyId: 'okroshkaColdSoup',
    continuationNote: 'Covered as dedicated cold soup family.',
  ),
  RussianCuisineCoverageEntry(
    id: 'okroshka_kvass',
    title: 'Окрошка на квасе',
    status: RussianCuisineCoverageStatus.covered,
    blueprintId: 'okroshka_kvass',
    familyId: 'okroshkaKvassColdSoup',
    continuationNote: 'Covered as dedicated cold soup family.',
  ),
  RussianCuisineCoverageEntry(
    id: 'solyanka',
    title: 'Солянка',
    status: RussianCuisineCoverageStatus.covered,
    blueprintId: 'solyanka',
    familyId: 'solyankaSoup',
    continuationNote: 'Covered as bright salty-sour soup family.',
  ),
  RussianCuisineCoverageEntry(
    id: 'green_shchi_sorrel',
    title: 'Щавелевые щи',
    status: RussianCuisineCoverageStatus.covered,
    blueprintId: 'green_shchi_sorrel',
    familyId: 'greenShchiSorrelSoup',
    continuationNote:
        'Implemented in this batch as separate hot sorrel soup family.',
  ),
  RussianCuisineCoverageEntry(
    id: 'svekolnik',
    title: 'Свекольник',
    status: RussianCuisineCoverageStatus.covered,
    blueprintId: 'svekolnik',
    familyId: 'svekolnikColdSoup',
    continuationNote:
        'Implemented in this batch as separate cold beet soup family.',
  ),
  RussianCuisineCoverageEntry(
    id: 'makarony_po_flotski',
    title: 'Макароны по-флотски',
    status: RussianCuisineCoverageStatus.covered,
    blueprintId: 'makarony_po_flotski',
    familyId: 'navyPasta',
    continuationNote: 'Covered as dedicated pasta family.',
  ),
  RussianCuisineCoverageEntry(
    id: 'grechka_rustic',
    title: 'Гречка по-домашнему',
    status: RussianCuisineCoverageStatus.covered,
    blueprintId: 'grechka_rustic',
    familyId: 'buckwheatRusticBowl',
    continuationNote:
        'Extracted from generic grain bowl into its own family in this batch.',
  ),
  RussianCuisineCoverageEntry(
    id: 'tvorozhnaya_zapekanka',
    title: 'Творожная запеканка',
    status: RussianCuisineCoverageStatus.covered,
    blueprintId: 'tvorozhnaya_zapekanka',
    familyId: 'curdBake',
    continuationNote: 'Covered as dedicated curd bake family.',
  ),
  RussianCuisineCoverageEntry(
    id: 'cabbage_egg_pie',
    title: 'Пирог с капустой и яйцом',
    status: RussianCuisineCoverageStatus.covered,
    blueprintId: 'cabbage_egg_pie',
    familyId: 'savoryClosedPie',
    continuationNote: 'Covered as closed savory pie family.',
  ),
  RussianCuisineCoverageEntry(
    id: 'blini',
    title: 'Блины',
    status: RussianCuisineCoverageStatus.covered,
    blueprintId: 'blini',
    familyId: 'bliniPan',
    continuationNote: 'Covered as thin pan batter family.',
  ),
  RussianCuisineCoverageEntry(
    id: 'oladyi',
    title: 'Оладьи',
    status: RussianCuisineCoverageStatus.covered,
    blueprintId: 'oladyi',
    familyId: 'oladyiFritter',
    continuationNote: 'Covered as thick kefir fritter family.',
  ),
  RussianCuisineCoverageEntry(
    id: 'syrniki',
    title: 'Сырники',
    status: RussianCuisineCoverageStatus.covered,
    blueprintId: 'syrniki',
    familyId: 'curdFritter',
    continuationNote: 'Covered as curd fritter family.',
  ),
  RussianCuisineCoverageEntry(
    id: 'draniki',
    title: 'Драники',
    status: RussianCuisineCoverageStatus.covered,
    blueprintId: 'draniki',
    familyId: 'potatoFritter',
    continuationNote: 'Covered as grated potato fritter family.',
  ),
  RussianCuisineCoverageEntry(
    id: 'millet_kasha',
    title: 'Пшенная каша',
    status: RussianCuisineCoverageStatus.covered,
    blueprintId: 'millet_kasha',
    familyId: 'porridge',
    continuationNote: 'Covered within porridge family.',
  ),
  RussianCuisineCoverageEntry(
    id: 'rice_kasha',
    title: 'Рисовая каша',
    status: RussianCuisineCoverageStatus.covered,
    blueprintId: 'rice_kasha',
    familyId: 'porridge',
    continuationNote:
        'Covered within porridge family with explicit blueprint mapping.',
  ),
  RussianCuisineCoverageEntry(
    id: 'manna_kasha',
    title: 'Манная каша',
    status: RussianCuisineCoverageStatus.covered,
    blueprintId: 'manna_kasha',
    familyId: 'porridge',
    continuationNote: 'Covered within porridge family.',
  ),
  RussianCuisineCoverageEntry(
    id: 'lazy_cabbage_rolls',
    title: 'Ленивые голубцы',
    status: RussianCuisineCoverageStatus.covered,
    blueprintId: 'lazy_cabbage_rolls',
    familyId: 'lazyCabbageRollStew',
    continuationNote: 'Covered as dedicated lazy cabbage roll family.',
  ),
  RussianCuisineCoverageEntry(
    id: 'tefteli',
    title: 'Тефтели',
    status: RussianCuisineCoverageStatus.covered,
    blueprintId: 'tefteli',
    familyId: 'tefteliSauceStew',
    continuationNote: 'Covered as sauce-bound meatball family.',
  ),
  RussianCuisineCoverageEntry(
    id: 'kotlet_dinner',
    title: 'Котлеты по-домашнему',
    status: RussianCuisineCoverageStatus.covered,
    blueprintId: 'kotlet_dinner',
    familyId: 'homeCutletDinner',
    continuationNote: 'Covered as cutlet-plus-garnish family.',
  ),
  RussianCuisineCoverageEntry(
    id: 'zrazy',
    title: 'Зразы',
    status: RussianCuisineCoverageStatus.covered,
    blueprintId: 'zrazy',
    familyId: 'zrazyStuffedCutlets',
    continuationNote: 'Covered as stuffed cutlet family.',
  ),
  RussianCuisineCoverageEntry(
    id: 'bitochki',
    title: 'Биточки',
    status: RussianCuisineCoverageStatus.covered,
    blueprintId: 'bitochki',
    familyId: 'bitochkiGravyCutlets',
    continuationNote: 'Covered as gravy cutlet family.',
  ),
  RussianCuisineCoverageEntry(
    id: 'zharkoe',
    title: 'Жаркое',
    status: RussianCuisineCoverageStatus.covered,
    blueprintId: 'zharkoe',
    familyId: 'zharkoeStew',
    continuationNote: 'Covered as potato-and-meat braise family.',
  ),
  RussianCuisineCoverageEntry(
    id: 'goulash',
    title: 'Гуляш',
    status: RussianCuisineCoverageStatus.covered,
    blueprintId: 'goulash',
    familyId: 'goulashSauceStew',
    continuationNote: 'Covered as paprika-tomato gravy family.',
  ),
  RussianCuisineCoverageEntry(
    id: 'beef_stroganoff',
    title: 'Бефстроганов',
    status: RussianCuisineCoverageStatus.covered,
    blueprintId: 'beef_stroganoff',
    familyId: 'stroganoffSauceStew',
    continuationNote: 'Covered as sour-cream beef family.',
  ),
  RussianCuisineCoverageEntry(
    id: 'stewed_cabbage',
    title: 'Тушеная капуста',
    status: RussianCuisineCoverageStatus.covered,
    blueprintId: 'stewed_cabbage',
    familyId: 'stewedCabbageStew',
    continuationNote:
        'Extracted from generic stew into its own family in this batch.',
  ),
  RussianCuisineCoverageEntry(
    id: 'classic_golubtsy',
    title: 'Классические голубцы',
    status: RussianCuisineCoverageStatus.covered,
    blueprintId: 'classic_golubtsy',
    familyId: 'classicGolubtsy',
    continuationNote:
        'Implemented as wrapped cabbage-roll family with dedicated braise, validator, and comparison tests.',
  ),
  RussianCuisineCoverageEntry(
    id: 'mushroom_soup',
    title: 'Грибной суп',
    status: RussianCuisineCoverageStatus.covered,
    blueprintId: 'mushroom_soup',
    familyId: 'mushroomSoup',
    continuationNote:
        'Implemented as its own mushroom-broth family with aromatic saute, dedicated validation, and anti-collapse tests against generic soup.',
  ),
  RussianCuisineCoverageEntry(
    id: 'pea_smoked_soup',
    title: 'Гороховый суп с копченостями',
    status: RussianCuisineCoverageStatus.covered,
    blueprintId: 'pea_smoked_soup',
    familyId: 'peaSmokedSoup',
    continuationNote: 'Covered as dedicated pea-and-smoked-meat soup family.',
  ),
  RussianCuisineCoverageEntry(
    id: 'pelmeni',
    title: 'Пельмени',
    status: RussianCuisineCoverageStatus.blockedByCatalog,
    familyId: 'pelmeni',
    continuationNote:
        'Requires dough-focused product expansion and dumpling-specific generation before implementation.',
  ),
  RussianCuisineCoverageEntry(
    id: 'vareniki',
    title: 'Вареники',
    status: RussianCuisineCoverageStatus.blockedByCatalog,
    familyId: 'vareniki',
    continuationNote:
        'Requires dough-focused product expansion and sweet/savory filling disambiguation.',
  ),
  RussianCuisineCoverageEntry(
    id: 'pirozhki',
    title: 'Пирожки',
    status: RussianCuisineCoverageStatus.blockedByCatalog,
    familyId: 'pirozhki',
    continuationNote:
        'Needs dough, yeast, shaping, and fry-vs-bake reasoning before implementation.',
  ),
  RussianCuisineCoverageEntry(
    id: 'kulebyaka_fish_pie',
    title: 'Кулебяка',
    status: RussianCuisineCoverageStatus.blockedByCatalog,
    familyId: 'kulebyakaFishPie',
    continuationNote:
        'Needs fish pie layering model and dough expansion before implementation.',
  ),
  RussianCuisineCoverageEntry(
    id: 'shuba',
    title: 'Селедка под шубой',
    status: RussianCuisineCoverageStatus.blockedByCatalog,
    familyId: 'shuba',
    continuationNote:
        'Needs herring product expansion and layered mayo salad reasoning.',
  ),
  RussianCuisineCoverageEntry(
    id: 'mimosa',
    title: 'Мимоза',
    status: RussianCuisineCoverageStatus.blockedByCatalog,
    familyId: 'mimosa',
    continuationNote:
        'Needs canned fish expansion and layered holiday salad reasoning.',
  ),
  RussianCuisineCoverageEntry(
    id: 'crab_salad',
    title: 'Крабовый салат',
    status: RussianCuisineCoverageStatus.blockedByCatalog,
    familyId: 'crabSalad',
    continuationNote:
        'Needs crab-stick product expansion and salad disambiguation.',
  ),
  RussianCuisineCoverageEntry(
    id: 'holodets',
    title: 'Холодец',
    status: RussianCuisineCoverageStatus.blockedByCatalog,
    familyId: 'holodets',
    continuationNote:
        'Needs collagen-rich cuts in catalog and dedicated gelled-dish reasoning.',
  ),
  RussianCuisineCoverageEntry(
    id: 'liver_fritters',
    title: 'Печеночные оладьи',
    status: RussianCuisineCoverageStatus.covered,
    blueprintId: 'liver_fritters',
    familyId: 'liverFritters',
    continuationNote:
        'Covered as a dedicated liver-and-onion skillet fritter family with separate blending and frying checks.',
  ),
  RussianCuisineCoverageEntry(
    id: 'liver_cake',
    title: 'Печеночный торт',
    status: RussianCuisineCoverageStatus.covered,
    blueprintId: 'liver_cake',
    familyId: 'liverCake',
    continuationNote:
        'Covered as a layered cold appetizer family with separate liver-batter, assembly, and chilling logic.',
  ),
  RussianCuisineCoverageEntry(
    id: 'charlotte',
    title: 'Шарлотка',
    status: RussianCuisineCoverageStatus.covered,
    blueprintId: 'charlotte',
    familyId: 'charlotte',
    continuationNote:
        'Covered as a dedicated apple charlotte family with airy batter, apple-layer assembly, validator, and rule-scoring checks.',
  ),
  RussianCuisineCoverageEntry(
    id: 'medovik',
    title: 'Медовик',
    status: RussianCuisineCoverageStatus.blockedByCatalog,
    familyId: 'medovik',
    continuationNote:
        'Needs honey expansion and layered cake reasoning before implementation.',
  ),
  RussianCuisineCoverageEntry(
    id: 'napoleon',
    title: 'Наполеон',
    status: RussianCuisineCoverageStatus.blockedByCatalog,
    familyId: 'napoleon',
    continuationNote:
        'Needs puff pastry expansion and custard/layer reasoning before implementation.',
  ),
  RussianCuisineCoverageEntry(
    id: 'mors',
    title: 'Морс',
    status: RussianCuisineCoverageStatus.covered,
    blueprintId: 'mors',
    familyId: 'mors',
    continuationNote:
        'Covered as a dedicated berry drink family with juice-first extraction, strained base, chilling, and anti-compote drift checks.',
  ),
  RussianCuisineCoverageEntry(
    id: 'kissel',
    title: 'Кисель',
    status: RussianCuisineCoverageStatus.blockedByCatalog,
    familyId: 'kissel',
    continuationNote:
        'Berry drink layer exists, but kissel still needs starch-thickened drink-dessert reasoning.',
  ),
  RussianCuisineCoverageEntry(
    id: 'bread_kvass',
    title: 'Хлебный квас',
    status: RussianCuisineCoverageStatus.blockedByCatalog,
    familyId: 'breadKvass',
    continuationNote:
        'Requires rye bread fermentation modeling before implementation.',
  ),
  RussianCuisineCoverageEntry(
    id: 'sauerkraut_preserve',
    title: 'Квашеная капуста',
    status: RussianCuisineCoverageStatus.covered,
    blueprintId: 'sauerkraut_preserve',
    familyId: 'sauerkrautPreserve',
    continuationNote:
        'Covered as a dedicated cabbage preserve family with salting, pressing, fermentation wait, and anti-salad drift checks.',
  ),
  RussianCuisineCoverageEntry(
    id: 'lightly_salted_cucumbers',
    title: 'Малосольные огурцы',
    status: RussianCuisineCoverageStatus.covered,
    blueprintId: 'lightly_salted_cucumbers',
    familyId: 'lightlySaltedCucumbers',
    continuationNote:
        'Covered as a dedicated cucumber preserve family with dill-garlic brine, short room-temperature cure, chilling, and anti-salad drift checks.',
  ),
  RussianCuisineCoverageEntry(
    id: 'berry_jam',
    title: 'Варенье',
    status: RussianCuisineCoverageStatus.blockedByCatalog,
    familyId: 'berryJam',
    continuationNote:
        'Preserve-family modeling exists; now blocked by berry product expansion.',
  ),
];
