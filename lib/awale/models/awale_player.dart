import 'package:equatable/equatable.dart';

/// Represents a player in an Awale game
class AwalePlayer extends Equatable {
  final String id;
  final String name;
  final bool isBot;
  final PlayerSide side; // Which side of the board (top or bottom)

  const AwalePlayer({
    required this.id,
    required this.name,
    this.isBot = false,
    required this.side,
  });

  /// Create a copy with updated fields
  AwalePlayer copyWith({
    String? id,
    String? name,
    bool? isBot,
    PlayerSide? side,
  }) {
    return AwalePlayer(
      id: id ?? this.id,
      name: name ?? this.name,
      isBot: isBot ?? this.isBot,
      side: side ?? this.side,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'isBot': isBot, 'side': side.name};
  }

  /// Create from JSON
  factory AwalePlayer.fromJson(Map<String, dynamic> json) {
    return AwalePlayer(
      id: json['id'] as String,
      name: json['name'] as String,
      isBot: json['isBot'] as bool? ?? false,
      side: PlayerSide.values.firstWhere(
        (e) => e.name == json['side'],
        orElse: () => PlayerSide.bottom,
      ),
    );
  }

  @override
  List<Object?> get props => [id, name, isBot, side];
}

/// Enum for player side on the board
enum PlayerSide {
  top, // Pits 0-5 (opponent's side when viewing from bottom)
  bottom, // Pits 6-11 (player's side when viewing from bottom)
}
