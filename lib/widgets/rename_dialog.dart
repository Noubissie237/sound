import 'package:flutter/material.dart';

class RenameDialog extends StatelessWidget {
  final String initialTitle;
  final _controller = TextEditingController();

  RenameDialog({super.key, required this.initialTitle}) {
    _controller.text = initialTitle;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Renommer'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          labelText: 'Nouveau nom',
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Renommer'),
        ),
      ],
    );
  }
}


