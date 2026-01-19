import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/morpion_provider.dart';
import '../models/morpion_state.dart';
import '../../widgets/generic_pattern.dart';

class MorpionLobbyScreen extends ConsumerStatefulWidget {
  const MorpionLobbyScreen({super.key});

  @override
  ConsumerState<MorpionLobbyScreen> createState() => _MorpionLobbyScreenState();
}

class _MorpionLobbyScreenState extends ConsumerState<MorpionLobbyScreen> {
  bool _vsBot = true;
  MorpionSymbol _humanSymbol = MorpionSymbol.x;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFBA68C8),
              Color(0xFF7B1FA2),
            ], // Purple theme for Morpion
          ),
        ),
        child: Stack(
          children: [
            const Positioned.fill(
              child: GenericPattern(
                type: PatternType.board,
                opacity: 0.05,
                crossAxisCount: 8,
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: () => context.pop(),
                        ),
                        const Spacer(),
                        const Text(
                          'MORPION',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(width: 48),
                      ],
                    ),
                    const Spacer(),
                    const Text(
                      'CHOISISSEZ VOTRE MODE',
                      style: TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildModeButton(
                      title: 'SOLO',
                      subtitle: 'Contre l\'ordinateur',
                      icon: Icons.computer,
                      isActive: _vsBot,
                      onTap: () => setState(() => _vsBot = true),
                    ),
                    const SizedBox(height: 16),
                    _buildModeButton(
                      title: 'MULTIJOUEUR',
                      subtitle: '2 joueurs en local',
                      icon: Icons.people,
                      isActive: !_vsBot,
                      onTap: () => setState(() => _vsBot = false),
                    ),
                    const SizedBox(height: 40),
                    const Text(
                      'VOTRE SYMBOLE',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildSymbolOption(MorpionSymbol.x),
                        const SizedBox(width: 24),
                        _buildSymbolOption(MorpionSymbol.o),
                      ],
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          ref
                              .read(morpionProvider.notifier)
                              .setupGame(
                                vsBot: _vsBot,
                                humanSymbol: _humanSymbol,
                              );
                          context.push('/morpion/game');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD700),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'JOUER',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.white.withOpacity(0.2)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? const Color(0xFFFFD700) : Colors.white24,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isActive ? const Color(0xFFFFD700) : Colors.white70,
              size: 32,
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white60, fontSize: 13),
                ),
              ],
            ),
            const Spacer(),
            if (isActive)
              const Icon(Icons.check_circle, color: Color(0xFFFFD700)),
          ],
        ),
      ),
    );
  }

  Widget _buildSymbolOption(MorpionSymbol symbol) {
    bool isSelected = _humanSymbol == symbol;
    String label = symbol == MorpionSymbol.x ? 'X' : 'O';

    return GestureDetector(
      onTap: () => setState(() => _humanSymbol = symbol),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFD700) : Colors.white10,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white24,
            width: isSelected ? 3 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
