import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../services/ad_service.dart';
import '../services/nakama_service.dart';
import '../theme.dart';
import '../i18n/strings.dart';
import 'game_widgets.dart';
import 'menu_screen.dart';
import '../widgets.dart' as w;

class OnlineGameScreen extends StatefulWidget {
  final String? matchId;
  final bool isHost;

  /// When true, skip the "waiting for opponent" state (used when the host is
  /// redirected into the game because the guest has already joined).
  final bool startNow;

  const OnlineGameScreen({
    super.key,
    this.matchId,
    this.isHost = false,
    this.startNow = false,
  });

  @override
  State<OnlineGameScreen> createState() => _OnlineGameScreenState();
}

class _OnlineGameScreenState extends State<OnlineGameScreen> {
  final NakamaService _nakama = NakamaService();

  late List<String> _board;
  late String _mySymbol;
  late String _opponentSymbol;
  late bool _isMyTurn;
  String? _winner;
  bool _isDraw = false;
  List<int>? _winLine;
  bool _waitingForOpponent = true;
  bool _opponentLeft = false;
  bool _waitingRematch = false;
  int _moveCount = 0;
  bool _resultRecorded = false;

  /// 0-based index of the current game. Determines who plays X (starts).
  /// Game 0 (first): host starts. Game 1: guest starts. And so on, alternating.
  int _gameIndex = 0;

  /// Rematch coordination: whether we already sent our "ready".
  bool _rematchSent = false;
  /// Whether the opponent already sent their "ready".
  bool _opponentReady = false;

  int _myScore = 0;
  int _opponentScore = 0;

  StreamSubscription<int>? _moveSubscription;
  StreamSubscription<bool>? _rematchSubscription;
  StreamSubscription<MatchEvent>? _matchEventSubscription;
  final AudioPlayer _player = AudioPlayer();

  static const _winLines = [
    [0, 1, 2], [3, 4, 5], [6, 7, 8],
    [0, 3, 6], [1, 4, 7], [2, 5, 8],
    [0, 4, 8], [2, 4, 6],
  ];

  /// Whether this player plays X (starts) in the current game.
  /// Alternates every game: first game → host starts, then guest, etc.
  bool _iStartThisGame() {
    // In the first game (index 0) the host (X) starts.
    // Each subsequent game the starting player alternates.
    return widget.isHost == ((_gameIndex % 2) == 0);
  }

  @override
  void initState() {
    super.initState();
    _startGame();
    _listenToMoves();
  }

  void _startGame() {
    _board = List.filled(9, '');
    _winner = null;
    _isDraw = false;
    _winLine = null;
    _moveCount = 0;
    _resultRecorded = false;
    _rematchSent = false;
    _opponentReady = false;
    _waitingRematch = false;

    final iStart = _iStartThisGame();
    _mySymbol = iStart ? 'X' : 'O';
    _opponentSymbol = iStart ? 'O' : 'X';
    _isMyTurn = iStart;
    _waitingForOpponent = widget.isHost && !widget.startNow && _gameIndex == 0;
  }

  @override
  void dispose() {
    _moveSubscription?.cancel();
    _rematchSubscription?.cancel();
    _matchEventSubscription?.cancel();
    _player.dispose();
    _nakama.leaveMatch();
    super.dispose();
  }

  void _listenToMoves() {
    _moveSubscription = _nakama.moveStream.listen((position) {
      if (!mounted) return;
      _applyOpponentMove(position);
    });

    _rematchSubscription = _nakama.rematchStream.listen((ready) {
      if (!mounted) return;
      _opponentReady = true;
      if (_winner != null || _isDraw) {
        _beginNextGame();
      }
    });

    _matchEventSubscription = _nakama.matchEventStream.listen((event) {
      if (!mounted) return;
      if (event.type == MatchEventType.matchStarted) {
        setState(() {
          _waitingForOpponent = false;
        });
      } else if (event.type == MatchEventType.matchFound) {
        // Quick match: matchmaking already determined host/guest via join order.
        _waitingForOpponent = false;
      } else if (event.type == MatchEventType.matchEnded ||
          event.type == MatchEventType.playerLeft) {
        setState(() {
          _opponentLeft = true;
        });
      }
    });
  }

