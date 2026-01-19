enum LudoColor { red, green, yellow, blue }

extension LudoColorX on LudoColor {
  String get frenchName {
    switch (this) {
      case LudoColor.red:
        return 'ROUGE';
      case LudoColor.green:
        return 'VERT';
      case LudoColor.yellow:
        return 'JAUNE';
      case LudoColor.blue:
        return 'BLEU';
    }
  }
}

enum PieceState {
  home, // In the starting area (base)
  inJail, // Captured by opponent
  track, // On the main board
  goalStretch, // In the colored home stretch
  goal, // Finished
}

class LudoPiece {
  final String id;
  final LudoColor color;
  final PieceState state;
  final int? capturedBy; // Player index who captured this piece (if inJail)
  final int position; // 0-51 on main track, 0-5 in goal stretch
  final bool hasCaptured; // Track if piece captured this turn

  const LudoPiece({
    required this.id,
    required this.color,
    this.state = PieceState.home,
    this.position = 0,
    this.capturedBy,
    this.hasCaptured = false,
  });

  LudoPiece copyWith({
    String? id,
    LudoColor? color,
    PieceState? state,
    int? position,
    int? capturedBy, // Corrected type to int?
    bool? hasCaptured,
  }) {
    return LudoPiece(
      id: id ?? this.id,
      color: color ?? this.color,
      state: state ?? this.state,
      position: position ?? this.position,
      capturedBy: capturedBy ?? this.capturedBy,
      hasCaptured: hasCaptured ?? this.hasCaptured,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'color': color.index,
    'state': state.index,
    'position': position,
    'capturedBy': capturedBy,
    'hasCaptured': hasCaptured,
  };

  factory LudoPiece.fromJson(Map<String, dynamic> json) => LudoPiece(
    id: json['id'],
    color: LudoColor.values[json['color']],
    state: PieceState.values[json['state']],
    position: json['position'],
    capturedBy: json['capturedBy'],
    hasCaptured: json['hasCaptured'] ?? false,
  );
}
