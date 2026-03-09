class PantryQuickKit {
  final String id;
  final String title;
  final String description;
  final List<String> entryIds;

  const PantryQuickKit({
    required this.id,
    required this.title,
    required this.description,
    required this.entryIds,
  });
}

const pantryQuickKits = <PantryQuickKit>[
  PantryQuickKit(
    id: 'chicken',
    title: 'Для курицы',
    description: 'Соль, перец, паприка, чеснок, масло, смесь для курицы',
    entryIds: [
      'salt',
      'black_pepper',
      'paprika',
      'garlic_dried',
      'sunflower_oil',
      'chicken_seasoning',
    ],
  ),
  PantryQuickKit(
    id: 'fish',
    title: 'Для рыбы',
    description: 'Соль, перец, укроп, лимонный сок, масло, смесь для рыбы',
    entryIds: [
      'salt',
      'black_pepper',
      'dill_dried',
      'lemon_juice',
      'olive_oil',
      'fish_seasoning',
    ],
  ),
  PantryQuickKit(
    id: 'soup',
    title: 'Для супа',
    description: 'Соль, перец, лавровый лист, укроп, томатная паста',
    entryIds: [
      'salt',
      'black_pepper',
      'bay_leaf',
      'dill_dried',
      'tomato_paste',
      'soup_seasoning',
    ],
  ),
  PantryQuickKit(
    id: 'salad',
    title: 'Для салата',
    description: 'Соль, перец, оливковое масло, лимон, горчица, йогурт',
    entryIds: [
      'salt',
      'black_pepper',
      'olive_oil',
      'lemon_juice',
      'mustard',
      'yogurt',
    ],
  ),
];
