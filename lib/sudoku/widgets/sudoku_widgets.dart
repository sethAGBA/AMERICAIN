import 'package:flutter/material.dart';
import '../models/sudoku_models.dart';

class SudokuBoard extends StatelessWidget {
  final List<List<SudokuCell>> board;
  final int? selectedRow;
  final int? selectedCol;
  final Function(int, int) onCellTap;

  const SudokuBoard({
    super.key,
    required this.board,
    this.selectedRow,
    this.selectedCol,
    required this.onCellTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: AspectRatio(
        aspectRatio: 1,
        child: Column(children: List.generate(9, (r) => _buildRow(r))),
      ),
    );
  }

  Widget _buildRow(int r) {
    return Expanded(
      child: Row(children: List.generate(9, (c) => _buildCell(r, c))),
    );
  }

  Widget _buildCell(int r, int c) {
    final cell = board[r][c];
    final isSelected = selectedRow == r && selectedCol == c;

    // Highlight logic
    bool isInSelectedRow = selectedRow == r;
    bool isInSelectedCol = selectedCol == c;
    bool isInSelectedBox =
        (selectedRow != null && selectedCol != null) &&
        (r ~/ 3 == selectedRow! ~/ 3 && c ~/ 3 == selectedCol! ~/ 3);

    // Highlight related cells
    Color? backgroundColor;
    if (isSelected) {
      backgroundColor = Colors.blue.withValues(alpha: 0.3);
    } else if (isInSelectedRow || isInSelectedCol || isInSelectedBox) {
      backgroundColor = Colors.blue.withValues(alpha: 0.1);
    }

    // Border logic for 3x3 blocks
    final borderRight = (c == 2 || c == 5) ? 2.0 : 0.5;
    final borderBottom = (r == 2 || r == 5) ? 2.0 : 0.5;

    return Expanded(
      child: GestureDetector(
        onTap: () => onCellTap(r, c),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border(
              right: BorderSide(color: Colors.black, width: borderRight),
              bottom: BorderSide(color: Colors.black, width: borderBottom),
            ),
          ),
          child: Center(
            child: cell.value != null
                ? Text(
                    '${cell.value}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: cell.isPreFilled
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: cell.isPreFilled ? Colors.black : Colors.blue[800],
                    ),
                  )
                : _buildNotes(cell.notes),
          ),
        ),
      ),
    );
  }

  Widget _buildNotes(Set<int> notes) {
    if (notes.isEmpty) return const SizedBox();
    return GridView.count(
      crossAxisCount: 3,
      padding: const EdgeInsets.all(2),
      physics: const NeverScrollableScrollPhysics(),
      children: List.generate(9, (index) {
        final number = index + 1;
        return Center(
          child: Text(
            notes.contains(number) ? '$number' : '',
            style: const TextStyle(fontSize: 8, color: Colors.grey),
          ),
        );
      }),
    );
  }
}

class SudokuNumberPad extends StatelessWidget {
  final Function(int) onNumberTap;
  final VoidCallback onErase;
  final bool isNotesMode;
  final VoidCallback onToggleNotes;

  const SudokuNumberPad({
    super.key,
    required this.onNumberTap,
    required this.onErase,
    required this.isNotesMode,
    required this.onToggleNotes,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(5, (i) => _buildNumberButton(i + 1)),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ...List.generate(4, (i) => _buildNumberButton(i + 6)),
            _buildSpecialButton(
              onErase,
              const Icon(Icons.backspace_outlined, color: Colors.red),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildNoteToggleButton(),
      ],
    );
  }

  Widget _buildNumberButton(int n) {
    return SizedBox(
      width: 50,
      height: 50,
      child: ElevatedButton(
        onPressed: () => onNumberTap(n),
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: Colors.white,
          foregroundColor: Colors.blue[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 2,
        ),
        child: Text(
          '$n',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildSpecialButton(VoidCallback onTap, Widget icon) {
    return SizedBox(
      width: 50,
      height: 50,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 2,
        ),
        child: icon,
      ),
    );
  }

  Widget _buildNoteToggleButton() {
    return SizedBox(
      width: 200,
      child: ElevatedButton.icon(
        onPressed: onToggleNotes,
        icon: Icon(isNotesMode ? Icons.edit_note : Icons.edit_outlined),
        label: Text(isNotesMode ? 'NOTES : ON' : 'NOTES : OFF'),
        style: ElevatedButton.styleFrom(
          backgroundColor: isNotesMode ? Colors.orange : Colors.white24,
          foregroundColor: Colors.white,
          shape: StadiumBorder(),
        ),
      ),
    );
  }
}
