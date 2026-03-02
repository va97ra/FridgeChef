import 'package:flutter/material.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/units.dart';
import '../domain/fridge_item.dart';

class FridgeItemCard extends StatelessWidget {
  final FridgeItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const FridgeItemCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    bool isExpired = false;
    if (item.expiresAt != null) {
      isExpired = item.expiresAt!
          .isBefore(DateTime.now().subtract(const Duration(days: 1)));
    }

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.r16),
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.p16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTokens.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTokens.r12),
                ),
                child: const Center(
                  child: Icon(Icons.fastfood, color: AppTokens.primary),
                ),
              ),
              const SizedBox(width: AppTokens.p16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.amount.toStringAsFixed(item.amount.truncateToDouble() == item.amount ? 0 : 1)} ${item.unit.label}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTokens.textLight,
                          ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    icon:
                        const Icon(Icons.delete_outline, color: AppTokens.warn),
                    onPressed: onDelete,
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                  if (item.expiresAt != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      Formatters.formatDate(item.expiresAt!),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isExpired
                                ? AppTokens.warn
                                : AppTokens.textLight,
                            fontWeight: isExpired ? FontWeight.bold : null,
                          ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
