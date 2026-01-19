import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings.dart';

final settingsProvider = StateNotifierProvider<SettingsNotifier, UserSettings>((
  ref,
) {
  return SettingsNotifier();
});

class SettingsNotifier extends StateNotifier<UserSettings> {
  static const String _storageKey = 'user_settings';

  SettingsNotifier() : super(const UserSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_storageKey);
      if (settingsJson != null) {
        state = UserSettings.fromJson(jsonDecode(settingsJson));
      }
    } catch (e) {
      // Keep default state if loading fails
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(state.toJson()));
    } catch (e) {
      // Handle error if needed
    }
  }

  void toggleSound(bool enabled) {
    state = state.copyWith(soundEnabled: enabled);
    _saveSettings();
  }

  void toggleMusic(bool enabled) {
    state = state.copyWith(musicEnabled: enabled);
    _saveSettings();
  }

  void setBotDifficulty(BotDifficulty difficulty) {
    state = state.copyWith(botDifficulty: difficulty);
    _saveSettings();
  }

  void setHomeMusic(String path) {
    state = state.copyWith(homeMusicPath: path);
    _saveSettings();
  }

  void setLobbyMusic(String path) {
    state = state.copyWith(lobbyMusicPath: path);
    _saveSettings();
  }

  void setGameMusic(String path) {
    state = state.copyWith(gameMusicPath: path);
    _saveSettings();
  }

  void setSoundVolume(double volume) {
    state = state.copyWith(soundVolume: volume);
    _saveSettings();
  }

  void setMusicVolume(double volume) {
    state = state.copyWith(musicVolume: volume);
    _saveSettings();
  }
}