  void _beginNextGame() {
    // Only advance when BOTH players requested a rematch.
    if (!_rematchSent || !_opponentReady) return;
    setState(() {
      _gameIndex++;
      _startGame();
    });
  }

  void _applyOpponentMove(int position) {
    if (position < 0 || position > 8) return;
    if (_board[position] != '') return;
    if (_winner != null || _isDraw) return;

    setState(() {
      _board[position] = _opponentSymbol;
      _moveCount++;
      _isMyTurn = true;
      _checkResult();
    });
  }

  void _onCellTap(int index) {
    if (_board[index] != '' || _winner != null || _isDraw) return;
    if (!_isMyTurn) return;
    if (_waitingForOpponent) return;

    setState(() {
      _board[index] = _mySymbol;
      _moveCount++;
      _isMyTurn = false;
      _checkResult();
    });

    _vibrate();
    _playSfx('move');
    _nakama.sendMove(index);
  }

  void _playSfx(String asset) {
    final s = context.read<GameState>();
    if (!s.sound) return;
    _player.stop();
    _player.play(AssetSource(asset));
  }

  void _vibrate() {
    final s = context.read<GameState>();
    if (!s.vibration) return;
    HapticFeedback.lightImpact();
  }

  void _checkResult() {
    final line = _findWinLine(_board);
    if (line != null) {
      _winLine = line;
      _winner = _board[line[0]];
      if (_winner == _mySymbol) {
        _myScore++;
      } else {
        _opponentScore++;
      }
      _recordOutcome();
    } else if (_moveCount == 9) {
      _isDraw = true;
      _recordOutcome();
    }
  }

  /// Registra o resultado da partida online no placar e nos desafios.
  void _recordOutcome() {
    if (_resultRecorded) return;
    _resultRecorded = true;
    final s = context.read<GameState>();
    s.recordOnlineMatch();
    if (_winner == _mySymbol) {
      s.recordWin();
      s.addDiamonds(5);
    } else if (_winner != null) {
      s.recordLoss();
    } else if (_isDraw) {
      s.recordTie();
    }
  }

  List<int>? _findWinLine(List<String> board) {
    for (final line in _winLines) {
      final [a, b, c] = line;
      if (board[a] != '' && board[a] == board[b] && board[b] == board[c]) {
        return line;
      }
    }
    return null;
  }

  /// Derived from game state so it always reflects the current language.
  String _statusText() {
    if (_opponentLeft) return L.t('opponentDisconnected');
    if (_waitingForOpponent) {
      return widget.isHost ? L.t('waitingOpponent') : L.t('waitingHost');
    }
    if (_winner != null) {
      return _winner == _mySymbol ? L.t('youWin') : L.t('youLose');
    }
    if (_isDraw) return L.t('draw');
    if (_waitingRematch) return L.t('waitingOpponent');
    return _isMyTurn ? L.t('yourTurn') : L.t('opponentTurn');
  }

  bool get _isMyTurnAndReady =>
      _isMyTurn &&
      !_waitingForOpponent &&
      !_opponentLeft &&
      _winner == null &&
      !_isDraw;

  void _playAgain() {
    if (_rematchSent) return;
    _rematchSent = true;
    AdService.instance.maybeShowInterstitial(
      context.read<GameState>().totalGames,
    );

    // If the opponent already sent their ready (both tapped ready), start now.
    setState(() {
      if (_opponentReady) {
        _gameIndex++;
        _startGame();
      } else {
        _waitingRematch = true;
      }
    });
    _nakama.sendRematch();
  }

