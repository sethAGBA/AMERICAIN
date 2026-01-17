import 'package:flutter_test/flutter_test.dart';
import 'package:jeu_8_americain/models/card.dart';
import 'package:jeu_8_americain/models/player.dart';

void main() {
  group('Scoring System Tests', () {
    test('Card Point Values', () {
      expect(
        PlayingCard(id: 'ah', suit: Suit.hearts, rank: Rank.ace).points,
        1,
      );
      expect(
        PlayingCard(id: '2h', suit: Suit.hearts, rank: Rank.two).points,
        2,
      );
      expect(
        PlayingCard(id: '2s', suit: Suit.spades, rank: Rank.two).points,
        4,
      );
      expect(
        PlayingCard(id: '7h', suit: Suit.hearts, rank: Rank.seven).points,
        7,
      );
      expect(
        PlayingCard(id: '8h', suit: Suit.hearts, rank: Rank.eight).points,
        64,
      );
      expect(
        PlayingCard(id: '10h', suit: Suit.hearts, rank: Rank.ten).points,
        10,
      );
      expect(
        PlayingCard(id: 'jh', suit: Suit.hearts, rank: Rank.jack).points,
        11,
      );
      expect(
        PlayingCard(id: 'js', suit: Suit.spades, rank: Rank.jack).points,
        22,
      );
      expect(
        PlayingCard(id: 'joker', suit: Suit.hearts, rank: Rank.joker).points,
        50,
      );
      expect(
        PlayingCard(id: 'kh', suit: Suit.hearts, rank: Rank.king).points,
        1,
      );
      expect(
        PlayingCard(id: 'qh', suit: Suit.hearts, rank: Rank.queen).points,
        1,
      );
      expect(
        PlayingCard(id: '3h', suit: Suit.hearts, rank: Rank.three).points,
        3,
      );
      expect(
        PlayingCard(id: '9h', suit: Suit.hearts, rank: Rank.nine).points,
        9,
      );
    });

    test('Player Hand Points', () {
      final player = Player(
        id: 'p1',
        name: 'Alice',
        hand: [
          PlayingCard(id: 'ah', suit: Suit.hearts, rank: Rank.ace), // 1
          PlayingCard(id: '8h', suit: Suit.hearts, rank: Rank.eight), // 64
          PlayingCard(id: 'js', suit: Suit.spades, rank: Rank.jack), // 22
        ],
      );
      expect(player.handPoints, 87); // 1 + 64 + 22
    });

    test('Winner Hand Points', () {
      final player = Player(id: 'p1', name: 'Alice', hand: []);
      expect(player.handPoints, 0);
    });
  });
}
