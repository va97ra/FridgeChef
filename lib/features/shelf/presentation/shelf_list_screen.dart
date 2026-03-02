import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_scaffold.dart';
import 'providers.dart';
import 'widgets/shelf_item_chip.dart';
import 'shelf_add_edit_screen.dart';

class ShelfListScreen extends ConsumerWidget {
  const ShelfListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(shelfListProvider);

    return AppScaffold(
      title: 'Полка',
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ShelfAddEditScreen()),
            );
          },
        ),
      ],
      body: items.isEmpty
          ? const Center(
              child: Text(
                'Специи не добавлены.\nНажми + чтобы добавить.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    'Отметьте, что у вас сейчас есть:',
                    style: TextStyle(color: AppTokens.textLight),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: items.map((item) {
                      return ShelfItemChip(
                        item: item,
                        onToggle: () {
                          ref.read(shelfListProvider.notifier).toggleItem(item);
                        },
                        onLongPress: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    ShelfAddEditScreen(itemToEdit: item)),
                          );
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
    );
  }
}
