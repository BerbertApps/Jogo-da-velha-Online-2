import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../services/nakama_service.dart';
import '../theme.dart';
import '../widgets.dart';
import '../i18n/strings.dart';
import 'online_game_screen.dart';

class OnlineScreen extends StatefulWidget {
  const OnlineScreen({super.key});

  @override
  State<OnlineScreen> createState() => _OnlineScreenState();
}

class _OnlineScreenState extends State<OnlineScreen> {
  final NakamaService _nakama = NakamaService();
  bool _connected = false;
  bool _searching = false;
  bool _connecting = false;
  int _onlineCount = 0;
  String? _createdMatchId;
  StreamSubscription? _connectionSub;
  StreamSubscription? _matchSub;
  StreamSubscription<int>? _onlineCountSub;

  @override
  void initState() {
    super.initState();
    _connectToServer();
    _connectionSub = _nakama.connectionStream.listen((connected) {
      if (mounted) setState(() => _connected = connected);
      if (connected) _ensureLobby();
    });
    _matchSub = _nakama.matchEventStream.listen(_handleMatchEvent);
    _onlineCountSub = _nakama.onlineCountStream.listen((count) {
      if (mounted) setState(() => _onlineCount = count);
    });
  }

  @override
  void dispose() {
    _connectionSub?.cancel();
    _matchSub?.cancel();
    _onlineCountSub?.cancel();
    _nakama.leaveOnlineLobby();
    super.dispose();
  }

  Future<void> _ensureLobby() async {
    try {
      await _nakama.joinOnlineLobby();
    } catch (e) {
      print('Lobby join failed: $e');
    }
  }

  void _handleMatchEvent(MatchEvent event) {
    if (!mounted) return;

    // Quick match: both players matched → go to game (host decided by server order).
    // startNow: in a quick match both players are already together, so nobody waits.
    if (event.type == MatchEventType.matchFound) {
      setState(() => _searching = false);
      _navigateToGame(
        event.matchId,
        quickMatchHost: event.isHost,
        startNow: true,
      );
      return;
    }

    // Room created by us: the moment the guest joins, redirect the host to the game.
    if (event.type == MatchEventType.matchStarted &&
        _createdMatchId != null &&
        event.matchId == _createdMatchId) {
      _navigateToGame(
        event.matchId,
        quickMatchHost: true,
        startNow: true,
      );
    }
  }

