import 'ludo_piece.dart';

enum PlayerType { human, bot, none }

class LudoPlayer {
  final LudoColor color;
  final PlayerType type;
  final List<LudoPiece> pieces;
  final bool hasFinished;

  const LudoPlayer({
    required this.color,
    required this.type,
    required this.pieces,
    this.hasFinished = false,
  });

  factory LudoPlayer.initial(LudoColor color, PlayerType type) {
    return LudoPlayer(
      color: color,
      type: type,
      pieces: List.generate(
        4,
        (index) => LudoPiece(id: '${color.name}_$index', color: color),
      ),
    );
  }

  LudoPlayer copyWith({List<LudoPiece>? pieces, bool? hasFinished}) {
    return LudoPlayer(
      color: color,
      type: type,
      pieces: pieces ?? this.pieces,
      hasFinished: hasFinished ?? this.hasFinished,
    );
  }

  Map<String, dynamic> toJson() => {
    'color': color.index,
    'type': type.index,
    'pieces': pieces.map((p) => p.toJson()).toList(),
    'hasFinished': hasFinished,
  };

  factory LudoPlayer.fromJson(Map<String, dynamic> json) => LudoPlayer(
    color: LudoColor.values[json['color']],
    type: PlayerType.values[json['type']],
    pieces: (json['pieces'] as List).map((p) => LudoPiece.fromJson(p)).toList(),
    hasFinished: json['hasFinished'] ?? false,
  );
}
