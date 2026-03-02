import 'package:flutter/material.dart';
import '../../theme/tokens.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const GlassCard({super.key, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTokens.surface.withOpacity(0.9),
          borderRadius: BorderRadius.circular(AppTokens.r16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(AppTokens.p16),
        child: child,
      ),
    );
  }
}
