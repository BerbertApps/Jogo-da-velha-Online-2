import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:nakama/nakama.dart';

/// Service that manages the Nakama connection, authentication,
/// matchmaking, and real-time game communication.
class NakamaService {
  static final NakamaService _instance = NakamaService._();
  factory NakamaService() => _instance;
  NakamaService._();

  NakamaBaseClient? _client;
  NakamaWebsocketClient? _socket;
  Session? _session;

  String? _currentMatchId;
  String? _matchmakerTicket;

  // Online lobby (player count): authoritative lobby singleton + this client.
  String? _lobbyMatchId;
  int _lobbyCount = 0;

  // Connection state
  bool get isConnected => _socket != null;
  bool get isAuthenticated => _session != null;

  // Incoming opponent move stream (relayed match, opCode 1)
  final _moveController = StreamController<int>.broadcast();
  Stream<int> get moveStream => _moveController.stream;

  // Incoming opponent rematch-ready signal (relayed match, opCode 3)
  final _rematchController = StreamController<bool>.broadcast();
  Stream<bool> get rematchStream => _rematchController.stream;

  // Match events
  final _matchEventController = StreamController<MatchEvent>.broadcast();
  Stream<MatchEvent> get matchEventStream => _matchEventController.stream;

  // Connection status
  final _connectionController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStream => _connectionController.stream;

  // Number of connected/online players (lobby presence count)
  final _onlineCountController = StreamController<int>.broadcast();
  Stream<int> get onlineCountStream => _onlineCountController.stream;

  /// Connect to Nakama server
  Future<void> connect({
    String host = '127.0.0.1',
    bool ssl = false,
    int httpPort = 7350,
    int grpcPort = 7349,
    String serverKey = 'defaultkey',
  }) async {
    try {
      _client = getNakamaClient(
        host: host,
        ssl: ssl,
        serverKey: serverKey,
        httpPort: httpPort,
        grpcPort: grpcPort,
      );

      // Authenticate with device ID (no login required)
      final deviceId = await _getOrCreateDeviceId();
      _session = await _client!.authenticateDevice(deviceId: deviceId);

      print('Nakama authenticated: ${_session!.userId}');

      // Connect WebSocket for realtime
      _socket = NakamaWebsocketClient.init(
        host: host,
        ssl: ssl,
        token: _session!.token,
      );

      // Listen for match data
      _socket!.onMatchData.listen(_onMatchData);

      // Listen for matchmaker matched
      _socket!.onMatchmakerMatched.listen(_onMatchmakerMatched);

      // Listen for match presence (join/leave)
      _socket!.onMatchPresence.listen(_onMatchPresence);

      _connectionController.add(true);
      print('Nakama connected successfully');
    } catch (e) {
      print('Nakama connection error: $e');
      _connectionController.add(false);
      rethrow;
    }
  }

  /// Disconnect from Nakama
  Future<void> disconnect() async {
    await _socket?.close();
    _socket = null;
    _session = null;
    _client = null;
    _connectionController.add(false);
  }

  /// Create a private match and return the match ID
  Future<String> createPrivateMatch() async {
    if (_socket == null) throw Exception('Not connected');

    final match = await _socket!.createMatch();
    _currentMatchId = match.matchId;

    print('Created match: ${match.matchId}');
    return match.matchId;
  }

  /// Join a match by ID
  Future<void> joinMatch(String matchId) async {
    if (_socket == null) throw Exception('Not connected');

    await _socket!.joinMatch(matchId);
    _currentMatchId = matchId;
    print('Joined match: $matchId');
  }

  /// Join the matchmaking pool (quick match)
  Future<void> joinMatchmaker() async {
    if (_socket == null) throw Exception('Not connected');

    final ticket = await _socket!.addMatchmaker(
      minCount: 2,
      maxCount: 2,
      query: '+properties.mode:tictactoe',
      stringProperties: {
        'mode': 'tictactoe',
      },
    );

    _matchmakerTicket = ticket.ticket;
    print('Joined matchmaking pool, ticket: ${ticket.ticket}');
  }

