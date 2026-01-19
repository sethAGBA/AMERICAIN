import 'package:equatable/equatable.dart';

/// Represents a single move in an Awale game
class AwaleMove extends Equatable {
  final String playerId;
  final int pitIndex; // 0-11, the pit that was selected
  final int seedsDistributed; // Number of seeds that were distributed
  final int seedsCaptured; // Number of seeds captured in this move
  final List<int> capturedFromPits; // Which pits were captured from
  final DateTime timestamp;

  const AwaleMove({
    required this.playerId,
    required this.pitIndex,
    required this.seedsDistributed,
    this.seedsCaptured = 0,
    this.capturedFromPits = const [],
    required this.timestamp,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'playerId': playerId,
      'pitIndex': pitIndex,
      'seedsDistributed': seedsDistributed,
      'seedsCaptured': seedsCaptured,
      'capturedFromPits': capturedFromPits,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Create from JSON
  factory AwaleMove.fromJson(Map<String, dynamic> json) {
    return AwaleMove(
      playerId: json['playerId'] as String,
      pitIndex: json['pitIndex'] as int,
      seedsDistributed: json['seedsDistributed'] as int,
      seedsCaptured: json['seedsCaptured'] as int? ?? 0,
      capturedFromPits:
          (json['capturedFromPits'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  @override
  List<Object?> get props => [
    playerId,
    pitIndex,
    seedsDistributed,
    seedsCaptured,
    capturedFromPits,
    timestamp,
  ];
}
