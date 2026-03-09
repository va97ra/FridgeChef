import 'package:flutter/material.dart';

Future<String?> showRenameRecipeDialog(
  BuildContext context, {
  required String initialTitle,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) {
      return _RenameRecipeDialog(initialTitle: initialTitle);
    },
  );
}

class _RenameRecipeDialog extends StatefulWidget {
  final String initialTitle;

  const _RenameRecipeDialog({
    required this.initialTitle,
  });

  @override
  State<_RenameRecipeDialog> createState() => _RenameRecipeDialogState();
}

class _RenameRecipeDialogState extends State<_RenameRecipeDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialTitle);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Переименовать рецепт'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'Новое название',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}
