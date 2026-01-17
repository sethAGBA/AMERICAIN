import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../models/game_state.dart';
import '../models/card.dart';

/// Service for WebSocket communication with game server
class SocketService {
  io.Socket? _socket;
  String? _currentGameId;

  // Callbacks for game events
  Function(GameState)? onGameUpdate;
  Function(String playerName)? onPlayerJoined;
  Function(String playerName)? onPlayerLeft;
  Function(String message)? onError;

  /// Connect to the game server
  void connect(String serverUrl) {
    _socket = io.io(
      serverUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    _setupListeners();
    _socket!.connect();
  }

  /// Set up event listeners
  void _setupListeners() {
    _socket?.on('connect', (_) {
      debugPrint('Connected to game server');
    });

    _socket?.on('disconnect', (_) {
      debugPrint('Disconnected from game server');
    });

    _socket?.on('gameUpdate', (data) {
      try {
        final gameState = GameState.fromJson(data as Map<String, dynamic>);
        onGameUpdate?.call(gameState);
      } catch (e) {
        debugPrint('Error parsing game update: $e');
        onError?.call('Failed to update game state');
      }
    });

    _socket?.on('playerJoined', (data) {
      final playerName = data['playerName'] as String;
      onPlayerJoined?.call(playerName);
    });

    _socket?.on('playerLeft', (data) {
      final playerName = data['playerName'] as String;
      onPlayerLeft?.call(playerName);
    });

    _socket?.on('error', (data) {
      final message = data['message'] as String? ?? 'Unknown error';
      onError?.call(message);
    });

    _socket?.on('connect_error', (error) {
      debugPrint('Connection error: $error');
      onError?.call('Failed to connect to server');
    });
  }

  /// Create a new game
  void createGame(String gameId, String playerId, String playerName) {
    _currentGameId = gameId;
    _socket?.emit('createGame', {
      'gameId': gameId,
      'playerId': playerId,
      'playerName': playerName,
    });
  }

  /// Join an existing game
  void joinGame(String gameId, String playerId, String playerName) {
    _currentGameId = gameId;
    _socket?.emit('joinGame', {
      'gameId': gameId,
      'playerId': playerId,
      'playerName': playerName,
    });
  }

  /// Start the game (host only)
  void startGame() {
    if (_currentGameId == null) return;
    _socket?.emit('startGame', {'gameId': _currentGameId});
  }

  /// Play a card
  void playCard(String playerId, PlayingCard card, {Suit? chosenSuit}) {
    if (_currentGameId == null) return;
    _socket?.emit('playCard', {
      'gameId': _currentGameId,
      'playerId': playerId,
      'card': card.toJson(),
      'chosenSuit': chosenSuit?.name,
    });
  }

  /// Draw a card from the deck
  void drawCard(String playerId) {
    if (_currentGameId == null) return;
    _socket?.emit('drawCard', {'gameId': _currentGameId, 'playerId': playerId});
  }

  /// Leave the current game
  void leaveGame(String playerId) {
    if (_currentGameId == null) return;
    _socket?.emit('leaveGame', {
      'gameId': _currentGameId,
      'playerId': playerId,
    });
    _currentGameId = null;
  }

  /// Send a chat message
  void sendMessage(String playerId, String message) {
    if (_currentGameId == null) return;
    _socket?.emit('chatMessage', {
      'gameId': _currentGameId,
      'playerId': playerId,
      'message': message,
    });
  }

  /// Disconnect from the server
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _currentGameId = null;
  }

  /// Check if connected
  bool get isConnected => _socket?.connected ?? false;

  /// Get current game ID
  String? get currentGameId => _currentGameId;
}
