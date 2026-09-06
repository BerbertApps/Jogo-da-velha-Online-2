import 'dart:math';
import '../models/game_state.dart';

class AI {
  static const _winLines = [
    [0, 1, 2], [3, 4, 5], [6, 7, 8],
    [0, 3, 6], [1, 4, 7], [2, 5, 8],
    [0, 4, 8], [2, 4, 6],
  ];

  static int? bestMove(List<String> board, Difficulty difficulty,
      {String ai = 'O', String human = 'X'}) {
    switch (difficulty) {
      case Difficulty.facil:
        return _randomMove(board);
      case Difficulty.medio:
        // 60% minimax, 40% aleatório
        final r = Random();
        if (r.nextDouble() < 0.4) return _randomMove(board);
        return _minimaxMove(board, ai, human, maxDepth: 2);
      case Difficulty.dificil:
        // minimax com limite de profundidade (menos precisão)
        return _minimaxMove(board, ai, human, maxDepth: 3);
      case Difficulty.mestre:
        // minimax completo (perfeito)
        return _minimaxMove(board, ai, human, maxDepth: 9);
    }
    return null;
  }

  static int? _randomMove(List<String> board) {
    final empties = <int>[];
    for (var i = 0; i < 9; i++) {
      if (board[i] == '') empties.add(i);
    }
    if (empties.isEmpty) return null;
    return empties[Random().nextInt(empties.length)];
  }

  static int? _minimaxMove(List<String> board, String ai, String human,
      {required int maxDepth}) {
    int bestVal = -1000;
    int? bestMove;
    for (var i = 0; i < 9; i++) {
      if (board[i] == '') {
        board[i] = ai;
        final val =
            _minimax(board, 0, false, ai, human, maxDepth, -1000, 1000);
        board[i] = '';
        if (val > bestVal) {
          bestMove = i;
          bestVal = val;
        }
      }
    }
    return bestMove;
  }

  static int _evaluate(List<String> board, String player) {
    for (final c in _winLines) {
      if (board[c[0]] != '' &&
          board[c[0]] == board[c[1]] &&
          board[c[1]] == board[c[2]]) {
        return board[c[0]] == player ? 10 : -10;
      }
    }
    return 0;
  }

  static int _minimax(List<String> board, int d, bool isMax, String ai,
      String human, int maxDepth, int alpha, int beta) {
    final score = _evaluate(board, ai);
    if (score == 10) return score - d;
    if (score == -10) return score + d;
    if (!board.contains('') || d >= maxDepth) return 0;

    if (isMax) {
      int best = -1000;
      for (var i = 0; i < 9; i++) {
        if (board[i] == '') {
          board[i] = ai;
          best = max(best,
              _minimax(board, d + 1, false, ai, human, maxDepth, alpha, beta));
          board[i] = '';
          alpha = max(alpha, best);
          if (beta <= alpha) break;
        }
      }
      return best;
    } else {
      int best = 1000;
      for (var i = 0; i < 9; i++) {
        if (board[i] == '') {
          board[i] = human;
          best = min(best,
              _minimax(board, d + 1, true, ai, human, maxDepth, alpha, beta));
          board[i] = '';
          beta = min(beta, best);
          if (beta <= alpha) break;
        }
      }
      return best;
    }
  }
}
