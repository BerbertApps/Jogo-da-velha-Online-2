import 'dart:async';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/ai.dart';
import '../models/game_state.dart';
import '../services/ad_service.dart';
import '../theme.dart';
import '../i18n/strings.dart';
import 'game_widgets.dart';
import 'menu_screen.dart';
import '../widgets.dart' as w;

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  final Random _r = Random();
  static const _winLines = [
    [0, 1, 2], [3, 4, 5], [6, 7, 8],
    [0, 3, 6], [1, 4, 7], [2, 5, 8],
    [0, 4, 8], [2, 4, 6],
  ];

  late List<String> _board;
  late String _current; // quem joga agora
  late String _humanSym;
  late String _aiSym;
  String? _winner;
  bool _isDraw = false;
  List<int>? _winLine;
  bool _isThinking = false;

  int _humanScore = 0;
  int _aiScore = 0;

  /// 0-based round index. In vs-AI the starter alternates each round:
  /// round 0 → human (X), round 1 → AI (X), round 2 → human... and so on.
  int _gameIndex = 0;

  List<List<String>> _history = [];
  late GameMode _mode;

  late ConfettiController _confetti;
  final AudioPlayer _player = AudioPlayer();
  Timer? _aiTimer;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 3));
    _mode = context.read<GameState>().mode;
    _resetBoard();
  }

  @override
  void dispose() {
    _aiTimer?.cancel();
    _player.dispose();
    _confetti.dispose();
    super.dispose();
  }

  Future<void> _playSfx(String asset) async {
    final s = context.read<GameState>();
    if (!s.sound) return;
    try {
      await _player.stop();
      await _player.play(AssetSource(asset));
    } catch (_) {}
  }

  Future<void> _playVictoryTone() async {
    final s = context.read<GameState>();
    if (!s.music) return;
    try {
      await _player.stop();
      await _player.play(AssetSource('win'));
    } catch (_) {}
  }

  void _vibrate() {
    final s = context.read<GameState>();
    if (!s.vibration) return;
    HapticFeedback.lightImpact();
  }

  void _resetBoard() {
    _aiTimer?.cancel();
    _aiTimer = null;
    setState(() {
      _board = List.filled(9, '');
      // vs-AI: alternate who starts each round. vs-friend always starts X.
      _humanSym = (_isVsAI && _gameIndex.isOdd) ? 'O' : 'X';
      _aiSym = _humanSym == 'X' ? 'O' : 'X';
      _current = _humanSym;
      _winner = null;
      _isDraw = false;
      _winLine = null;
      _isThinking = false;
      _history.clear();
    });
    if (_isVsAI && _aiSym == 'X') {
      // AI is X on odd rounds → it starts.
      _executeAI();
    }
  }

  void _nextRound() {
    AdService.instance.maybeShowInterstitial(
      context.read<GameState>().totalGames,
    );
    setState(() => _gameIndex++);
    _resetBoard();
  }

  bool get _isVsAI => _mode == GameMode.vsAI;

  void _onCellTap(int index) {
    if (_board[index] != '' || _winner != null || _isDraw) return;
    if (_isVsAI && _current == _aiSym) return;

    _history.add(List.of(_board));

    final humanSym = _current;
    _place(index, _current);

    if (_isVsAI) {
      // IA responde depois
      if (_winner == null && !_isDraw) {
        _executeAI();
      }
    }
  }

  void _executeAI() {
    _isThinking = true;
    setState(() {});
    _aiTimer?.cancel();
    _aiTimer = Timer(const Duration(milliseconds: 550), () {
      _aiTimer = null;
      if (!mounted) return;
      final d = context.read<GameState>().difficulty;
      final move = AI.bestMove(_board, d, ai: _aiSym, human: _humanSym);
      setState(() => _isThinking = false);
      if (move != null) {
        _place(move, _aiSym);
      } else {
        // Fallback: never leave the turn "stuck" on the AI.
        setState(() => _current = _humanSym);
      }
    });
  }

  void _place(int index, String symbol) {
    setState(() {
      _board[index] = symbol;
      // Turn goes to the OTHER symbol than the one just placed.
      _current = (symbol == _humanSym) ? _aiSym : _humanSym;
    });
    _playSfx('move');
    if (symbol == _humanSym) _vibrate();

    final win = _checkWin();
    if (win != null) {
      setState(() {
        _winner = win;
        _winLine = _findWinLine(win);
      });
      _onFinish(win);
    } else if (!_board.contains('')) {
      setState(() => _isDraw = true);
      _onTie();
    }
  }

  String? _checkWin() {
    for (final c in _winLines) {
      if (_board[c[0]] != '' &&
          _board[c[0]] == _board[c[1]] &&
          _board[c[1]] == _board[c[2]]) {
        return _board[c[0]];
      }
    }
    return null;
  }

  List<int>? _findWinLine(String symbol) {
    for (final c in _winLines) {
      if (_board[c[0]] == symbol &&
          _board[c[1]] == symbol &&
          _board[c[2]] == symbol) {
        return c;
      }
    }
    return null;
  }

  void _onFinish(String win) {
    final state = context.read<GameState>();
    if (_isVsAI) {
      if (win == _humanSym) {
        state.recordWin();
      } else {
        state.recordLoss();
      }
    } else {
      state.recordWin(); // para modo amigo, conta como jogo
    }

    // Atualizar placar da sessão
    if (win == _humanSym) {
      _humanScore++;
    } else {
      _aiScore++;
    }
    setState(() {});

    if (win == _humanSym) {
      _confetti.play();
    }
    _playVictoryTone();
  }

  void _onTie() {
    context.read<GameState>().recordTie();
  }

  void _undo() {
    if (_history.isEmpty || _winner != null || _isDraw) return;
    _aiTimer?.cancel();
    _aiTimer = null;
    setState(() {
      _board = List.of(_history.removeLast());
      // After undoing, the (vs-AI) human is back on turn. In friend mode,
      // give the turn back to whoever made the last move.
      _current = _isVsAI
          ? _humanSym
          : (_current == _humanSym ? _aiSym : _humanSym);
      _isThinking = false;
    });
  }

  void _goMenu() {
    AdService.instance.maybeShowInterstitial(
      context.read<GameState>().totalGames,
    );
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MenuScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();
    L.lang = state.language;
    final aiLabel = state.mode == GameMode.vsFriend
        ? L.t('friendLabel')
        : L.t('masterTitle');

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
                            Icon(Icons.settings, color: AppColors.textoClaro),
                            const SizedBox(width: 8),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ScoreBoard(
                          humanSym: _humanSym,
                          aiSym: _aiSym,
                          humanScore: _humanScore,
                          aiScore: _aiScore,
                          aiLabel: aiLabel,
                        ),
                        const SizedBox(height: 14),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: _buildStatus(),
                        ),
                        const SizedBox(height: 18),
                        Center(child: _buildBoardWrap(state)),
                        const SizedBox(height: 18),
                        _buildBottomButtons(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
              ),
            ),
          ),
          // Confetes
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirection: -pi / 2,
              particleDrag: 0.05,
              gravity: 0.3,
              emissionFrequency: 0.05,
              numberOfParticles: 40,
              colors: [
                AppColors.ciano,
                AppColors.magenta,
                AppColors.dourado,
                Colors.white,
              ],
            ),
          ),
          // Resultado overlay
          if (_winner != null || _isDraw) _buildResultOverlay(),
        ],
      ),
    );
  }

  Widget _buildResultOverlay() {
    final state = context.read<GameState>();
    final String mainText;
    final String subText;
    Color color;
    IconData icon;

    if (_isDraw) {
      mainText = L.t('draw');
      subText = L.t('greatMatch');
      color = AppColors.textoClaro;
      icon = Icons.handshake;
    } else if (!_isVsAI) {
      mainText = L.fmt('playerWon', {'sym': '$_winner'});
      subText = L.t('congrats');
      color = _winner == _humanSym ? AppColors.ciano : AppColors.magenta;
      icon = Icons.emoji_events;
    } else if (_winner == _humanSym) {
      mainText = L.t('youWin');
      subText = L.t('goodMove');
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
                    L.t('playAgain'), 
                    onTap: _nextRound,
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

  Widget _buildStatus() {
    String text;
    Color color;
    if (_winner != null) {
      if (_isVsAI) {
        if (_winner == _humanSym) {
          text = L.t('youWin');
          color = AppColors.ciano;
        } else {
          text = L.t('youLose');
          color = AppColors.magenta;
        }
      } else {
        text = L.fmt('playerWon', {'sym': '$_winner'});
        color = _winner == _humanSym ? AppColors.ciano : AppColors.magenta;
      }
    } else if (_isDraw) {
      text = L.t('draw');
      color = AppColors.textoClaro;
    } else if (_isThinking) {
      text = L.t('aiThinking');
      color = AppColors.textoClaro;
    } else {
      final isHuman = _current == _humanSym;
      text = isHuman ? L.t('yourTurn') : (_isVsAI ? L.t('aiThinking') : L.t('yourTurn'));
      color = isHuman ? AppColors.ciano : AppColors.magenta;
    }

    // Texto com contorno (outline) neon + brilho.
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
        // Camada de contorno (stroke)
        Text(
          text,
          style: style.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3
              ..color = color,
          ),
        ),
        // Camada de preenchimento
        Text(text, style: style),
      ],
    );
  }

  Widget _buildBoardWrap(GameState state) {
    return Board3x3(
      board: _board,
      winLine: _winLine,
      enabled: _winner == null && !_isDraw && !_isThinking,
      onTap: _onCellTap,
    );
  }

  Widget _buildBottomButtons() {
    return Row(
      children: [
        Expanded(
          child: _smallBtn(Icons.undo, L.t('undo'), _undo),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _smallBtn(Icons.menu, L.t('menu'), _goMenu),
        ),
      ],
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
            BoxShadow(color: Color(0x4400AFFF), blurRadius: 10, spreadRadius: -2)
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
