import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/domino_piece.dart';
import '../../services/sound_service.dart';

enum DominoStatus { lobby, playing, finished }

class DominoPlayer {
  final String id;
  final String name;
  final List<DominoPiece> hand;
  final bool isBot;

  DominoPlayer({
    required this.id,
    required this.name,
    required this.hand,
    this.isBot = false,
  });

  DominoPlayer copyWith({List<DominoPiece>? hand}) {
    return DominoPlayer(
      id: id,
      name: name,
      hand: hand ?? List.from(this.hand),
      isBot: isBot,
    );
  }
}

class DominoState {
  final List<DominoPlayer> players;
  final List<DominoPiece> board;
  final List<DominoPiece> deck;
  final int currentTurn;
  final DominoStatus status;
  final String? winnerId;
  final int? leftValue;
  final int? rightValue;
  final String? lastMessage;
  final bool isHandoverInProgress;

  DominoState({
    required this.players,
    required this.board,
    required this.deck,
    required this.currentTurn,
    required this.status,
    this.winnerId,
    this.leftValue,
    this.rightValue,
    this.lastMessage,
    this.isHandoverInProgress = false,
  });

  DominoState copyWith({
    List<DominoPlayer>? players,
    List<DominoPiece>? board,
    List<DominoPiece>? deck,
    int? currentTurn,
    DominoStatus? status,
    String? winnerId,
    int? leftValue,
    int? rightValue,
    String? lastMessage,
    bool? isHandoverInProgress,
  }) {
    return DominoState(
      players: players ?? this.players,
      board: board ?? this.board,
      deck: deck ?? this.deck,
      currentTurn: currentTurn ?? this.currentTurn,
      status: status ?? this.status,
      winnerId: winnerId ?? this.winnerId,
      leftValue: leftValue ?? this.leftValue,
      rightValue: rightValue ?? this.rightValue,
      lastMessage: lastMessage ?? this.lastMessage,
      isHandoverInProgress: isHandoverInProgress ?? this.isHandoverInProgress,
    );
  }
}

final dominoProvider = StateNotifierProvider<DominoNotifier, DominoState>((
  ref,
) {
  return DominoNotifier();
});

class DominoNotifier extends StateNotifier<DominoState> {
  DominoNotifier()
    : super(
        DominoState(
          players: [],
          board: [],
          deck: [],
          currentTurn: 0,
          status: DominoStatus.lobby,
        ),
      );

  void setupGame(int humanCount, int botCount) {
    List<DominoPlayer> initialPlayers = [];

    for (int i = 0; i < humanCount; i++) {
      initialPlayers.add(
        DominoPlayer(
          id: 'human_$i',
          name: humanCount == 1 ? 'Vous' : 'Joueur ${i + 1}',
          hand: [],
        ),
      );
    }

    for (int i = 0; i < botCount; i++) {
      initialPlayers.add(
        DominoPlayer(id: 'bot_$i', name: 'Bot ${i + 1}', hand: [], isBot: true),
      );
    }

    state = state.copyWith(
      players: initialPlayers,
      status: DominoStatus.lobby,
      board: [],
      deck: [],
      currentTurn: 0,
      winnerId: null,
      leftValue: null,
      rightValue: null,
      lastMessage: 'Partie prête',
      isHandoverInProgress: false,
    );
  }

  void startGame() {
    final allPieces = DominoPiece.generateSet()..shuffle();
    final players = state.players.map((p) => p.copyWith(hand: [])).toList();

    // Deal 7 pieces each
    for (var player in players) {
      for (int i = 0; i < 7; i++) {
        if (allPieces.isNotEmpty) {
          player.hand.add(allPieces.removeAt(0));
        }
      }
    }

    SoundService.playDominoShuffle();
    state = state.copyWith(
      players: players,
      deck: allPieces,
      board: [],
      status: DominoStatus.playing,
      currentTurn: 0,
      leftValue: null,
      rightValue: null,
      lastMessage: 'Bonne chance !',
    );

    // If it's a bot's turn (rare at start but still), let them play
    if (state.players[state.currentTurn].isBot) {
      _botTurn();
    }
  }

  bool canPlayAny() {
    final player = state.players[state.currentTurn];
    return player.hand.any((piece) => canPlay(piece));
  }

  bool canPlay(DominoPiece piece) {
    if (state.board.isEmpty) return true;
    final lv = state.leftValue;
    final rv = state.rightValue;
    if (lv == null || rv == null) return true;
    return piece.contains(lv) || piece.contains(rv);
  }