  /// Cancel matchmaking
  Future<void> cancelMatchmaker() async {
    if (_socket == null || _matchmakerTicket == null) return;
    await _socket!.removeMatchmaker(_matchmakerTicket!);
    _matchmakerTicket = null;
    print('Cancelled matchmaking');
  }

  /// Join the shared online lobby (used to count "online players").
  Future<void> joinOnlineLobby() async {
    if (_socket == null) throw Exception('Not connected');
    if (_lobbyMatchId != null) return;

    final rpc = await _socket!.rpc(id: 'create_online_lobby');
    final data = (rpc.payload == null || rpc.payload!.isEmpty)
        ? <String, dynamic>{}
        : (jsonDecode(rpc.payload!) as Map<String, dynamic>);
    final matchId = data['matchId'] as String?;
    if (matchId == null || matchId.isEmpty) {
      throw Exception('Lobby indisponível');
    }

    await _socket!.joinMatch(matchId);
    _lobbyMatchId = matchId;
    _lobbyCount = 1;
    _onlineCountController.add(_lobbyCount);
    print('Online lobby joined: $matchId');
  }

  /// Leave the shared online lobby.
  Future<void> leaveOnlineLobby() async {
    if (_lobbyMatchId != null && _socket != null) {
      await _socket!.leaveMatch(_lobbyMatchId!);
    }
    _lobbyMatchId = null;
    _lobbyCount = 0;
    _onlineCountController.add(0);
    print('Left online lobby');
  }

  /// Send a move to the server
  void sendMove(int position) {
    if (_socket == null || _currentMatchId == null) {
      throw Exception('Not connected');
    }

    final data = jsonEncode({'position': position});

    // Send as match data (opCode 1 = move)
    _socket!.sendMatchData(
      matchId: _currentMatchId!,
      opCode: 1,
      data: utf8.encode(data),
    );

    print('Sent move: position $position');
  }

  /// Send a "ready for next game" (rematch) signal to the opponent.
  void sendRematch() {
    if (_socket == null || _currentMatchId == null) return;
    _socket!.sendMatchData(
      matchId: _currentMatchId!,
      opCode: 3,
      data: utf8.encode(jsonEncode({'rematch': true})),
    );
    print('Sent rematch ready');
  }

  /// Leave the current match
  Future<void> leaveMatch() async {
    if (_currentMatchId != null && _socket != null) {
      await _socket!.leaveMatch(_currentMatchId!);
      print('Left match: $_currentMatchId');
      _currentMatchId = null;
    }
  }

  // --- Private members ---

  void _onMatchData(MatchData event) {
    // Only handle data from the match we are currently playing in.
    if (_currentMatchId != null &&
        event.matchId != null &&
        event.matchId != _currentMatchId) {
      return;
    }
    // Ignore the echo of our own messages (relayed matches re-deliver to sender).
    if (event.presence?.userId == _session?.userId) return;
    if (event.data == null) return;

    final decoded = utf8.decode(event.data!);
    switch (event.opCode) {
      // Opponent's move
      case 1:
        try {
          final data = jsonDecode(decoded);
          final position = data['position'];
          if (position is int) {
            _moveController.add(position);
          }
        } catch (e) {
          print('Error parsing move data: $e');
        }
        break;
      // Opponent is ready for the next game (rematch)
      case 3:
        _rematchController.add(true);
        break;
      default:
        break;
    }
  }

