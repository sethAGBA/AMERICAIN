/// Awale game rules and constants
class AwaleRules {
  // Board configuration
  static const int totalPits = 12;
  static const int pitsPerPlayer = 6;
  static const int initialSeedsPerPit = 4;
  static const int totalSeeds = totalPits * initialSeedsPerPit; // 48

  // Capture rules
  static const int minCaptureSeeds = 2;
  static const int maxCaptureSeeds = 3;

  // Win condition
  static const int seedsToWin = (totalSeeds ~/ 2) + 1; // 25 seeds

  // Pit indices
  static const List<int> topRowPits = [0, 1, 2, 3, 4, 5];
  static const List<int> bottomRowPits = [6, 7, 8, 9, 10, 11];

  /// Check if a pit index is on the top row
  static bool isTopRow(int pitIndex) {
    return pitIndex >= 0 && pitIndex <= 5;
  }

  /// Check if a pit index is on the bottom row
  static bool isBottomRow(int pitIndex) {
    return pitIndex >= 6 && pitIndex <= 11;
  }

  /// Get the opponent's pit indices for a given pit index
  static List<int> getOpponentPits(int pitIndex) {
    return isTopRow(pitIndex) ? bottomRowPits : topRowPits;
  }

  /// Get the player's own pit indices for a given pit index
  static List<int> getOwnPits(int pitIndex) {
    return isTopRow(pitIndex) ? topRowPits : bottomRowPits;
  }

  /// Check if seeds can be captured (2 or 3 seeds)
  static bool canCapture(int seedCount) {
    return seedCount == minCaptureSeeds || seedCount == maxCaptureSeeds;
  }
}
