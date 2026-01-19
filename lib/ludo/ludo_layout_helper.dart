import 'dart:ui'; // For Offset
import 'models/ludo_piece.dart'; // For PieceState

class LudoLayoutHelper {
  // Map logical track position (0-51) to Grid Coordinate (x, y) where 0,0 is top-left
  // Grid size is 15x15.
  // Hardcoded map for all 52 positions
  static const List<Offset> _mainTrackOffsets = [
    // Red Sector (0-12)
    Offset(1, 6), Offset(2, 6), Offset(3, 6), Offset(4, 6), Offset(5, 6),
    Offset(6, 5),
    Offset(6, 4),
    Offset(6, 3),
    Offset(6, 2),
    Offset(6, 1),
    Offset(6, 0),
    Offset(7, 0), Offset(8, 0),

    // Green Sector (13-25)
    Offset(8, 1), Offset(8, 2), Offset(8, 3), Offset(8, 4), Offset(8, 5),
    Offset(9, 6),
    Offset(10, 6),
    Offset(11, 6),
    Offset(12, 6),
    Offset(13, 6),
    Offset(14, 6),
    Offset(14, 7), Offset(14, 8),

    // Yellow Sector (26-38)
    Offset(13, 8), Offset(12, 8), Offset(11, 8), Offset(10, 8), Offset(9, 8),
    Offset(8, 9),
    Offset(8, 10),
    Offset(8, 11),
    Offset(8, 12),
    Offset(8, 13),
    Offset(8, 14),
    Offset(7, 14), Offset(6, 14),

    // Blue Sector (39-51)
    Offset(6, 13), Offset(6, 12), Offset(6, 11), Offset(6, 10), Offset(6, 9),
    Offset(5, 8),
    Offset(4, 8),
    Offset(3, 8),
    Offset(2, 8),
    Offset(1, 8),
    Offset(0, 8),
    Offset(0, 7), Offset(0, 6),
  ];

  static Offset getCoordinates(LudoPiece piece) {
    if (piece.state == PieceState.inJail) {
      return _getJailCoordinates(piece);
    }
    if (piece.state == PieceState.home) {
      return _getHomeCoordinates(piece);
    }
    if (piece.state == PieceState.goal) {
      // Center triangle based on color
      switch (piece.color) {
        case LudoColor.red:
          return const Offset(6, 6); // Approx center edge?
        case LudoColor.green:
          return const Offset(8, 6);
        case LudoColor.yellow:
          return const Offset(8, 8);
        case LudoColor.blue:
          return const Offset(6, 8);
      }
    }
    if (piece.state == PieceState.goalStretch) {
      return _getGoalStretchCoordinates(piece);
    }

    // Main Track
    // Position 0-51
    return _mainTrackOffsets[piece.position % 52];
  }

  static Offset _getHomeCoordinates(LudoPiece piece) {
    // 4 positions inside the 6x6 base
    // Red Base (0,0)
    double basePathX = 0;
    double basePathY = 0;

    switch (piece.color) {
      case LudoColor.red:
        basePathX = 0;
        basePathY = 0;
        break;
      case LudoColor.green:
        basePathX = 9;
        basePathY = 0;
        break;
      case LudoColor.yellow:
        basePathX = 9;
        basePathY = 9;
        break;
      case LudoColor.blue:
        basePathX = 0;
        basePathY = 9;
        break;
    }

    // Inner square starts at +1, +1 relative to base, size 4x4.
    // Pieces arranged in 2x2 grid inside inner square (which is at x+1, y+1)
    // Piece 0: 1.5, 1.5 relative to base?
    // Let's place them at 1.5, 1.5 | 3.5, 1.5 etc
    // Indices usually 0-3 based on piece ID suffix
    String suffix = piece.id.split('_').last;
    int index = int.tryParse(suffix) ?? 0;

    double offsetX = (index % 2 == 0) ? 1.5 : 3.5;
    double offsetY = (index < 2) ? 1.5 : 3.5;

    return Offset(basePathX + offsetX, basePathY + offsetY);
  }

  static Offset _getGoalStretchCoordinates(LudoPiece piece) {
    // Indices 0-4 (5 steps towards center)
    // Red: (1,7) -> (5,7)
    // Green: (7,1) -> (7,5)
    // Yellow: (13,7) -> (9,7)
    // Blue: (7,13) -> (7,9)

    int index = piece.position; // 0 is first step in

    switch (piece.color) {
      case LudoColor.red:
        return Offset(1.0 + index, 7.0);
      case LudoColor.green:
        return Offset(7.0, 1.0 + index);
      case LudoColor.yellow:
        return Offset(13.0 - index, 7.0);
      case LudoColor.blue:
        return Offset(7.0, 13.0 - index);
    }
  }