  void _onMatchmakerMatched(MatchmakerMatched event) {
    // The server does NOT include match_id in the matchmaker_matched event;
    // the match id is carried inside the token (JWT `mid` claim).
    final matchId = event.matchId ?? _matchIdFromToken(event.token ?? '');
    if (matchId == null) {
      print('Matchmaker matched but could not derive match id');
      return;
    }

    print('Matchmaker matched! Match ID: $matchId');
    _currentMatchId = matchId;

    // Deterministically decide who plays X (host) for quick matches.
    // The server may order the participants differently for each client, so
    // use a rule both players can agree on: the LOWEST user id is X/starts.
    // (Same comparison runs on both devices → same result.)
    final opponentId = event.users.isNotEmpty
        ? event.users.first.presence?.userId
        : null;
    final myId = _session?.userId ?? '';
    if (opponentId == null || opponentId.isEmpty) {
      _quickMatchIsHost = true;
    } else {
      _quickMatchIsHost = myId.compareTo(opponentId) < 0;
    }
    print('Quick-match host role: $_quickMatchIsHost (me=$myId, opp=$opponentId)');

    // Join the matched game with the token from matchmaker
    _socket!.joinMatch(matchId, token: event.token).then((_) {
      _matchEventController.add(MatchEvent(
        type: MatchEventType.matchFound,
        matchId: matchId,
        isHost: _quickMatchIsHost,
      ));
    });
  }

  /// Extract the match id from a matchmaker token (JWT payload `mid` claim).
  String? _matchIdFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length < 2) return null;
      final payload = base64Url.normalize(parts[1]);
      final decoded = jsonDecode(utf8.decode(base64Url.decode(payload)));
      if (decoded is Map<String, dynamic>) {
        final mid = decoded['mid'];
        if (mid is String && mid.isNotEmpty) return mid;
      }
    } catch (e) {
      print('Error decoding match token: $e');
    }
    return null;
  }

  /// Whether the current user is X (host) in the last quick-match; null for rooms.
  bool _quickMatchIsHost = false;
  bool get quickMatchIsHost => _quickMatchIsHost;

  void _onMatchPresence(MatchPresenceEvent event) {
    final isLobby =
        event.matchId != null && event.matchId == _lobbyMatchId;

    var lobbyDelta = 0;
    for (final p in event.joins) {
      if (p.userId == _session?.userId) continue;
      lobbyDelta++;
      if (!isLobby) {
        print('Opponent joined: ${p.userId}');
        _matchEventController.add(MatchEvent(
          type: MatchEventType.matchStarted,
          matchId: event.matchId,
        ));
      }
    }
    for (final p in event.leaves) {
      if (p.userId == _session?.userId) continue;
      lobbyDelta--;
      if (!isLobby) {
        print('Opponent left: ${p.userId}');
        _matchEventController.add(MatchEvent(
          type: MatchEventType.matchEnded,
          matchId: event.matchId,
          message: 'Oponente não está mais conectado',
        ));
      }
    }

    if (isLobby) {
      _lobbyCount += lobbyDelta;
      if (_lobbyCount < 1) _lobbyCount = 1;
      _onlineCountController.add(_lobbyCount);
      print('Online lobby count: $_lobbyCount');
    }
  }

  /// Get or create a persistent device ID
  Future<String> _getOrCreateDeviceId() async {
    final random = Random();
    final id =
        'device_${random.nextInt(999999999).toString().padLeft(9, '0')}';
    return id;
  }

  /// Get the current user ID
  String? get userId => _session?.userId;

  /// Get the current match ID
  String? get currentMatchId => _currentMatchId;

  /// Set current match ID (used when creating/joining private matches)
  void setCurrentMatchId(String matchId) {
    _currentMatchId = matchId;
  }

  /// Dispose resources
  void dispose() {
    _moveController.close();
    _rematchController.close();
    _matchEventController.close();
    _connectionController.close();
    _onlineCountController.close();
    disconnect();
  }
}

/// Match event types
enum MatchEventType {
  matchFound,
  matchStarted,
  matchEnded,
  playerJoined,
  playerLeft,
}

/// Match event data
class MatchEvent {
  final MatchEventType type;
  final String? matchId;
  final String? message;
  final bool? isHost;

  MatchEvent({
    required this.type,
    this.matchId,
    this.message,
    this.isHost,
  });
}