  Future<void> _connectToServer() async {
    if (_nakama.isConnected) {
      setState(() => _connected = true);
      _ensureLobby();
      return;
    }
    setState(() => _connecting = true);
    try {
      const useEmulatorLoopback = bool.fromEnvironment(
        'EMULATOR',
        defaultValue: false,
      );
      // Resolve the Nakama host:
      // 1. NAKAMA_HOST dart-define (physical device / remote) wins.
      // 2. EMULATOR=true → Android emulator loopback (10.0.2.2).
      // 3. Default → localhost for web/desktop.
      const nakamaHost = String.fromEnvironment('NAKAMA_HOST');
      final host = nakamaHost.isNotEmpty
          ? nakamaHost
          : (useEmulatorLoopback ? '10.0.2.2' : '127.0.0.1');
      await _nakama.connect(host: host);
      setState(() => _connected = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${L.t('connectError')}$e'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  // --- Matchmaking (Quick Match) ---
  Future<void> _startMatchmaking() async {
    if (!_connected) {
      _copyFeedback(context, L.t('connectFirst'));
      return;
    }
    setState(() => _searching = true);
    try {
      await _nakama.joinMatchmaker();
      _copyFeedback(context, L.t('searchingMsg'));
    } catch (e) {
      setState(() => _searching = false);
      _copyFeedback(context, '${L.t('searchError')}$e');
    }
  }

  void _cancelSearch() {
    _nakama.cancelMatchmaker();
    setState(() => _searching = false);
  }

  // --- Create Room ---
  Future<void> _createRoom() async {
    if (!_connected) {
      _copyFeedback(context, L.t('connectFirst'));
      return;
    }
    try {
      final matchId = await _nakama.createPrivateMatch();
      setState(() => _createdMatchId = matchId);
      _nakama.setCurrentMatchId(matchId);
      Clipboard.setData(ClipboardData(text: matchId));
      _copyFeedback(context, '${L.t('roomCreated')}$matchId');
    } catch (e) {
      _copyFeedback(context, '${L.t('createRoomError')}$e');
    }
  }

  // --- Join Room ---
  Future<void> _joinRoom() async {
    if (!_connected) {
      _copyFeedback(context, L.t('connectFirst'));
      return;
    }
    final controller = TextEditingController();
    final matchId = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.ciano),
        ),
        title: Text(
          L.t('joinRoom'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: TextField(
          controller: controller,
          autocorrect: false,
          textCapitalization: TextCapitalization.characters,
          style: const TextStyle(color: Colors.white, letterSpacing: 2),
          decoration: InputDecoration(
            hintText: L.t('roomCodeHint'),
            hintStyle: const TextStyle(color: AppColors.textoClaro),
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              L.t('cancel'),
              style: const TextStyle(color: AppColors.textoClaro),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(
              L.t('enter'),
              style: const TextStyle(color: AppColors.verde),
            ),
          ),
        ],
      ),
    );
    if (matchId == null || matchId.isEmpty) {
      if (matchId != null && matchId.isNotEmpty) {
        _copyFeedback(context, L.t('invalidCode'));
      }
      return;
    }
    try {
      _nakama.setCurrentMatchId(matchId);
      await _nakama.joinMatch(matchId);
      if (mounted) _navigateToGame(matchId);
    } catch (e) {
      _copyFeedback(context, '${L.t('joinRoomError')}$e');
    }
  }

  void _navigateToGame(String? matchId, {bool? quickMatchHost, bool startNow = false}) {
    if (!mounted) return;
    final isHost = quickMatchHost ?? (_createdMatchId == matchId);
    final s = context.read<GameState>();
    s.mode = GameMode.online;
    s.notifyListeners();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OnlineGameScreen(
          matchId: matchId,
          isHost: isHost,
          startNow: startNow,
        ),
      ),
    );
  }

  void _copyFeedback(BuildContext context, String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.bgCard,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<GameState>();
    L.lang = s.language;
    return Scaffold(
      body: ParticleLayer(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 12),
                ScreenHeader(title: L.t('playOnline')),
                const SizedBox(height: 8),
                // Connection status
                _buildConnectionStatus(),
                if (_connected) ...[
                  const SizedBox(height: 8),
                  _buildOnlineCountChip(),
                ],
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _largeTile(
                        context,
                        icon: Icons.public,
                        title: _searching
                            ? L.t('searching')
                            : L.t('quickMatch'),
                        desc: _searching
                            ? L.t('searchingDesc')
                            : L.t('quickMatchDesc'),
                        onTap: _searching ? _cancelSearch : _startMatchmaking,
                        highlighted: _searching,
                      ),
                      const SizedBox(height: 14),
                      _largeTile(
                        context,
                        icon: Icons.people,
                        title: L.t('createRoom'),
                        desc: L.t('createRoomDesc'),
                        onTap: _createRoom,
                      ),
                      const SizedBox(height: 14),
                      _largeTile(
                        context,
                        icon: Icons.login,
                        title: L.t('joinRoom'),
                        desc: L.t('joinRoomDesc'),
                        onTap: _joinRoom,
                      ),
                      if (_createdMatchId != null) ...[
                        const SizedBox(height: 28),
                        NeonCard(
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.verified_user,
                                  color: AppColors.verde,
                                  size: 30,
                                ),
                                const SizedBox(height: 10),
                                SelectableText(
                                  _createdMatchId!,
                                  style: const TextStyle(
                                    color: AppColors.ciano,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 4,
                                    shadows: [
                                      Shadow(
                                        color: AppColors.ciano,
                                        blurRadius: 16,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  L.t('shareWithFriends'),
                                  style: const TextStyle(
                                    color: AppColors.textoClaro,
                                    fontSize: 13,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                NeonButton(
                                  L.t('copyCode'),
                                  () {
                                    Clipboard.setData(
                                      ClipboardData(text: _createdMatchId!),
                                    );
                                    _copyFeedback(
                                      context,
                                      L.t('codeCopied'),
                                    );
                                  },
                                  height: 44,
                                  fontSize: 14,
                                  startColor: AppColors.ciano,
                                  endColor: AppColors.roxo,
                                ),
                              ],
                            ),
                          ),
                          borderColor: AppColors.magenta,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionStatus() {
    if (_connecting) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.dourado.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.dourado, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.dourado,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              L.t('connectServer'),
              style: const TextStyle(
                color: AppColors.dourado,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      );
    }

    final color = _connected ? AppColors.verde : Colors.red.shade400;
    final text = _connected ? L.t('connected') : L.t('disconnected');
    final icon = _connected ? Icons.wifi : Icons.wifi_off;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineCountChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.ciano.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.ciano, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people, color: AppColors.ciano, size: 14),
          const SizedBox(width: 8),
          Text(
            _onlineCount > 0
                ? L.fmt('onlinePlayers', {'n': '$_onlineCount'})
                : L.t('connectingLobby'),
            style: TextStyle(
              color: _onlineCount > 0
                  ? AppColors.ciano
                  : AppColors.textoClaro,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _largeTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String desc,
    VoidCallback? onTap,
    bool highlighted = false,
  }) {
    return GestureDetector(
      onTap: onTap ?? () {},
      child: NeonCard(
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              NeonIconTile(
                Icon(
                  icon,
                  color: highlighted ? AppColors.magenta : AppColors.ciano,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: highlighted
                            ? AppColors.magenta
                            : Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      desc,
                      style: const TextStyle(
                        color: AppColors.textoClaro,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.textoClaro),
            ],
          ),
        ),
        highlighted: highlighted,
      ),
    );
  }
}
