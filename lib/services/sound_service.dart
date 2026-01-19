import 'package:flame_audio/flame_audio.dart';

class SoundService {
  static const String sfxPlay = 'flipcard-91468.mp3';
  static const String sfxDraw = 'flipcard-91468.mp3';
  static const String sfxShuffle = 'riffle-card-shuffle-104313.mp3';

  // Card-specific sounds
  static const String sfxJokerGlide = 'faaaa.mp3';
  static const String sfxWin = 'other_sounds/akrobeto.mp3';
  static const String sfxLose = 'meme-groan.mp3';
  static const String sfxAce = 'metal-pipe-clang.mp3';
  static const String sfxTwo =
      'les-inconnus-vous-pouvez-repeter-la-question-.mp3';
  static const String sfxTwoOfSpades = 'flashbang-gah-dayum.mp3';
  static const String sfxSeven = 'your-phone-is-ringing-pick-it-up-now.mp3';
  static const String sfxTen = 'record-dj-scratch-sound-effect.mp3';
  static const String sfxJack = 'crickets_cJUBTZm.mp3';

  // Additional game action sounds
  static const String sfxEight =
      'other_sounds/sonido-de-spray-efecto-de-sonido.mp3';
  static const String sfxBlock = 'other_sounds/bone-crack.mp3';
  static const String sfxPenalty =
      'other_sounds/hold-up-wait-a-minute-sound-effect.mp3';
  static const String sfxLastCard = 'other_sounds/suspense-1_bLEXV6f.mp3';

  // Ludo-specific sounds
  static const String sfxDiceRoll =
      'ludo/dice-roll.mp3'; // Clack for roll result
  static const String sfxLudoRollStart =
      'ludo/dice-roll-start.mp3'; // New rolling sound
  static const String sfxLudoMove = 'flipcard-91468.mp3'; // Small clack
  static const String sfxLudoCapture = 'other_sounds/bone-crack.mp3';
  static const String sfxLudoGoal = 'other_sounds/akrobeto.mp3';
  static const String sfxLudoDoubleSix = 'faaaa.mp3';
  static const String sfxLudoBridge = 'metal-pipe-clang.mp3';

  // Awale-specific sounds
  static const String sfxAwaleSeedDrop = 'flipcard-91468.mp3'; // Seed landing
  static const String sfxAwaleCapture =
      'other_sounds/bone-crack.mp3'; // Capture
  static const String sfxAwaleWin = 'other_sounds/akrobeto.mp3'; // Victory
  static const String sfxAwaleLose = 'meme-groan.mp3'; // Defeat

  // Domino-specific sounds
  static const String sfxDominoPlay = 'flipcard-91468.mp3';
  static const String sfxDominoDraw = 'flipcard-91468.mp3';
  static const String sfxDominoShuffle = 'riffle-card-shuffle-104313.mp3';
  static const String bgmDomino = 'casino-jazz-317385.mp3';

  static bool _soundEnabled = true;
  static bool _musicEnabled = true;

  // Initialize audio cache (preload sounds)
  static Future<void> init() async {
    // Enable BGM module
    await FlameAudio.bgm.initialize();
  }

  static double _soundVolume = 1.0;
  static double _musicVolume = 1.0;

  static void updateSettings({
    required bool soundEnabled,
    required bool musicEnabled,
    double soundVolume = 1.0,
    double musicVolume = 1.0,
  }) {
    _soundEnabled = soundEnabled;
    _musicEnabled = musicEnabled;
    _soundVolume = soundVolume;
    _musicVolume = musicVolume;

    // Update BGM volume immediately if disabled
    if (!_musicEnabled) {
      FlameAudio.bgm.stop();
    } else if (FlameAudio.bgm.isPlaying) {
      // Update volume if playing
      setBGMVolume(_musicVolume);
    }
  }

  static Future<void> playBGM(String fileName, {double? volume}) async {
    if (!_musicEnabled) return;
    try {
      if (FlameAudio.bgm.isPlaying) {
        await FlameAudio.bgm.stop();
      }
      // Use provided volume override (e.g. for game screen dimming) or global setting
      final effectiveVolume = (volume ?? 1.0) * _musicVolume;
      await FlameAudio.bgm.play(fileName, volume: effectiveVolume);
    } catch (_) {}
  }

  static void setBGMVolume(double volume) {
    try {
      // Apply global music volume scaling
      FlameAudio.bgm.audioPlayer.setVolume(volume * _musicVolume);
    } catch (_) {}
  }

  static Future<void> stopBGM() async {
    try {
      await FlameAudio.bgm.stop();
    } catch (_) {}
  }

  static Future<void> playCard() async {
    if (!_soundEnabled) return;
    try {
      await FlameAudio.play(sfxPlay, volume: _soundVolume);
    } catch (_) {}
  }

  static Future<void> drawCard() async {
    if (!_soundEnabled) return;
    try {
      await FlameAudio.play(sfxDraw, volume: _soundVolume);
    } catch (_) {}
  }

  static Future<void> shuffle() async {
    if (!_soundEnabled) return;
    try {
      await FlameAudio.play(sfxShuffle, volume: _soundVolume);
    } catch (_) {}
  }

  // Card-specific sound effects
  static Future<void> playJokerGlide() async {
    if (!_soundEnabled) return;
    try {
      await FlameAudio.play(sfxJokerGlide, volume: _soundVolume);
    } catch (_) {}
  }

