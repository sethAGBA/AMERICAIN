class DominoPiece {
  final int sideA;
  final int sideB;

  const DominoPiece(this.sideA, this.sideB);

  bool contains(int value) => sideA == value || sideB == value;

  int otherSide(int value) {
    if (sideA == value) return sideB;
    if (sideB == value) return sideA;
    throw Exception('Value $value not found in piece $this');
  }

  bool get isDouble => sideA == sideB;

  int get score => sideA + sideB;

  @override
  String toString() => '[$sideA|$sideB]';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DominoPiece &&
          ((sideA == other.sideA && sideB == other.sideB) ||
              (sideA == other.sideB && sideB == other.sideA));

  @override
  int get hashCode => sideA.hashCode ^ sideB.hashCode;

  static List<DominoPiece> generateSet() {
    List<DominoPiece> set = [];
    for (int i = 0; i <= 6; i++) {
      for (int j = i; j <= 6; j++) {
        set.add(DominoPiece(i, j));
      }
    }
    return set;
  }
}
