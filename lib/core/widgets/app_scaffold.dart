import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'app_icon_button.dart';

class AppScaffold extends StatelessWidget {
  static const _countertopTextureAsset = 'assets/images/countertop_texture.png';

  final Widget body;
  final String? title;
  final Widget? floatingActionButton;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;
  final EdgeInsetsGeometry bodyPadding;

  const AppScaffold({
    super.key,
    required this.body,
    this.title,
    this.floatingActionButton,
    this.actions,
    this.leading,
    this.showBackButton = true,
    this.bodyPadding = const EdgeInsets.symmetric(horizontal: AppTokens.p20),
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.colors.background,
      appBar: title != null ? _buildAppBar(context) : null,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(_countertopTextureAsset),
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            opacity: 0.9,
            filterQuality: FilterQuality.high,
          ),
        ),
        child: Container(
          color: const Color(0x18FFFFFF),
          child: SafeArea(
            top: title == null,
            bottom: false,
            child: Padding(
              padding: bodyPadding,
              child: body,
            ),
          ),
        ),
      ),
      floatingActionButton: floatingActionButton,
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(title!),
      backgroundColor: AppTokens.colors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleSpacing: 8,
      toolbarHeight: 68,
      actions: actions,
      leadingWidth: 64,
      leading: showBackButton && Navigator.canPop(context)
          ? const Padding(
              padding: EdgeInsets.only(left: 20),
              child: _BackButton(),
            )
          : leading,
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    return AppIconButton(
      icon: Icons.arrow_back_rounded,
      onPressed: () => Navigator.maybePop(context),
      tooltip: 'Назад',
    );
  }
}
