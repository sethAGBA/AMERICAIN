import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../services/sound_service.dart';
import '../models/settings.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _playMusic();
    });
  }

  void _playMusic() {
    final settings = ref.read(settingsProvider);
    SoundService.playBGM(settings.homeMusicPath);
  }

  @override
  Widget build(BuildContext context) {
    final currentSettings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    // Also listen to music path changes
    ref.listen(settingsProvider.select((s) => s.homeMusicPath), (
      previous,
      next,
    ) {
      if (next != previous) {
        SoundService.playBGM(next);
      }
    });

    // Listen to music enabled status
    ref.listen(settingsProvider.select((s) => s.musicEnabled), (
      previous,
      next,
    ) {
      if (next == true && (previous == false || previous == null)) {
        _playMusic();
      } else if (next == false) {
        SoundService.stopBGM();
      }
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF37474F), // Blue Grey 800
              Color(0xFF263238), // Blue Grey 900
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Paramètres',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Personnalisez votre expérience sonore',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: ListView(
                    children: [
                      _buildSectionTitle('AUDIO'),
                      _buildSettingCard(
                        child: Column(
                          children: [
                            SwitchListTile(
                              title: const Text(
                                'Effets sonores',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              secondary: Icon(
                                currentSettings.soundEnabled
                                    ? Icons.volume_up
                                    : Icons.volume_off,
                                color: Colors.orangeAccent,
                              ),
                              value: currentSettings.soundEnabled,
                              activeColor: Colors.orangeAccent,
                              onChanged: (value) => notifier.toggleSound(value),
                            ),
                            if (currentSettings.soundEnabled)
                              _buildVolumeSlider(
                                value: currentSettings.soundVolume,
                                icon: Icons.volume_down,
                                onChanged: (value) {
                                  notifier.setSoundVolume(value);
                                  SoundService.updateSettings(
                                    soundEnabled: currentSettings.soundEnabled,
                                    musicEnabled: currentSettings.musicEnabled,
                                    soundVolume: value,
                                    musicVolume: currentSettings.musicVolume,
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSettingCard(
                        child: Column(
                          children: [
                            SwitchListTile(
                              title: const Text(
                                'Musique d\'ambiance',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              secondary: Icon(
                                currentSettings.musicEnabled
                                    ? Icons.music_note
                                    : Icons.music_off,
                                color: Colors.blueAccent,
                              ),
                              value: currentSettings.musicEnabled,
                              activeColor: Colors.blueAccent,
                              onChanged: (value) => notifier.toggleMusic(value),
                            ),
                            if (currentSettings.musicEnabled)
                              _buildVolumeSlider(
                                value: currentSettings.musicVolume,
                                icon: Icons.audiotrack,
                                color: Colors.blueAccent,
                                onChanged: (value) {
                                  notifier.setMusicVolume(value);
                                  SoundService.updateSettings(
                                    soundEnabled: currentSettings.soundEnabled,
                                    musicEnabled: currentSettings.musicEnabled,
                                    soundVolume: currentSettings.soundVolume,
                                    musicVolume: value,
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildSectionTitle('MUSIQUES DÉDIÉES'),
                      _buildSettingCard(
                        child: Column(
                          children: [
                            _buildMusicDropdown(
                              context,
                              label: 'Accueil',
                              value: currentSettings.homeMusicPath,
                              onChanged: (path) => notifier.setHomeMusic(path!),
                            ),
                            const Divider(color: Colors.white24, height: 32),
                            _buildMusicDropdown(
                              context,
                              label: 'Salon (Lobby)',
                              value: currentSettings.lobbyMusicPath,
                              onChanged: (path) =>
                                  notifier.setLobbyMusic(path!),
                            ),
                            const Divider(color: Colors.white24, height: 32),
                            _buildMusicDropdown(
                              context,
                              label: 'En Jeu',
                              value: currentSettings.gameMusicPath,
                              onChanged: (path) => notifier.setGameMusic(path!),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildSectionTitle('IA & DIFFICULTÉ'),
                      _buildSettingCard(
                        child: _buildDifficultyDropdown(
                          currentSettings.botDifficulty,
                          (value) {
                            if (value != null) notifier.setBotDifficulty(value);
                          },
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white60,
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildSettingCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: child,
    );
  }

  Widget _buildVolumeSlider({
    required double value,
    required IconData icon,
    required ValueChanged<double> onChanged,
    Color color = Colors.orangeAccent,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.white60),
          Expanded(
            child: Slider(
              value: value,
              min: 0.0,
              max: 1.0,
              activeColor: color,
              inactiveColor: color.withOpacity(0.2),
              onChanged: onChanged,
            ),
          ),
          Text(
            '${(value * 100).toInt()}%',
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMusicDropdown(
    BuildContext context, {
    required String label,
    required String value,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Theme(
            data: Theme.of(
              context,
            ).copyWith(canvasColor: const Color(0xFF37474F)),
            child: DropdownButtonFormField<String>(
              value: value,
              dropdownColor: const Color(0xFF37474F),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: availableTracks.map((track) {
                return DropdownMenuItem(
                  value: track.path,
                  child: Text(
                    track.label,
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyDropdown(
    BotDifficulty current,
    ValueChanged<BotDifficulty?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Difficulté des bots',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<BotDifficulty>(
            value: current,
            dropdownColor: const Color(0xFF37474F),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            items: BotDifficulty.values.map((difficulty) {
              return DropdownMenuItem(
                value: difficulty,
                child: Text(
                  difficulty.label,
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
