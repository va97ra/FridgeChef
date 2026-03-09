import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'primary_button.dart';
import 'section_surface.dart';

class EmptyStatePanel extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStatePanel({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
    this.iconColor = AppTokens.primary,
    this.iconBackground = AppTokens.primarySoft,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SectionSurface(
        tone: SectionSurfaceTone.muted,
        padding: const EdgeInsets.all(AppTokens.p24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(AppTokens.radius.xl),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: iconColor, size: 30),
            ),
            const SizedBox(height: AppTokens.p16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: AppTokens.p8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppTokens.p20),
              PrimaryButton(
                text: actionLabel!,
                onPressed: onAction!,
                variant: PrimaryButtonVariant.secondary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