  void playPiece(DominoPiece piece, {bool atLeft = true}) {
    if (state.status != DominoStatus.playing) return;

    final player = state.players[state.currentTurn];
    if (!player.hand.contains(piece)) return;

    // Board is empty: first piece
    if (state.board.isEmpty) {
      final newPlayers = List<DominoPlayer>.from(state.players);
      final updatedHand = List<DominoPiece>.from(player.hand)..remove(piece);
      newPlayers[state.currentTurn] = player.copyWith(hand: updatedHand);

      SoundService.playDominoPlay();
      state = state.copyWith(
        board: [piece],
        players: newPlayers,
        leftValue: piece.sideA,
        rightValue: piece.sideB,
        lastMessage: '${player.name} a commencé avec $piece',
      );
      _checkWinOrNext();
      return;
    }

    // Try to play at requested side
    bool played = false;
    int? newLeft = state.leftValue;
    int? newRight = state.rightValue;
    List<DominoPiece> newBoard = List.from(state.board);

    int? currentLeft = state.leftValue;
    int? currentRight = state.rightValue;

    if (currentLeft == null || currentRight == null) {
      // Should not happen if board is not empty, but safety first
      return;
    }

    if (atLeft && piece.contains(currentLeft)) {
      // If sides don't match, we "flip" it conceptually by adjusting the new end value
      int matchValue = currentLeft;
      int otherValue = piece.otherSide(matchValue);
      newLeft = otherValue;
      newBoard.insert(0, piece);
      played = true;
    } else if (!atLeft && piece.contains(currentRight)) {
      int matchValue = currentRight;
      int otherValue = piece.otherSide(matchValue);
      newRight = otherValue;
      newBoard.add(piece);
      played = true;
    } else {
      // If requested side failed, try the other side automatically if valid
      if (piece.contains(currentLeft)) {
        newLeft = piece.otherSide(currentLeft);
        newBoard.insert(0, piece);
        played = true;
      } else if (piece.contains(currentRight)) {
        newRight = piece.otherSide(currentRight);
        newBoard.add(piece);
        played = true;
      }
    }

    if (played) {
      final newPlayers = List<DominoPlayer>.from(state.players);
      final updatedHand = List<DominoPiece>.from(player.hand)..remove(piece);
      newPlayers[state.currentTurn] = player.copyWith(hand: updatedHand);

      SoundService.playDominoPlay();
      state = state.copyWith(
        board: newBoard,
        players: newPlayers,
        leftValue: newLeft,
        rightValue: newRight,
        lastMessage: '${player.name} a joué $piece',
      );
      _checkWinOrNext();
    }
  }

  void drawPiece() {
    if (state.status != DominoStatus.playing) return;
    if (state.deck.isEmpty) {
      _nextTurn(); // If deck empty, skip
      return;
    }

    final newDeck = List<DominoPiece>.from(state.deck);
    final drawn = newDeck.removeAt(0);

    final newPlayers = List<DominoPlayer>.from(state.players);
    final player = newPlayers[state.currentTurn];
    final updatedHand = List<DominoPiece>.from(player.hand)..add(drawn);
    newPlayers[state.currentTurn] = player.copyWith(hand: updatedHand);

    SoundService.playDominoDraw();
    state = state.copyWith(
      deck: newDeck,
      players: newPlayers,
      lastMessage: '${player.name} a pioché',
    );

    // If drawn piece is playable, let the player play it (or continue turn if bot)
    if (player.isBot) {
      _botTurn();
    }
  }

  void _checkWinOrNext() {
    final player = state.players[state.currentTurn];
    if (player.hand.isEmpty) {
      state = state.copyWith(
        status: DominoStatus.finished,
        winnerId: player.id,
        lastMessage: '${player.name} a gagné !',
      );
      return;
    }

    // Check if game is blocked
    bool anyMovePossible = false;
    for (var p in state.players) {
      if (p.hand.any((item) => canPlay(item))) {
        anyMovePossible = true;
        break;
      }
    }

    if (!anyMovePossible && state.deck.isEmpty) {
      // Blocked! Whoever has fewer points wins
      DominoPlayer? best;
      int minScore = 999;
      for (var p in state.players) {
        int s = p.hand.fold(0, (sum, item) => sum + item.score);
        if (s < minScore) {
          minScore = s;
          best = p;
        }
      }
      state = state.copyWith(
        status: DominoStatus.finished,
        winnerId: best?.id,
        lastMessage: 'Jeu bloqué ! ${best?.name} gagne aux points.',
      );
      return;
    }

    _nextTurn();
  }

  void setHandoverComplete() {
    state = state.copyWith(isHandoverInProgress: false);
  }

  void _nextTurn() {
    int next = (state.currentTurn + 1) % state.players.length;
    bool needsHandover =
        !state.players[next].isBot &&
        state.players.any(
          (p) => p.isBot == false && p.id != state.players[next].id,
        );

    state = state.copyWith(
      currentTurn: next,
      isHandoverInProgress: needsHandover,
    );

    if (state.players[next].isBot) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        _botTurn();
      });
    }
  }

  void _botTurn() {
    if (state.status != DominoStatus.playing) return;

    final bot = state.players[state.currentTurn];
    // Find playable pieces
    final playable = bot.hand.where((p) => canPlay(p)).toList();

    if (playable.isNotEmpty) {
      // Simple strategy: play the highest score piece
      playable.sort((a, b) => b.score.compareTo(a.score));
      playPiece(playable.first);
    } else {
      if (state.deck.isNotEmpty) {
        drawPiece();
      } else {
        _nextTurn(); // Pass
        state = state.copyWith(lastMessage: '${bot.name} passe son tour');
      }
    }
  }
}
