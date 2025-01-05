import 'package:flutter/material.dart';

class EmptyView extends StatelessWidget {
  final String message;
  final IconData? icon;
  final VoidCallback? onActionPressed;
  final String? actionLabel;

  const EmptyView({
    super.key,
    required this.message,
    this.icon = Icons.music_off,
    this.onActionPressed,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutBack,
            builder: (context, double value, child) {
              return Transform.scale(
                scale: value,
                child: child,
              );
            },
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 24),
          TweenAnimationBuilder(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOut,
            builder: (context, double value, child) {
              return Opacity(
                opacity: value,
                child: child,
              );
            },
            child: Column(
              children: [
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                ),
                if (actionLabel != null && onActionPressed != null) ...[
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: onActionPressed,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    icon: const Icon(Icons.refresh),
                    label: Text(actionLabel!),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Conseil: Pensez à enrichir votre collection ou à sélectionner des titres en favoris',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.color
                      ?.withOpacity(0.7),
                ),
          ),
        ],
      ),
    );
  }
}
