import 'package:equatable/equatable.dart';

class GameStats extends Equatable {
  final String gameId;
  final int wins;
  final int losses;

  const GameStats({required this.gameId, this.wins = 0, this.losses = 0});

  GameStats copyWith({String? gameId, int? wins, int? losses}) {
    return GameStats(
      gameId: gameId ?? this.gameId,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
    );
  }

  Map<String, dynamic> toJson() {
    return {'gameId': gameId, 'wins': wins, 'losses': losses};
  }

  factory GameStats.fromJson(Map<String, dynamic> json) {
    return GameStats(
      gameId: json['gameId'] as String,
      wins: json['wins'] as int? ?? 0,
      losses: json['losses'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [gameId, wins, losses];
}
