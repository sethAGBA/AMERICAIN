import 'package:flutter/material.dart';

class PenduKeyboard extends StatelessWidget {
  final Set<String> guessedLetters;
  final Function(String) onLetterPressed;

  const PenduKeyboard({
    super.key,
    required this.guessedLetters,
    required this.onLetterPressed,
  });

  @override
  Widget build(BuildContext context) {
    const letters = [
      'A',
      'B',
      'C',
      'D',
      'E',
      'F',
      'G',
      'H',
      'I',
      'J',
      'K',
      'L',
      'M',
      'N',
      'O',
      'P',
      'Q',
      'R',
      'S',
      'T',
      'U',
      'V',
      'W',
      'X',
      'Y',
      'Z',
    ];

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: letters.map((letter) {
        final isUsed = guessedLetters.contains(letter);
        return SizedBox(
          width: 40,
          height: 40,
          child: ElevatedButton(
            onPressed: isUsed ? null : () => onLetterPressed(letter),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.zero,
              backgroundColor: Colors.white,
              disabledBackgroundColor: Colors.white24,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              letter,
              style: TextStyle(
                color: isUsed ? Colors.white38 : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
