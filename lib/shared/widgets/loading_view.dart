import 'package:flutter/material.dart';

/// Vista canónica de carga con indicador circular y mensaje informativo.
class LoadingView extends StatelessWidget {
  const LoadingView({
    super.key,
    this.message = 'Cargando información...',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 38,
              height: 38,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(height: 18),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
