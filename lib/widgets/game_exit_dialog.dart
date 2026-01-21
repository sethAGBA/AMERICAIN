import 'package:flutter/material.dart';

class GameExitDialog extends StatelessWidget {
  final String title;
  final String content;
  final VoidCallback onConfirm;
  final Color backgroundColor;

  /// Standard exit dialog matching the Chifoumi design.
  ///
  /// [title] defaults to 'Quitter la partie ?'
  /// [content] description text asking for confirmation.
  /// [onConfirm] callback when user clicks 'QUITTER'.
  /// [backgroundColor] background color of the dialog, defaults to deep purple (0xFF311B92).
  const GameExitDialog({
    super.key,
    this.title = 'Quitter la partie ?',
    required this.content,
    required this.onConfirm,
    this.backgroundColor = const Color(0xFF311B92),
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Text(content, style: const TextStyle(color: Colors.white70)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('ANNULER', style: TextStyle(color: Colors.white)),
        ),
        ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF5252),
            foregroundColor: Colors.white,
          ),
          child: const Text('QUITTER'),
        ),
      ],
    );
  }
}
