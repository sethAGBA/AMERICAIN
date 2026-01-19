import 'package:flutter_test/flutter_test.dart';
import 'package:jeu_8_americain/models/settings.dart';
import 'package:jeu_8_americain/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  group('SettingsProvider', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Loads default settings on initialization', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final settings = container.read(settingsProvider);
      expect(settings.soundEnabled, true);
      expect(settings.musicEnabled, true);
      expect(settings.botDifficulty, BotDifficulty.normal);
    });

    test('Updates and persists settings', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(settingsProvider.notifier);

      notifier.toggleSound(false);
      notifier.setBotDifficulty(BotDifficulty.hard);

      final settings = container.read(settingsProvider);
      expect(settings.soundEnabled, false);
      expect(settings.botDifficulty, BotDifficulty.hard);

      // Reload to verify persistence (shared_preferences mock)
      final prefs = await SharedPreferences.getInstance();
      final storedJson = prefs.getString('user_settings');
      expect(storedJson, contains('"soundEnabled":false'));
      expect(storedJson, contains('"botDifficulty":"hard"'));
    });
  });
}
