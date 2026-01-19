import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ludo_game_state.dart';
import '../models/ludo_player.dart';
import '../models/ludo_piece.dart';
import '../ludo_logic.dart';
import '../../services/sound_service.dart';

final ludoProvider = StateNotifierProvider<LudoGameNotifier, LudoGameState>((
  ref,
) {
  return LudoGameNotifier();
});

class LudoGameNotifier extends StateNotifier<LudoGameState> {
  LudoGameNotifier() : super(LudoGameState.initial()) {
    _loadSavedGame();
  }

  static const _saveKey = 'ludo_game_state';
  final _random = Random();

  Future<void> _loadSavedGame() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedData = prefs.getString(_saveKey);
      if (savedData != null) {
        final decoded = json.decode(savedData);
        state = LudoGameState.fromJson(decoded);

        // If it's a bot's turn, trigger it
        if (state.players[state.currentPlayerIndex].type == PlayerType.bot &&
            state.turnState != LudoTurnState.finished) {
          _handleBotTurn();
        }
      }
    } catch (e) {
      debugPrint('Error loading Ludo game: $e');
    }
  }

  Future<void> _saveGame() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = json.encode(state.toJson());
      await prefs.setString(_saveKey, jsonData);
    } catch (e) {
      debugPrint('Error saving Ludo game: $e');
    }
  }

  void startNewGame(List<PlayerType> slotTypes) {
    if (slotTypes.length != 4) return;

    final players = <LudoPlayer>[];
    for (int i = 0; i < 4; i++) {
      final color = LudoColor.values[i];
      players.add(LudoPlayer.initial(color, slotTypes[i]));
    }

    // Find first active player
    int firstPlayerIndex = 0;
    while (players[firstPlayerIndex].type == PlayerType.none &&
        firstPlayerIndex < 3) {
      firstPlayerIndex++;
    }

    state = LudoGameState(
      players: players,
      currentPlayerIndex: firstPlayerIndex,
      turnState: LudoTurnState.waitingForRoll,
    );

    // If first player is bot, trigger roll
    if (players[firstPlayerIndex].type == PlayerType.bot) {
      _handleBotTurn();
    }
    _saveGame();
  }

  Future<void> leaveGame() async {
    state = LudoGameState.initial();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_saveKey);
  }

  void rollDice() {
    if (state.turnState != LudoTurnState.waitingForRoll) return;

    SoundService.playDiceRoll();

    final d1 = _random.nextInt(6) + 1;
    final d2 = _random.nextInt(6) + 1;
    // final d1 = 6; final d2 = 6; // DEBUG: Force doubles

    final newValues = [...state.diceValues, d1, d2];
    // Restricted Doubles Rule: Only 6+6 triggers a re-roll.
    // Other pairs (1+1..5+5) are single rolls.
    final isDouble = (d1 == 6 && d2 == 6);
    if (isDouble) SoundService.playLudoDoubleSix();
    final canMove = _canMakeAnyMove(newValues);

    if (isDouble && canMove) {
      // Keep rolling only if we can actually use the dice (or have existing valid dice)
      // Per user rule: "quand on a pas eu de 6... on n'a pas droit a un deuxième jeu"
      state = state.copyWith(
        diceValues: newValues,
        turnState: LudoTurnState.waitingForRoll,
      );
      _saveGame();
    } else {
      // Done rolling (Not double, OR Double but no moves possible)
      state = state.copyWith(
        diceValues: newValues,
        turnState: LudoTurnState.waitingForMove,
      );
      _saveGame();
      // Auto-skip if no moves possible
      if (!canMove) {
        Future.delayed(const Duration(seconds: 1), () {
          // Ensure state hasn't changed (e.g. game reset)
          // Note: StateNotifier doesn't have mounted check, but we can check turnState
          // actually nextTurn() is safe enough here.
          nextTurn();
        });
      }
    }
  }

  void selectDie(int index) {
    if (index >= 0 && index < state.diceValues.length) {
      final currentSelected = List<int>.from(state.selectedDiceIndices);
      if (currentSelected.contains(index)) {
        currentSelected.remove(index);
      } else {
        currentSelected.add(index);
      }
      state = state.copyWith(selectedDiceIndices: currentSelected);
      _saveGame();
    }
  }

  void movePiece(String pieceId) {
    if (state.turnState != LudoTurnState.waitingForMove) return;
    if (state.diceValues.isEmpty) return;

    final playerIndex = state.currentPlayerIndex;
    final player = state.players[playerIndex];
    final pieceIndex = player.pieces.indexWhere((p) => p.id == pieceId);

    if (pieceIndex == -1) return;
    final piece = player.pieces[pieceIndex];

    // Immobilized if captured this turn
    if (piece.hasCaptured) return;

    if (piece.state == PieceState.home) {
      final startPos = LudoLogic.startPositions[player.color]!;
      final allPieces = state.players.expand((p) => p.pieces).toList();
      final opponentBlockers = allPieces
          .where(
            (p) =>
                p.state == PieceState.track &&
                p.position == startPos &&
                p.color != piece.color,
          )
          .toList();
      final n = opponentBlockers.length;

      if (n >= 2) {
        // Start square is blocked by a bridge of N pieces.
        // Check for Special Exit: Need N sixes and total N pieces (Home + InJail).
        final sixesIndexes = <int>[];
        for (int i = 0; i < state.diceValues.length; i++) {
          if (state.diceValues[i] == 6) sixesIndexes.add(i);
        }

        final homePieces = player.pieces
            .where((p) => p.state == PieceState.home)
            .toList();
        final jailPieces = player.pieces
            .where((p) => p.state == PieceState.inJail)
            .toList();

        if (sixesIndexes.length >= n &&
            (homePieces.length + jailPieces.length) >= n) {
          // SPECIAL EXIT TRIGGERED
          _executeSpecialExit(
            playerIndex,
            n,
            startPos,
            sixesIndexes,
            homePieces,
            jailPieces,
          );
          return;
        }
        // If not enough sixes/pieces, normal exit is also blocked by bridge.
        SoundService.playLudoBridge();
        // isValidMove will return false below.
      }
    }

    // Check for Combined Move Condition
    // Rule: Single piece in play (Track/GoalStretch) AND No 6 in dice.
    // Exception: If 6 is present, individual play allowed (to exit new piece).
    final piecesInPlay = player.pieces
        .where(
          (p) =>
              p.state == PieceState.track || p.state == PieceState.goalStretch,
        )
        .toList();

    final hasSix = state.diceValues.contains(6);
    final allPieces = state.players.expand((p) => p.pieces).toList();
    bool isForcedCombined =
        piecesInPlay.length == 1 && !hasSix && state.diceValues.length >= 2;

    // PROTECTION RULE: Even if manual or not forced, if playing a single die
    // results in a capture that blocks the only remaining piece from playing other dice,
    // we MUST force a combined move instead.
    if (!isForcedCombined && state.diceValues.length >= 2) {
      // Check if this piece is the ONLY one that can use the dice
      bool othersCanMove = false;
      for (final otherP in player.pieces) {
        if (otherP.id == piece.id) continue;
        for (final die in state.diceValues) {
          if (LudoLogic.isValidMove(otherP, die, allPieces: allPieces)) {
            othersCanMove = true;
            break;
          }
        }
        if (othersCanMove) break;
      }

      if (!othersCanMove) {
        // If this piece moves and captures, it will be immobilized.
        // Check if ANY die in diceValues causes a capture for this piece.
        for (final die in state.diceValues) {
          final mockMove = LudoLogic.movePiece(piece, die);
          bool wouldCapture = false;
          if (mockMove.state == PieceState.track) {
            for (final other in allPieces) {
              if (LudoLogic.canCapture(mockMove, other)) {
                wouldCapture = true;
                break;
              }
            }
          }

          if (wouldCapture) {
            // PROTECTION TRIGGERED: Force combined move to avoid invalid capture
            isForcedCombined = true;
            break;
          }
        }
      }
    }

    // Determine which die/dice to use
    int usedDieIndex = -2; // -2: Undefined, -1: Sum, 0+: Single index
    int roll = 0;

    if (isForcedCombined) {
      final sumRoll = state.diceValues.fold(0, (sum, val) => sum + val);
      final allPieces = state.players.expand((p) => p.pieces).toList();

      // Check if SUM move is valid
      if (LudoLogic.isValidMove(piece, sumRoll, allPieces: allPieces)) {
        roll = sumRoll;
        usedDieIndex = -1; // Use SUM
      } else {
        // Exception 2: SUM is blocked. Check if any individual die is playable.
        // We try playing the first available valid die.
        for (int i = 0; i < state.diceValues.length; i++) {
          if (LudoLogic.isValidMove(
            piece,
            state.diceValues[i],
            allPieces: allPieces,
          )) {
            roll = state.diceValues[i];
            usedDieIndex = i;
            break;
          }
        }
      }

      // If still -2, it means even partial moves are blocked or invalid (e.g. piece is finished)
      if (usedDieIndex == -2) return;
    } else {
      // Standard Selection Logic (or dice length == 1)
      if (state.selectedDiceIndices.isNotEmpty) {
        if (state.selectedDiceIndices.length == 1) {
          usedDieIndex = state.selectedDiceIndices[0];
          roll = state.diceValues[usedDieIndex];
        } else {
          // Manual Combination: Use sum and execute sequentially
          final sortedIndices = List<int>.from(state.selectedDiceIndices)
            ..sort();
          final sequence = sortedIndices
              .map((i) => state.diceValues[i])
              .toList();

          // Check for manual combined move validity
          if (_isValidSequence(piece, sequence)) {
            _executeSequentialMove(pieceId, sequence);
            return;
          } else {
            // Try reverse order for 2-die combinations
            if (sequence.length == 2) {
              final rev = sequence.reversed.toList();
              if (_isValidSequence(piece, rev)) {
                _executeSequentialMove(pieceId, rev);
                return;
              }
            }
            return;
          }
        }
      } else if (state.diceValues.length == 1) {
        usedDieIndex = 0;
        roll = state.diceValues[0];
      } else {
        // Multiple dice, none selected.
        // IMPROVEMENT: If only one die is valid for THIS piece, auto-select it.
        final validIndices = <int>[];
        for (int i = 0; i < state.diceValues.length; i++) {
          if (LudoLogic.isValidMove(
            piece,
            state.diceValues[i],
            allPieces: allPieces,
          )) {
            validIndices.add(i);
          }
        }

        if (validIndices.length == 1) {
          usedDieIndex = validIndices[0];
          roll = state.diceValues[usedDieIndex];
        } else {
          return;
        }
      }
    }

    // 14. Automatic Combined Move on Exit
    if (piece.state == PieceState.home &&
        roll == 6 &&
        state.diceValues.length > 1 &&
        usedDieIndex >= 0) {
      final availableDice = List<int>.from(state.diceValues);
      availableDice.removeAt(usedDieIndex);

      // Rule refined: Automatic exit ONLY if NO other choice.
      // Check if any other piece can use any of the remaining dice.
      bool otherMovePossible = false;
      for (final otherPiece in player.pieces) {
        if (otherPiece.id == piece.id) continue;
        for (final dieValue in availableDice) {
          if (LudoLogic.isValidMove(
            otherPiece,
            dieValue,
            allPieces: allPieces,
          )) {
            otherMovePossible = true;
            break;
          }
        }
        if (otherMovePossible) break;
      }

      if (!otherMovePossible) {
        List<int> sequence = [6];
        LudoPiece currentMock = LudoLogic.movePiece(piece, 6);

        // Check capture on start square
        bool cStart = false;
        for (final other in allPieces) {
          if (LudoLogic.canCapture(currentMock, other)) {
            cStart = true;
            break;
          }
        }
        if (cStart) currentMock = currentMock.copyWith(hasCaptured: true);

        // Greedily consume remaining dice
        List<int> remaining = List.from(availableDice);
        while (remaining.isNotEmpty) {
          int? nextDie;
          for (int i = 0; i < remaining.length; i++) {
            if (LudoLogic.isValidMove(
              currentMock,
              remaining[i],
              allPieces: allPieces,
            )) {
              nextDie = remaining[i];
              remaining.removeAt(i);
              break;
            }
          }
          if (nextDie != null) {
            sequence.add(nextDie);
            currentMock = LudoLogic.movePiece(currentMock, nextDie);
            bool cap = false;
            for (final other in allPieces) {
              if (LudoLogic.canCapture(currentMock, other)) {
                cap = true;
                break;
              }
            }
            if (cap) currentMock = currentMock.copyWith(hasCaptured: true);
          } else {
            break;
          }
        }

        if (sequence.length > 1) {
          _executeSequentialMove(pieceId, sequence);
          return;
        }
      }
    }

    // Check for "Mandatory Unblocking" rule (Exception 2 handled in Logic)
    final unblockPositions = LudoLogic.getMandatoryUnblockPositions(
      state.players,
      playerIndex,
    );

    if (unblockPositions.isNotEmpty) {
      // Is the current piece part of a mandatory unblock bridge?
      bool isUnblockingPiece =
          piece.state == PieceState.track &&
          unblockPositions.contains(piece.position);

      if (!isUnblockingPiece) {
        // Can ANY piece that SHOULD unblock actually move with this roll?
        bool anyUnblockerCanMove = false;
        for (final pos in unblockPositions) {
          final bridgePieces = player.pieces.where(
            (p) => p.state == PieceState.track && p.position == pos,
          );
          for (final bp in bridgePieces) {
            if (LudoLogic.isValidMove(bp, roll, allPieces: allPieces)) {
              anyUnblockerCanMove = true;
              break;
            }
          }
          if (anyUnblockerCanMove) break;
        }

        if (anyUnblockerCanMove) {
          // You MUST move one of the pieces that form the mandatory bridge
          SoundService.playLudoBridge();
          return;
        }
      }
    }

    // Final safety check (blocking check)
    // For combined moves, we need to check the path sequentially for captures.
    if (usedDieIndex == -1) {
      // For combined moves, we must find a valid sequence (d1 then d2, OR d2 then d1, etc.)
      // Since it's usually just 2 dice, we try both.
      final dice = state.diceValues;
      bool valid = false;
      List<int>? validSequence;

      if (_isValidSequence(piece, [dice[0], dice[1]])) {
        valid = true;
        validSequence = [dice[0], dice[1]];
      } else if (_isValidSequence(piece, [dice[1], dice[0]])) {
        valid = true;
        validSequence = [dice[1], dice[0]];
      }

      if (!valid) return;
      _executeSequentialMove(pieceId, validSequence!);
      return;
    }

    if (!LudoLogic.isValidMove(piece, roll, allPieces: allPieces)) {
      SoundService.playLudoBridge();
      return;
    }

    // Perform move
    SoundService.playLudoMove();
    final movedPiece = LudoLogic.movePiece(piece, roll);

    if (movedPiece.state == PieceState.goal) {
      SoundService.playLudoGoal();
    }

    // Remove used die/dice
    List<int> newDiceValues;
    if (usedDieIndex == -1) {
      // Combined move consumed ALL dice
      newDiceValues = [];
    } else {
      newDiceValues = List.from(state.diceValues);
      newDiceValues.removeAt(usedDieIndex);
    }

    // Handle Captures
    List<LudoPlayer> updatedPlayers = List.from(state.players);
    updatedPlayers[playerIndex] = player.copyWith(
      pieces: [
        ...player.pieces.sublist(0, pieceIndex),
        movedPiece,
        ...player.pieces.sublist(pieceIndex + 1),
      ],
    );

    // Check for captures
    bool captureOccurredTotal = false;
    if (movedPiece.state == PieceState.track) {
      for (int i = 0; i < 4; i++) {
        if (i == playerIndex) continue; // Don't capture self

        final opponent = updatedPlayers[i];
        final capturedIndices = <int>[];

        for (int j = 0; j < opponent.pieces.length; j++) {
          if (LudoLogic.canCapture(movedPiece, opponent.pieces[j])) {
            capturedIndices.add(j);
          }
        }

        if (capturedIndices.isNotEmpty) {
          captureOccurredTotal = true;
          // CAPTURE: Send to Opponent's Jail (Opponent's piece is captured)
          // "il part dans VOTRE zone de capture" -> Visually.
          // State-wise: PieceState.inJail.
          List<LudoPiece> newOppPieces = List.from(opponent.pieces);
          for (final idx in capturedIndices) {
            newOppPieces[idx] = newOppPieces[idx].copyWith(
              state: PieceState.inJail,
              position: 0,
              capturedBy: playerIndex, // Set the capturer's index
              hasCaptured: false, // Reset capture status if jailed
            );
          }
          updatedPlayers[i] = opponent.copyWith(pieces: newOppPieces);
        }
      }
    }

    // Update moved piece with capture status
    final pieceToStore = captureOccurredTotal
        ? movedPiece.copyWith(hasCaptured: true)
        : movedPiece;

    updatedPlayers[playerIndex] = player.copyWith(
      pieces: [
        ...player.pieces.sublist(0, pieceIndex),
        pieceToStore,
        ...player.pieces.sublist(pieceIndex + 1),
      ],
    );

    state = state.copyWith(
      players: updatedPlayers,
      diceValues: newDiceValues,
      selectedDiceIndices: [], // Clear selection
    );

    if (newDiceValues.isEmpty) {
      // Turn finished
      nextTurn();
    } else {
      _saveGame();
      // Check if any moves remaining? if not -> nextTurn
      // Optimized: Just let player try, or auto-skip?
      // Better to check. If stuck, skip.
      if (!_canMakeAnyMove(newDiceValues)) {
        nextTurn();
      }
    }
  }

  bool _canMakeAnyMove(List<int> dice) {
    if (dice.isEmpty) return false;

    final player = state.currentPlayer;
    final allPieces = state.players.expand((p) => p.pieces).toList();

    // Check for "Special Exit" possibility
    final homePieces = player.pieces
        .where((p) => p.state == PieceState.home)
        .toList();
    final jailPieces = player.pieces
        .where((p) => p.state == PieceState.inJail)
        .toList();

    if ((homePieces.length + jailPieces.length) >= 2) {
      final startPos = LudoLogic.startPositions[player.color]!;
      final opponentBlockersCount = allPieces
          .where(
            (p) =>
                p.state == PieceState.track &&
                p.position == startPos &&
                p.color != player.color,
          )
          .length;

      if (opponentBlockersCount >= 2) {
        final sixesCount = dice.where((v) => v == 6).length;
        if (sixesCount >= opponentBlockersCount &&
            (homePieces.length + jailPieces.length) >= opponentBlockersCount) {
          return true;
        }
      }
    }

    final piecesInPlay = player.pieces
        .where(
          (p) =>
              p.state == PieceState.track || p.state == PieceState.goalStretch,
        )
        .toList();

    final hasSix = dice.contains(6);
    final isForcedCombined =
        piecesInPlay.length == 1 && !hasSix && dice.length >= 2;

    if (isForcedCombined) {
      final piece = piecesInPlay.first;
      // Try [d1, d2]
      if (LudoLogic.isValidMove(piece, dice[0], allPieces: allPieces)) {
        final p1 = LudoLogic.movePiece(piece, dice[0]);
        // Mock capture check
        bool c1 = false;
        for (final other in allPieces) {
          if (LudoLogic.canCapture(p1, other)) {
            c1 = true;
            break;
          }
        }
        final p1Mock = c1 ? p1.copyWith(hasCaptured: true) : p1;
        if (LudoLogic.isValidMove(p1Mock, dice[1], allPieces: allPieces)) {
          return true;
        }
      }
      // Try [d2, d1]
      if (LudoLogic.isValidMove(piece, dice[1], allPieces: allPieces)) {
        final p1 = LudoLogic.movePiece(piece, dice[1]);
        bool c1 = false;
        for (final other in allPieces) {
          if (LudoLogic.canCapture(p1, other)) {
            c1 = true;
            break;
          }
        }
        final p1Mock = c1 ? p1.copyWith(hasCaptured: true) : p1;
        if (LudoLogic.isValidMove(p1Mock, dice[0], allPieces: allPieces)) {
          return true;
        }
      }

      // Fallback: Check if any individual die is playable (Exception 2)
      for (final die in dice) {
        if (LudoLogic.isValidMove(piece, die, allPieces: allPieces)) {
          return true;
        }
      }
      return false;
    }

    // Check for "Mandatory Unblocking" rule
    final unblockPositions = LudoLogic.getMandatoryUnblockPositions(
      state.players,
      state.currentPlayerIndex,
    );

    if (unblockPositions.isNotEmpty) {
      // If ANY piece at these positions can move with ANY of the dice, then we have a move
      for (final die in dice) {
        for (final pos in unblockPositions) {
          final bridgePieces = player.pieces.where(
            (p) => p.state == PieceState.track && p.position == pos,
          );
          for (final bp in bridgePieces) {
            if (LudoLogic.isValidMove(bp, die, allPieces: allPieces)) {
              return true;
            }
          }
        }
      }

      // If NO piece in the bridge can move with the current dice,
      // the blocker is usually still restricted or can they move other pieces?
      // Rule says "il doit commencer par descendre sa pile".
      // If it's IMPOSSIBLE to descend the pile this turn (dice don't allow it),
      // then we fallback to standard check?
      // "Si le joueur bloqueur est lui-même bloqué par un autre joueur, alors il n'est plus obligé"
      // Exception 2 is already in getMandatoryUnblockPositions.

      // I will assume if he can't break the bridge this turn, he can move other pieces
      // to avoid soft-locking B while A is also stuck.
    }

    // Standard check for all dice and all pieces
    for (final die in dice) {
      for (final piece in player.pieces) {
        if (piece.hasCaptured) continue;
        if (LudoLogic.isValidMove(piece, die, allPieces: allPieces)) {
          return true;
        }
      }
    }
    return false;
  }

  Future<void> _handleBotTurn() async {
    // Artificial delay
    await Future.delayed(const Duration(seconds: 1));
    if (state.players[state.currentPlayerIndex].type != PlayerType.bot) return;

    // 1. Roll
    rollDice();
    await Future.delayed(const Duration(milliseconds: 500));
    if (state.diceValues.isEmpty) return; // Turn skipped or game reset

    // 2. Simple AI: Move first valid piece
    final player = state.players[state.currentPlayerIndex];
    final allPieces = state.players.expand((p) => p.pieces).toList();

    // Try a combined move with all dice if possible
    if (state.diceValues.length >= 2) {
      for (final p in player.pieces) {
        if (p.hasCaptured) continue;
        if (_isValidSequence(p, state.diceValues)) {
          movePiece(p.id);
          return;
        }
      }
    }

    // Otherwise try any single die
    for (final die in state.diceValues) {
      for (final p in player.pieces) {
        if (p.hasCaptured) continue;
        if (LudoLogic.isValidMove(p, die, allPieces: allPieces)) {
          movePiece(p.id);
          return;
        }
      }
    }
  }

  void _executeSpecialExit(
    int playerIndex,
    int n,
    int startPos,
    List<int> sixesIndexes,
    List<LudoPiece> homePieces,
    List<LudoPiece> jailPieces,
  ) {
    final player = state.players[playerIndex];

    // 1. Determine pieces involved (prioritize Jail)
    final b = min(n, jailPieces.length); // Number of jail pieces to buy back
    final h = n - b; // Remaining pieces must come from Home

    List<LudoPiece> involvedJail = jailPieces.take(b).toList();
    List<LudoPiece> involvedHome = homePieces.take(h).toList();

    // 2. Consume N sixes
    List<int> newDiceValues = List.from(state.diceValues);
    final consumedIndexes = sixesIndexes.take(n).toList()
      ..sort((a, b) => b.compareTo(a));
    for (final idx in consumedIndexes) {
      newDiceValues.removeAt(idx);
    }

    // 3. Process Buy-backs and potential Exit
    List<LudoPlayer> updatedPlayers = List.from(state.players);
    List<LudoPiece> updatedPlayerPieces = List.from(player.pieces);

    bool shouldExit = (n - b) > 0; // At least one 6 left for exit?
    // Wait, the rule says "1 six pour racheter + 1 six pour sortir les 2" (Case 1b).
    // In 1b: n=2, jail=1. b=1. n-b = 1. So yes, shouldExit = true.
    // In 1c: n=2, jail=2. b=2. n-b = 0. So shouldExit = false.
    // This logic holds.

    if (shouldExit) {
      // Move all N involved pieces (those from jail and those from home) to track
      // First, "move" jail pieces to home logically, then home to track.
      // But we can just move them to track directly in state.
      for (var p in involvedJail) {
        final idx = updatedPlayerPieces.indexWhere((pc) => pc.id == p.id);
        updatedPlayerPieces[idx] = p.copyWith(
          state: PieceState.track,
          position: startPos,
          capturedBy: null,
          hasCaptured: true, // Special Exit Capture
        );
      }
      for (var p in involvedHome) {
        final idx = updatedPlayerPieces.indexWhere((pc) => pc.id == p.id);
        updatedPlayerPieces[idx] = p.copyWith(
          state: PieceState.track,
          position: startPos,
          hasCaptured: true, // Special Exit Capture
        );
      }

      // Handle Captures
      updatedPlayers[playerIndex] = player.copyWith(
        pieces: updatedPlayerPieces,
      );
      for (int i = 0; i < 4; i++) {
        if (i == playerIndex) continue;
        final opponent = updatedPlayers[i];
        List<LudoPiece> oppPieces = List.from(opponent.pieces);
        bool captureOccurred = false;

        for (int j = 0; j < oppPieces.length; j++) {
          if (oppPieces[j].state == PieceState.track &&
              oppPieces[j].position == startPos) {
            oppPieces[j] = oppPieces[j].copyWith(
              state: PieceState.inJail,
              position: 0,
              capturedBy: playerIndex,
            );
            captureOccurred = true;
          }
        }
        if (captureOccurred) {
          SoundService.playLudoCapture();
          updatedPlayers[i] = opponent.copyWith(pieces: oppPieces);
        }
      }
    } else {
      // ONLY Buy-back (back to home)
      for (var p in involvedJail) {
        final idx = updatedPlayerPieces.indexWhere((pc) => pc.id == p.id);
        updatedPlayerPieces[idx] = p.copyWith(
          state: PieceState.home,
          position: 0,
          capturedBy: null,
        );
      }
      updatedPlayers[playerIndex] = player.copyWith(
        pieces: updatedPlayerPieces,
      );
    }

    state = state.copyWith(
      players: updatedPlayers,
      diceValues: newDiceValues,
      selectedDiceIndices: [],
    );

    if (newDiceValues.isEmpty) {
      nextTurn();
    } else if (!_canMakeAnyMove(newDiceValues)) {
      nextTurn();
    }
  }

  void _executeSequentialMove(String pieceId, List<int> sequence) {
    // Re-fetch state
    final playerIndex = state.currentPlayerIndex;
    final player = state.players[playerIndex];
    final pieceIndex = player.pieces.indexWhere((p) => p.id == pieceId);
    final piece = player.pieces[pieceIndex];

    // --- TELEPORT LOGIC ---
    // Combined moves jump directly to the sum destination.
    int totalRoll = sequence.reduce((a, b) => a + b);

    // If starting from Home/Jail, we actually move (Total - 6) from startPos
    // because LudoLogic.movePiece(Home, X) just puts it on startPos.
    LudoPiece movedPiece;
    if (piece.state == PieceState.home || piece.state == PieceState.inJail) {
      final startPosPiece = LudoLogic.movePiece(piece, 6); // Just gets it out
      final remaining = totalRoll - 6;
      if (remaining > 0) {
        movedPiece = LudoLogic.movePiece(startPosPiece, remaining);
      } else {
        movedPiece = startPosPiece;
      }
    } else {
      movedPiece = LudoLogic.movePiece(piece, totalRoll);
    }

    // Apply Capture ONLY at the final destination
    final updatedPlayersWithCapture = _checkAndApplyCapture(movedPiece);

    if (movedPiece.state == PieceState.goal) {
      SoundService.playLudoGoal();
    }

    if (updatedPlayersWithCapture != null) {
      state = state.copyWith(players: updatedPlayersWithCapture);
    } else {
      // Just Update the piece position
      final playerIdx = state.currentPlayerIndex;
      final p = state.players[playerIdx];
      final pIdx = p.pieces.indexWhere((p) => p.id == pieceId);
      state = state.copyWith(
        players: [
          ...state.players.sublist(0, playerIdx),
          p.copyWith(
            pieces: [
              ...p.pieces.sublist(0, pIdx),
              movedPiece,
              ...p.pieces.sublist(pIdx + 1),
            ],
          ),
          ...state.players.sublist(playerIdx + 1),
        ],
      );
    }

    // Clear dice and turn
    List<int> newDice = List.from(state.diceValues);
    for (final roll in sequence) {
      newDice.remove(roll);
    }

    state = state.copyWith(diceValues: newDice, selectedDiceIndices: []);
    if (newDice.isEmpty || !_canMakeAnyMove(newDice)) {
      nextTurn();
    } else {
      _saveGame();
    }
  }

  void nextTurn() {
    int nextIndex = (state.currentPlayerIndex + 1) % 4;

    // Skip inactive players (PlayerType.none)
    // Safety break to prevent infinite loop if all are none (should not happen)
    int attempts = 0;
    while (state.players[nextIndex].type == PlayerType.none && attempts < 4) {
      nextIndex = (nextIndex + 1) % 4;
      attempts++;
    }

    // Reset capture status for ALL pieces at start of turn
    final updatedPlayers = state.players.map((player) {
      return player.copyWith(
        pieces: player.pieces
            .map((p) => p.copyWith(hasCaptured: false))
            .toList(),
      );
    }).toList();

    state = state.copyWith(
      currentPlayerIndex: nextIndex,
      diceValues: [],
      selectedDiceIndices: [],
      turnState: LudoTurnState.waitingForRoll,
      players: updatedPlayers,
    );

    _saveGame();

    // If next player is a Bot, trigger roll after delay
    if (state.players[nextIndex].type == PlayerType.bot) {
      _handleBotTurn();
    }
  }

  /// Checks if a sequence of dice rolls is valid for a piece,
  /// simulating intermediate states and captures.
  bool _isValidSequence(LudoPiece piece, List<int> sequence) {
    if (sequence.isEmpty) return false;
    final allPieces = state.players.expand((p) => p.pieces).toList();

    // --- TELEPORT SIMULATION ---
    int totalRoll = sequence.reduce((a, b) => a + b);

    if (piece.state == PieceState.home || piece.state == PieceState.inJail) {
      // Must contain at least one 6
      if (!sequence.contains(6)) return false;

      // Simulate exit
      final startPos = LudoLogic.startPositions[piece.color]!;
      LudoPiece onTrack = piece.copyWith(
        state: PieceState.track,
        position: startPos,
      );
      final remainingRoll = totalRoll - 6;

      if (remainingRoll == 0) return true;
      return LudoLogic.isValidMove(
        onTrack,
        remainingRoll,
        allPieces: allPieces,
      );
    }

    // Pieces already on track
    // isValidMove handles path-blocking internal simulation
    return LudoLogic.isValidMove(piece, totalRoll, allPieces: allPieces);
  }

  List<LudoPlayer>? _checkAndApplyCapture(LudoPiece piece) {
    if (piece.state != PieceState.track) return null;

    final playerIndex = state.currentPlayerIndex;
    final updatedPlayers = List<LudoPlayer>.from(state.players);
    bool captureOccurred = false;

    for (int i = 0; i < 4; i++) {
      if (i == playerIndex) continue;
      final opponent = updatedPlayers[i];
      final capturedIndices = <int>[];

      for (int j = 0; j < opponent.pieces.length; j++) {
        if (LudoLogic.canCapture(piece, opponent.pieces[j])) {
          capturedIndices.add(j);
        }
      }

      if (capturedIndices.isNotEmpty) {
        captureOccurred = true;
        List<LudoPiece> newOppPieces = List.from(opponent.pieces);
        for (final idx in capturedIndices) {
          newOppPieces[idx] = newOppPieces[idx].copyWith(
            state: PieceState.inJail,
            position: 0,
            capturedBy: playerIndex,
            hasCaptured: false,
          );
        }
        updatedPlayers[i] = opponent.copyWith(pieces: newOppPieces);
      }
    }

    if (captureOccurred) {
      SoundService.playLudoCapture();
      final player = updatedPlayers[playerIndex];
      final pIdx = player.pieces.indexWhere((p) => p.id == piece.id);
      if (pIdx != -1) {
        updatedPlayers[playerIndex] = player.copyWith(
          pieces: [
            ...player.pieces.sublist(0, pIdx),
            piece.copyWith(hasCaptured: true),
            ...player.pieces.sublist(pIdx + 1),
          ],
        );
      }
      return updatedPlayers;
    }
    return null;
  }
}
