import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// Базовый скаффолд приложения с градиентным фоном и декоративными пятнами.
class AppScaffold extends StatelessWidget {
  final Widget body;
  final String? title;
  final Widget? floatingActionButton;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;

  const AppScaffold({
    super.key,
    required this.body,
    this.title,
    this.floatingActionButton,
    this.actions,
    this.leading,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: title != null ? _buildAppBar(context) : null,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Фоновый градиент
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppTokens.bgGradient,
            ),
          ),

          // Декоративный блоб — верхний правый
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTokens.primary.withValues(alpha: 0.35),
              ),
            ),
          ),

          // Декоративный блоб — нижний левый
          Positioned(
            bottom: -50,
            left: MediaQuery.of(context).size.width * -0.2,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTokens.secondary.withValues(alpha: 0.25),
              ),
            ),
          ),

          // Размытие (Mesh Gradient)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: const SizedBox(),
            ),
          ),

          // Основной контент
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTokens.p16),
              child: body,
            ),
          ),
        ],
      ),
      floatingActionButton: floatingActionButton,
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(title!),
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      actions: actions,
      leading:
          showBackButton && Navigator.canPop(context) ? _BackButton() : leading,
    );
  }
}

class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.maybePop(context),
      child: Container(
        margin: const EdgeInsets.only(left: 12),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppTokens.surface.withValues(alpha: 0.85),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Icon(Icons.arrow_back_ios_new, size: 16),
      ),
    );
  }
}
