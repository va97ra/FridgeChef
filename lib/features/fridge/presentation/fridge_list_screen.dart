import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/app_scaffold.dart';
import 'providers.dart';
import 'widgets/fridge_item_card.dart';
import 'fridge_add_edit_screen.dart';
import 'package:animations/animations.dart';

class FridgeListScreen extends ConsumerWidget {
  const FridgeListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(fridgeListProvider);

    return AppScaffold(
      title: 'Мой холодильник',
      actions: [
        OpenContainer(
          closedElevation: 0,
          openElevation: 0,
          closedColor: Colors.transparent,
          openColor: Theme.of(context).scaffoldBackgroundColor,
          middleColor: Colors.transparent,
          transitionType: ContainerTransitionType.fadeThrough,
          closedBuilder: (context, action) => IconButton(
            icon: const Icon(Icons.add),
            onPressed: action,
          ),
          openBuilder: (context, action) => const FridgeAddEditScreen(),
        ),
      ],
      body: items.isEmpty
          ? const Center(
              child: Text(
                'Пока в холодильнике пусто.\nНажми + чтобы добавить продукты!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = items[index];
                return OpenContainer(
                  closedElevation: 0,
                  openElevation: 0,
                  closedColor: Colors.transparent,
                  openColor: Theme.of(context).scaffoldBackgroundColor,
                  middleColor: Colors.transparent,
                  transitionType: ContainerTransitionType.fadeThrough,
                  closedBuilder: (context, action) => FridgeItemCard(
                    item: item,
                    onTap: action,
                    onDelete: () {
                      ref.read(fridgeListProvider.notifier).removeItem(item.id);
                    },
                  ),
                  openBuilder: (context, action) =>
                      FridgeAddEditScreen(itemToEdit: item),
                );
              },
            ),
    );
  }
}
