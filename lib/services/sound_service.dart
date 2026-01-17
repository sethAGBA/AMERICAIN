import 'package:flame_audio/flame_audio.dart';

class SoundService {
  static const String sfxPlay = 'play_card.mp3';
  static const String sfxDraw = 'draw_card.mp3';
  static const String sfxShuffle = 'shuffle.mp3';
  static const String sfxWin = 'win.mp3';

  // Initialize audio cache (preload sounds)
  static Future<void> init() async {
    // In a real app with real files, we would pre-load here
    // await FlameAudio.audioCache.loadAll([sfxPlay, sfxDraw, sfxShuffle, sfxWin]);
  }

  static Future<void> playCard() async {
    try {
      await FlameAudio.play(sfxPlay);
    } catch (_) {}
  }

  static Future<void> drawCard() async {
    try {
      await FlameAudio.play(sfxDraw);
    } catch (_) {}
  }

  static Future<void> shuffle() async {
    try {
      await FlameAudio.play(sfxShuffle);
    } catch (_) {}
  }

  static Future<void> win() async {
    try {
      await FlameAudio.play(sfxWin);
    } catch (_) {}
  }
}