  static Offset _getJailCoordinates(LudoPiece piece) {
    if (piece.capturedBy == null) return _getHomeCoordinates(piece);

    final capturerColor = LudoColor.values[piece.capturedBy!];

    double baseX = 0;
    double baseY = 0;

    switch (capturerColor) {
      case LudoColor.red:
        baseX = 0;
        baseY = 0;
        break;
      case LudoColor.green:
        baseX = 9;
        baseY = 0;
        break;
      case LudoColor.yellow:
        baseX = 9;
        baseY = 9;
        break;
      case LudoColor.blue:
        baseX = 0;
        baseY = 9;
        break;
    }

    // Nestling logic: Place captured pieces in the gaps between the owner's pieces.
    // Owner pieces are at (1.5, 1.5), (4.5, 1.5), (1.5, 4.5), (4.5, 4.5).
    // Available Gaps:
    // G1: (3.0, 1.5) - Top Mid
    // G2: (3.0, 4.5) - Bottom Mid
    // G3: (1.5, 3.0) - Left Mid
    // G4: (4.5, 3.0) - Right Mid
    // G5: (3.0, 3.0) - Center

    String suffix = piece.id.split('_').last;
    int pieceIdx = int.tryParse(suffix) ?? 0;
    // Combinatory index to avoid same-suffix collisions if multiple colors jailed
    int slot = (piece.color.index * 4 + pieceIdx) % 5;

    double offsetX = 3.0; // Default Center
    double offsetY = 3.0;

    switch (capturerColor) {
      case LudoColor
          .red: // Top-Left. Inward gaps: Right-Mid (G4) and Bottom-Mid (G2).
        if (slot == 0) {
          offsetX = 4.5;
          offsetY = 3.0;
        } // G4
        else if (slot == 1) {
          offsetX = 3.0;
          offsetY = 4.5;
        } // G2
        else if (slot == 2) {
          offsetX = 3.0;
          offsetY = 3.0;
        } // G5
        else if (slot == 3) {
          offsetX = 4.0;
          offsetY = 4.0;
        } // Near-Center
        else {
          offsetX = 2.0;
          offsetY = 2.0;
        } // Near-Center
        break;
      case LudoColor
          .green: // Top-Right. Inward gaps: Left-Mid (G3) and Bottom-Mid (G2).
        if (slot == 0) {
          offsetX = 1.5;
          offsetY = 3.0;
        } // G3
        else if (slot == 1) {
          offsetX = 3.0;
          offsetY = 4.5;
        } // G2
        else if (slot == 2) {
          offsetX = 3.0;
          offsetY = 3.0;
        } // G5
        else if (slot == 3) {
          offsetX = 2.0;
          offsetY = 4.0;
        } else {
          offsetX = 4.0;
          offsetY = 2.0;
        }
        break;
      case LudoColor
          .yellow: // Bottom-Right. Inward gaps: Left-Mid (G3) and Top-Mid (G1).
        if (slot == 0) {
          offsetX = 1.5;
          offsetY = 3.0;
        } // G3
        else if (slot == 1) {
          offsetX = 3.0;
          offsetY = 1.5;
        } // G1
        else if (slot == 2) {
          offsetX = 3.0;
          offsetY = 3.0;
        } // G5
        else if (slot == 3) {
          offsetX = 2.0;
          offsetY = 2.0;
        } else {
          offsetX = 4.0;
          offsetY = 4.0;
        }
        break;
      case LudoColor
          .blue: // Bottom-Left. Inward gaps: Right-Mid (G4) and Top-Mid (G1).
        if (slot == 0) {
          offsetX = 4.5;
          offsetY = 3.0;
        } // G4
        else if (slot == 1) {
          offsetX = 3.0;
          offsetY = 1.5;
        } // G1
        else if (slot == 2) {
          offsetX = 3.0;
          offsetY = 3.0;
        } // G5
        else if (slot == 3) {
          offsetX = 4.0;
          offsetY = 2.0;
        } else {
          offsetX = 2.0;
          offsetY = 4.0;
        }
        break;
    }

    return Offset(baseX + offsetX, baseY + offsetY);
  }

  static Offset getTrackPosition(int index) => _mainTrackOffsets[index % 52];
}
