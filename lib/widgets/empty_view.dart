import 'package:flutter/material.dart';

class EmptyView extends StatelessWidget {
  const EmptyView({super.key, required String message});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Aucune musique trouvée'),
    );
  }
}