  static Future<void> playWin() async {
    if (!_soundEnabled) return;
    try {
      await FlameAudio.play(sfxWin, volume: _soundVolume);
    } catch (_) {}
  }

  static Future<void> playLose() async {
    if (!_soundEnabled) return;
    try {
      await FlameAudio.play(sfxLose, volume: _soundVolume);
    } catch (_) {}
  }

  static Future<void> playAce() async {
    if (!_soundEnabled) return;
    try {
      await FlameAudio.play(sfxAce, volume: _soundVolume);
    } catch (_) {}
  }

  static Future<void> playTwo() async {
    if (!_soundEnabled) return;
    try {
      await FlameAudio.play(sfxTwo, volume: _soundVolume);
    } catch (_) {}
  }

  static Future<void> playTwoOfSpades() async {
    if (!_soundEnabled) return;
    try {
      await FlameAudio.play(sfxTwoOfSpades, volume: _soundVolume);
    } catch (_) {}
  }

  static Future<void> playSeven() async {
    if (!_soundEnabled) return;
    try {
      await FlameAudio.play(sfxSeven, volume: _soundVolume);
    } catch (_) {}
  }

  static Future<void> playTen() async {
    if (!_soundEnabled) return;
    try {
      await FlameAudio.play(sfxTen, volume: _soundVolume);
    } catch (_) {}
  }

  static Future<void> playJack() async {
    if (!_soundEnabled) return;
    try {
      await FlameAudio.play(sfxJack, volume: _soundVolume);
    } catch (_) {}
  }

  static Future<void> playEight() async {
    if (!_soundEnabled) return;
    try {
      await FlameAudio.play(sfxEight, volume: _soundVolume);
    } catch (_) {}
  }

  static Future<void> playBlock() async {
    if (!_soundEnabled) return;
    try {
      await FlameAudio.play(sfxBlock, volume: _soundVolume);
    } catch (_) {}
  }

  static Future<void> playPenalty() async {
    if (!_soundEnabled) return;
    try {
      await FlameAudio.play(sfxPenalty, volume: _soundVolume);
    } catch (_) {}
  }

  static Future<void> playLastCardAlert() async {
    if (!_soundEnabled) return;
    try {
      await FlameAudio.play(sfxLastCard, volume: _soundVolume);
    } catch (_) {}
  }

  // Ludo-specific methods
  static Future<void> playDiceRoll() async {
    if (!_soundEnabled) return;
    try {
      await FlameAudio.play(sfxDiceRoll, volume: _soundVolume);
    } catch (_) {}
  }

  static Future<void> playLudoRollStart() async {
    if (!_soundEnabled) return;
    try {
      await FlameAudio.play(sfxLudoRollStart, volume: _soundVolume * 0.7);
    } catch (_) {}
  }

  static Future<void> playLudoMove() async {
    if (!_soundEnabled) return;
    try {
      await FlameAudio.play(sfxLudoMove, volume: _soundVolume * 0.8);
    } catch (_) {}
  }

  static Future<void> playLudoCapture() async {
    if (!_soundEnabled) return;
    try {
      await FlameAudio.play(sfxLudoCapture, volume: _soundVolume);
    } catch (_) {}
  }

  static Future<void> playLudoGoal() async {
    if (!_soundEnabled) return;
    try {
      await FlameAudio.play(sfxLudoGoal, volume: _soundVolume);
    } catch (_) {}
  }

  static Future<void> playLudoDoubleSix() async {
    if (!_soundEnabled) return;
    try {
      await FlameAudio.play(sfxLudoDoubleSix, volume: _soundVolume);
    } catch (_) {}
  }

  static Future<void> playLudoBridge() async {
    if (!_soundEnabled) return;
    try {
      await FlameAudio.play(sfxLudoBridge, volume: _soundVolume * 0.5);
    } catch (_) {}
  }

  // Awale-specific methods
  static Future<void> playAwaleSeedDrop() async {
    if (!_soundEnabled) return;
    try {
      await FlameAudio.play(sfxAwaleSeedDrop, volume: _soundVolume * 0.6);
    } catch (_) {}
  }

  static Future<void> playAwaleCapture() async {
    if (!_soundEnabled) return;
    try {
      await FlameAudio.play(sfxAwaleCapture, volume: _soundVolume);
    } catch (_) {}
  }

  static Future<void> playAwaleWin() async {
    if (!_soundEnabled) return;
    try {
      await FlameAudio.play(sfxAwaleWin, volume: _soundVolume);
    } catch (_) {}
  }

  static Future<void> playAwaleLose() async {
    if (!_soundEnabled) return;
    try {
      await FlameAudio.play(sfxAwaleLose, volume: _soundVolume);
    } catch (_) {}
  }

  // Domino-specific methods
  static Future<void> playDominoPlay() async {
    if (!_soundEnabled) return;
    try {
      await FlameAudio.play(sfxDominoPlay, volume: _soundVolume);
    } catch (_) {}
  }

  static Future<void> playDominoDraw() async {
    if (!_soundEnabled) return;
    try {
      await FlameAudio.play(sfxDominoDraw, volume: _soundVolume);
    } catch (_) {}
  }

  static Future<void> playDominoShuffle() async {
    if (!_soundEnabled) return;
    try {
      await FlameAudio.play(sfxDominoShuffle, volume: _soundVolume);
    } catch (_) {}
  }
}
