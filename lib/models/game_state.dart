import 'package:flutter/material.dart';

enum GameMode { vsAI, vsFriend, online }
enum Difficulty { facil, medio, dificil, mestre }
enum Player { human, ai }

class GameState extends ChangeNotifier {
  GameMode mode = GameMode.vsAI;
  Difficulty difficulty = Difficulty.dificil;

  int playerScore = 0;
  int aiScore = 0;
  int ties = 0;

  int totalGames = 0;
  int wins = 0;
  int losses = 0;

  bool sound = true;
  bool music = true;
  bool vibration = true;
  String theme = 'NEON';
  String language = 'pt';

  // Desafios diários
  int dailyWins = 0; // progresso de vitórias no dia

  // Símbolos
  Player currentPlayer = Player.human; // usado durante partida
  List<String> board = List.filled(9, '');
  String? winner;
  bool isDraw = false;
  List<int>? winLine;

  void resetGame() {
    board = List.filled(9, '');
    winner = null;
    isDraw = false;
    winLine = null;
    currentPlayer = Player.human;
    notifyListeners();
  }

  // Retorna o símbolo na posição
  String symbolFor(Player p) => p == Player.human ? 'X' : 'O';

  void recordWin() {
    wins++;
    totalGames++;
    dailyWins++;
    playerScore++;
    notifyListeners();
  }

  void recordLoss() {
    losses++;
    totalGames++;
    aiScore++;
    notifyListeners();
  }

  void recordTie() {
    ties++;
    totalGames++;
    notifyListeners();
  }
}
