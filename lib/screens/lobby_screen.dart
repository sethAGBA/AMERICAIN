import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../providers/game_provider.dart';
import '../widgets/suit_pattern.dart';

/// Lobby screen for creating or joining games
class LobbyScreen extends ConsumerStatefulWidget {
  final String mode; // 'create' or 'join'

  const LobbyScreen({super.key, required this.mode});

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen> {
  final _nameController = TextEditingController();
  final _gameCodeController = TextEditingController();
  String? _generatedGameCode;

  @override
  void initState() {
    super.initState();
    if (widget.mode == 'create') {
      _generatedGameCode = _generateGameCode();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _gameCodeController.dispose();
    super.dispose();
  }

  String _generateGameCode() {
    const uuid = Uuid();
    return uuid.v4().substring(0, 6).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF43A047), // Vibrant Emerald Green 600
              Color(0xFF1B5E20), // Darker Forest Green 800
            ],
          ),
        ),
        child: Stack(
          children: [
            const Positioned.fill(child: SuitPattern(opacity: 0.1)),
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
                        Text(
                          widget.mode == 'create'
                              ? 'Créer une partie'
                              : 'Rejoindre une partie',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: gameState == null
                          ? _buildLobbyForm()
                          : _buildWaitingRoom(gameState),
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

  Widget _buildLobbyForm() {
    return SingleChildScrollView(
      child: Container(
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
            const Text(
              'Entrez votre nom',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B5E20),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Votre nom',
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
                prefixIcon: const Icon(Icons.person, color: Color(0xFF43A047)),
              ),
            ),
            const SizedBox(height: 24),

            if (widget.mode == 'create') ...[
              const Text(
                'Code de la partie',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF43A047).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _generatedGameCode ?? '',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, color: Color(0xFF43A047)),
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: _generatedGameCode ?? ''),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Code copié !')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ] else ...[
              const Text(
                'Entrez le code de la partie',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _gameCodeController,
                decoration: InputDecoration(
                  hintText: 'XXXXXX',
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
                  prefixIcon: const Icon(
                    Icons.vpn_key,
                    color: Color(0xFF43A047),
                  ),
                ),
                textCapitalization: TextCapitalization.characters,
              ),
            ],

            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _handleAction,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF1B5E20),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              child: Text(
                widget.mode == 'create' ? 'Créer la partie' : 'Rejoindre',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaitingRoom(gameState) {
    final players = gameState.players;
    final isHost = gameState.hostId == ref.read(currentPlayerIdProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Text(
                'Code : ${gameState.gameId}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20),
                ),
                textAlign: TextAlign.center,
              ),
              const Text(
                'En attente de joueurs...',
                style: TextStyle(fontSize: 16, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        Expanded(
          child: ListView.builder(
            itemCount: players.length,
            itemBuilder: (context, index) {
              final player = players[index];
              final isCurrentHost = player.id == gameState.hostId;

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: Colors.white.withValues(alpha: 0.9),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF43A047),
                    child: Text(
                      player.name[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(
                    player.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing: isCurrentHost
                      ? Chip(
                          label: const Text(
                            'Hôte',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          backgroundColor: const Color(0xFF1B5E20),
                          padding: EdgeInsets.zero,
                        )
                      : null,
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 16),

        if (isHost)
          ElevatedButton(
            onPressed: players.length >= 1 ? _startGame : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: const Color(0xFF43A047),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
            child: Text(
              players.length == 1
                  ? 'Démarrer (Solo vs Bot)'
                  : 'Démarrer la partie',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'En attente que l\'hôte démarre...',
              style: TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: Color(0xFF1B5E20),
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  void _handleAction() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer votre nom')),
      );
      return;
    }

    if (widget.mode == 'create') {
      ref
          .read(gameNotifierProvider.notifier)
          .createGame(_generatedGameCode!, name);
    } else {
      final code = _gameCodeController.text.trim();
      if (code.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez entrer le code de la partie')),
        );
        return;
      }
      ref.read(gameNotifierProvider.notifier).joinGame(code, name);
    }
  }

  void _startGame() {
    ref.read(gameNotifierProvider.notifier).startGame();
    context.go('/game');
  }
}
