import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'avatars.dart';
import 'player_record.dart';

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

  // Perfil do jogador
  String playerName = '';
  String avatar = '';
  int diamonds = 0;
  List<PlayerRecord> players = [];

  // Desafios diários (resetam à meia-noite)
  int dailyWins = 0;
  int dailyDraws = 0;
  int dailyOnlineGames = 0;
  String lastChallengeDay = '';
  Set<String> claimedChallenges = {};

  // Símbolos
  Player currentPlayer = Player.human; // usado durante partida
  List<String> board = List.filled(9, '');
  String? winner;
  bool isDraw = false;
  List<int>? winLine;

  // --- Persistência ---

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    playerName = _prefs!.getString('playerName') ?? '';
    avatar = _prefs!.getString('playerAvatar') ?? '';
    diamonds = _prefs!.getInt('diamonds') ?? 0;
    players = _decodePlayers(_prefs!.getString('players'));
    wins = _prefs!.getInt('wins') ?? 0;
    losses = _prefs!.getInt('losses') ?? 0;
    ties = _prefs!.getInt('ties') ?? 0;
    totalGames = _prefs!.getInt('totalGames') ?? 0;
    dailyWins = _prefs!.getInt('dailyWins') ?? 0;
    dailyDraws = _prefs!.getInt('dailyDraws') ?? 0;
    dailyOnlineGames = _prefs!.getInt('dailyOnlineGames') ?? 0;
    lastChallengeDay = _prefs!.getString('lastChallengeDay') ?? '';
    claimedChallenges = (_prefs!.getStringList('claimedChallenges') ??
            const <String>[])
        .toSet();
    sound = _prefs!.getBool('sound') ?? true;
    music = _prefs!.getBool('music') ?? true;
    vibration = _prefs!.getBool('vibration') ?? true;
    theme = _prefs!.getString('theme') ?? 'NEON';
    language = _prefs!.getString('language') ?? 'pt';

    // Foto aleatória até o jogador escolher.
    if (avatar.startsWith('http') || avatar == '' || !kAvatars.contains(avatar)) {
      avatar = randomAvatar();
      _save();
    }
    _ensureDailyReset();
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('playerName', playerName);
    await p.setString('playerAvatar', avatar);
    await p.setInt('diamonds', diamonds);
    await p.setString('players', jsonEncode(players.map((e) => e.toJson()).toList()));
    await p.setInt('wins', wins);
    await p.setInt('losses', losses);
    await p.setInt('ties', ties);
    await p.setInt('totalGames', totalGames);
    await p.setInt('dailyWins', dailyWins);
    await p.setInt('dailyDraws', dailyDraws);
    await p.setInt('dailyOnlineGames', dailyOnlineGames);
    await p.setString('lastChallengeDay', lastChallengeDay);
    await p.setStringList('claimedChallenges', claimedChallenges.toList());
  }

  List<PlayerRecord> _decodePlayers(String? s) {
    if (s == null || s.isEmpty) return [];
    try {
      final list = jsonDecode(s) as List;
      return list
          .map((e) => PlayerRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Recalcula o ranking local com o perfil atual atualizado.
  void _updateSelfRecord() {
    final selfIdx = players.indexWhere((p) => p.isSelf);
    final self = PlayerRecord(
      name: playerName.isEmpty ? 'Jogador' : playerName,
      avatar: avatar,
      isSelf: true,
      wins: wins,
      losses: losses,
      ties: ties,
      diamonds: diamonds,
    );
    if (selfIdx >= 0) {
      players[selfIdx] = self;
    } else {
      players.insert(0, self);
    }
    players.sort((a, b) {
      final byScore = b.wins.compareTo(a.wins);
      if (byScore != 0) return byScore;
      return b.diamonds.compareTo(a.diamonds);
    });
  }

  // --- Perfil ---

  void updateProfile({String? name, String? setAvatar, bool random = false}) {
    if (name != null && name.trim().isNotEmpty) playerName = name.trim();
    if (random) {
      avatar = randomAvatar();
    } else if (setAvatar != null && kAvatars.contains(setAvatar)) {
      avatar = setAvatar;
    }
    _updateSelfRecord();
    _save();
    notifyListeners();
  }

  // --- Diamantes ---

  void addDiamonds(int amount) {
    diamonds += amount;
    _updateSelfRecord();
    _save();
    notifyListeners();
  }

  // --- Desafios diários ---

  void _ensureDailyReset() {
    final today = _todayKey();
    if (lastChallengeDay != today) {
      lastChallengeDay = today;
      dailyWins = 0;
      dailyDraws = 0;
      dailyOnlineGames = 0;
      claimedChallenges = {};
      _save();
    }
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  /// Chama durante as telas para zerar os desafios ao virar o dia.
  void checkDailyReset() {
    _ensureDailyReset();
    notifyListeners();
  }

  bool isChallengeClaimed(String id) => claimedChallenges.contains(id);

  void claimChallenge(String id, int reward) {
    _ensureDailyReset();
    if (claimedChallenges.contains(id)) return;
    claimedChallenges.add(id);
    diamonds += reward;
    _updateSelfRecord();
    _save();
    notifyListeners();
  }

  void recordOnlineMatch() {
    _ensureDailyReset();
    dailyOnlineGames++;
    _save();
    notifyListeners();
  }

  /// Salva as preferências de configuração (som, música, vibração, tema, idioma).
  Future<void> saveSettings() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('sound', sound);
    await p.setBool('music', music);
    await p.setBool('vibration', vibration);
    await p.setString('theme', theme);
    await p.setString('language', language);
  }

  void resetProgress() {
    playerScore = 0;
    aiScore = 0;
    ties = 0;
    totalGames = 0;
    wins = 0;
    losses = 0;
    diamonds = 0;
    dailyWins = 0;
    dailyDraws = 0;
    dailyOnlineGames = 0;
    claimedChallenges = {};
    players = [];
    _save();
    notifyListeners();
  }

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
    _updateSelfRecord();
    _save();
    notifyListeners();
  }

  void recordLoss() {
    losses++;
    totalGames++;
    aiScore++;
    _save();
    notifyListeners();
  }

  void recordTie() {
    ties++;
    totalGames++;
    dailyDraws++;
    _save();
    notifyListeners();
  }
}