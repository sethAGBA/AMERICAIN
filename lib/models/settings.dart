import 'package:equatable/equatable.dart';

enum BotDifficulty {
  easy,
  normal,
  hard;

  String get label {
    switch (this) {
      case BotDifficulty.easy:
        return 'Facile';
      case BotDifficulty.normal:
        return 'Normal';
      case BotDifficulty.hard:
        return 'Difficile';
    }
  }
}

class MusicTrack extends Equatable {
  final String path;
  final String label;

  const MusicTrack({required this.path, required this.label});

  @override
  List<Object?> get props => [path, label];
}

const List<MusicTrack> availableTracks = [
  MusicTrack(path: 'casino-164235.mp3', label: 'Casino Lounge'),
  MusicTrack(path: 'casino-jazz-317385.mp3', label: 'Jazz Smooth'),
  MusicTrack(
    path:
        'casino-music-jazz-las-vegas-monaco-background-intro-theme-294408.mp3',
    label: 'Vegas Intro',
  ),
  MusicTrack(path: 'casino-roulettes-405725.mp3', label: 'Roulette Chill'),
  MusicTrack(
    path: 'las-vegas-las-vegas-casino-music-385955.mp3',
    label: 'Las Vegas Night',
  ),
];

class UserSettings extends Equatable {
  final bool soundEnabled;
  final bool musicEnabled;
  final BotDifficulty botDifficulty;
  final String homeMusicPath;
  final String lobbyMusicPath;
  final String gameMusicPath;
  final double soundVolume;
  final double musicVolume;

  const UserSettings({
    this.soundEnabled = true,
    this.musicEnabled = true,
    this.botDifficulty = BotDifficulty.normal,
    this.homeMusicPath =
        'casino-music-jazz-las-vegas-monaco-background-intro-theme-294408.mp3',
    this.lobbyMusicPath = 'casino-jazz-317385.mp3',
    this.gameMusicPath = 'casino-roulettes-405725.mp3',
    this.soundVolume = 1.0,
    this.musicVolume = 1.0,
  });

  UserSettings copyWith({
    bool? soundEnabled,
    bool? musicEnabled,
    BotDifficulty? botDifficulty,
    String? homeMusicPath,
    String? lobbyMusicPath,
    String? gameMusicPath,
    double? soundVolume,
    double? musicVolume,
  }) {
    return UserSettings(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      musicEnabled: musicEnabled ?? this.musicEnabled,
      botDifficulty: botDifficulty ?? this.botDifficulty,
      homeMusicPath: homeMusicPath ?? this.homeMusicPath,
      lobbyMusicPath: lobbyMusicPath ?? this.lobbyMusicPath,
      gameMusicPath: gameMusicPath ?? this.gameMusicPath,
      soundVolume: soundVolume ?? this.soundVolume,
      musicVolume: musicVolume ?? this.musicVolume,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'soundEnabled': soundEnabled,
      'musicEnabled': musicEnabled,
      'botDifficulty': botDifficulty.name,
      'homeMusicPath': homeMusicPath,
      'lobbyMusicPath': lobbyMusicPath,
      'gameMusicPath': gameMusicPath,
      'soundVolume': soundVolume,
      'musicVolume': musicVolume,
    };
  }

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      soundEnabled: json['soundEnabled'] as bool? ?? true,
      musicEnabled: json['musicEnabled'] as bool? ?? true,
      botDifficulty: BotDifficulty.values.firstWhere(
        (e) => e.name == json['botDifficulty'],
        orElse: () => BotDifficulty.normal,
      ),
      homeMusicPath:
          json['homeMusicPath'] as String? ?? availableTracks[2].path,
      lobbyMusicPath:
          json['lobbyMusicPath'] as String? ?? availableTracks[1].path,
      gameMusicPath:
          json['gameMusicPath'] as String? ?? availableTracks[3].path,
      soundVolume: (json['soundVolume'] as num?)?.toDouble() ?? 1.0,
      musicVolume: (json['musicVolume'] as num?)?.toDouble() ?? 1.0,
    );
  }

  @override
  List<Object?> get props => [
    soundEnabled,
    musicEnabled,
    botDifficulty,
    homeMusicPath,
    lobbyMusicPath,
    gameMusicPath,
    soundVolume,
    musicVolume,
  ];
}