  void _goMenu() {
    AdService.instance.maybeShowInterstitial(
      context.read<GameState>().totalGames,
    );
    _nakama.leaveMatch();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MenuScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<GameState>();
    L.lang = s.language;
    return Scaffold(
      body: Stack(
        children: [
          w.ParticleLayer(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          BackButton(
                            color: Colors.white,
                            onPressed: _goMenu,
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _waitingForOpponent
                                  ? AppColors.dourado.withValues(alpha: 0.2)
                                  : AppColors.verde.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _waitingForOpponent
                                    ? AppColors.dourado
                                    : AppColors.verde,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _waitingForOpponent
                                      ? Icons.hourglass_top
                                      : Icons.circle,
                                  color: _waitingForOpponent
                                      ? AppColors.dourado
                                      : AppColors.verde,
                                  size: 10,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _waitingForOpponent
                                      ? L.t('waitingShort')
                                      : L.t('onlineStatus'),
                                  style: TextStyle(
                                    color: _waitingForOpponent
                                        ? AppColors.dourado
                                        : AppColors.verde,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ScoreBoard(
                        humanSym: _mySymbol,
                        aiSym: _opponentSymbol,
                        humanScore: _myScore,
                        aiScore: _opponentScore,
                        aiLabel: L.t('opponent'),
                      ),
                      const SizedBox(height: 14),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: _buildStatus(),
                      ),
                      const SizedBox(height: 18),
                      Center(
                        child: Board3x3(
                          board: _board,
                          winLine: _winLine,
                          enabled: _isMyTurnAndReady,
                          onTap: _onCellTap,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_opponentLeft)
            _buildOpponentLeftOverlay()
          else if (_winner != null || _isDraw)
            _buildResultOverlay(),
        ],
      ),
    );
  }

  Widget _buildStatus() {
    final statusMessage = _statusText();
    Color color;
    if (_winner != null) {
      color = _winner == _mySymbol ? AppColors.ciano : AppColors.magenta;
    } else if (_isDraw) {
      color = AppColors.textoClaro;
    } else if (_isMyTurn) {
      color = AppColors.ciano;
    } else {
      color = AppColors.magenta;
    }

    final style = TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w800,
      letterSpacing: 2,
      color: color,
      shadows: [
        Shadow(color: color.withValues(alpha: 0.6), blurRadius: 14),
      ],
    );

    return Stack(
      children: [
        Text(
          statusMessage,
          style: style.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3
              ..color = color,
          ),
        ),
        Text(statusMessage, style: style),
      ],
    );
  }

  Widget _buildOpponentLeftOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.25),
              Colors.black.withValues(alpha: 0.55),
              Colors.black.withValues(alpha: 0.7),
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 90),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GameResultBanner(
                    mainText: L.t('opponentDisconnected'),
                    secondaryText: L.t('matchEnded'),
                    color: AppColors.magenta,
                    icon: Icons.link_off,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: w.NeonButton(
                      L.t('menu'),
                      _goMenu,
                      icon: Icons.menu,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultOverlay() {
    final String mainText;
    final String subText;
    Color color;
    IconData icon;

    if (_isDraw) {
      mainText = L.t('draw');
      subText = L.t('greatMatch');
      color = AppColors.textoClaro;
      icon = Icons.handshake;
    } else if (_winner == _mySymbol) {
      mainText = L.t('youWin');
      subText = L.t('congrats');
      color = AppColors.ciano;
      icon = Icons.emoji_events;
    } else {
      mainText = L.t('youLose');
      subText = L.t('tryAgain');
      color = AppColors.magenta;
      icon = Icons.smart_toy;
    }

    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.25),
              Colors.black.withValues(alpha: 0.55),
              Colors.black.withValues(alpha: 0.7),
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 90),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GameResultBanner(
                    mainText: mainText,
                    secondaryText: subText,
                    color: color,
                    icon: icon,
                  ),
                  const SizedBox(height: 24),
                  PlayAgainButton(
                    _rematchSent && !_opponentReady
                        ? L.t('waitingOpponent')
                        : L.t('playAgain'),
                    onTap: _playAgain,
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _goMenu,
                    icon: const Icon(Icons.menu, color: Colors.white, size: 18),
                    label: Text(
                      L.t('menu'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _smallBtn(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.azulNeon, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Color(0x4400AFFF),
              blurRadius: 10,
              spreadRadius: -2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
