import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../providers/awale_provider.dart';
import '../models/awale_game_state.dart';
import '../../providers/settings_provider.dart';
import '../../services/sound_service.dart';
import '../../widgets/generic_pattern.dart';

/// Lobby screen for Awale game setup
class AwaleLobbyScreen extends ConsumerStatefulWidget {
  const AwaleLobbyScreen({super.key});

  @override
  ConsumerState<AwaleLobbyScreen> createState() => _AwaleLobbyScreenState();
}

class _AwaleLobbyScreenState extends ConsumerState<AwaleLobbyScreen> {
  final _nameController = TextEditingController();
  String _selectedMode = 'bot'; // 'bot' or 'local' or 'online'
  String _selectedDifficulty = 'medium'; // 'easy', 'medium', 'hard'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _playMusic();
    });
  }

  void _playMusic() {
    final settings = ref.read(settingsProvider);
    SoundService.playBGM(settings.lobbyMusicPath);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to music path changes
    ref.listen(settingsProvider.select((s) => s.lobbyMusicPath), (
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
              Color(0xFF8D6E63), // Light brown
              Color(0xFF5D4037), // Medium brown
            ],
          ),
        ),
        child: Stack(
          children: [
            const Positioned.fill(
              child: GenericPattern(
                type: PatternType.circles,
                opacity: 0.1,
                crossAxisCount: 6,
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: () => context.pop(),
                        ),
                        const Text(
                          'Awale',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: _buildSetupForm(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetupForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Game title
          const Text(
            '🌰 Awale',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF5D4037),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Jeu de stratégie traditionnel africain',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Player name
          const Text(
            'Votre nom',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF5D4037),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'Entrez votre nom',
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              prefixIcon: const Icon(Icons.person, color: Color(0xFF8D6E63)),
            ),
          ),
          const SizedBox(height: 24),

          // Game mode selection
          const Text(
            'Mode de jeu',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF5D4037),
            ),
          ),
          const SizedBox(height: 12),
          _buildModeOption(
            'bot',
            'Contre l\'ordinateur',
            Icons.smart_toy,
            'Jouez contre l\'IA',
          ),
          const SizedBox(height: 8),
          _buildModeOption(
            'local',
            'Local (2 joueurs)',
            Icons.people,
            'Passez l\'appareil entre joueurs',
          ),
          const SizedBox(height: 8),
          _buildModeOption(
            'online',
            'En ligne',
            Icons.wifi,
            'Jouez en ligne (bientôt disponible)',
            enabled: false,
          ),

          // Difficulty selection (only for bot mode)
          if (_selectedMode == 'bot') ...[
            const SizedBox(height: 24),
            const Text(
              'Difficulté',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5D4037),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDifficultyChip('easy', 'Facile', Colors.green),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDifficultyChip('medium', 'Moyen', Colors.orange),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDifficultyChip('hard', 'Difficile', Colors.red),
                ),
              ],
            ),
          ],

          const SizedBox(height: 32),

          // Start button
          ElevatedButton(
            onPressed: _startGame,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: const Color(0xFF5D4037),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
            child: const Text(
              'Commencer',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeOption(
    String value,
    String title,
    IconData icon,
    String subtitle, {
    bool enabled = true,
  }) {
    final isSelected = _selectedMode == value;

    return GestureDetector(
      onTap: enabled
          ? () {
              setState(() {
                _selectedMode = value;
              });
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF8D6E63).withValues(alpha: 0.2)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF8D6E63) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: enabled
                  ? (isSelected
                        ? const Color(0xFF5D4037)
                        : Colors.grey.shade600)
                  : Colors.grey.shade400,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: enabled
                          ? (isSelected
                                ? const Color(0xFF5D4037)
                                : Colors.black87)
                          : Colors.grey.shade400,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: enabled
                          ? Colors.grey.shade600
                          : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFF5D4037)),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyChip(String value, String label, Color color) {
    final isSelected = _selectedDifficulty == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDifficulty = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  void _startGame() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer votre nom')),
      );
      return;
    }

    if (_selectedMode == 'online') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mode en ligne bientôt disponible')),
      );
      return;
    }

    // Generate game ID
    const uuid = Uuid();
    final gameId = uuid.v4();
    final playerId = uuid.v4();

    // Create game
    ref
        .read(awaleGameStateProvider.notifier)
        .createGame(
          gameId: gameId,
          playerName: name,
          playerId: playerId,
          vsBot: _selectedMode == 'bot',
          mode: _selectedMode == 'local' ? GameMode.local : GameMode.online,
        );

    // Start game
    ref.read(awaleGameStateProvider.notifier).startGame();

    // Navigate to game screen
    context.go('/awale-game');
  }
}
