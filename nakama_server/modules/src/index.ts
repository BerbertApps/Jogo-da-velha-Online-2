const moduleName = "tictactoe";
const lobbyModuleName = "lobby";

interface LobbyState {
  occupants: number;
}

const WIN_LINES = [
  [0, 1, 2], [3, 4, 5], [6, 7, 8],
  [0, 3, 6], [1, 4, 7], [2, 5, 8],
  [0, 4, 8], [2, 4, 6],
];

const MAX_PLAYERS = 2;
const OP_CODE_MOVE = 1;
const OP_CODE_STATE = 2;

interface PlayerState {
  sessionId: string;
  userId: string;
  symbol: "X" | "O";
}

interface TicTacToeState {
  board: string[];
  players: PlayerState[];
  currentTurnSessionId: string;
  winner: string | null;
  gameOver: boolean;
}

function InitModule(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, initializer: nkruntime.Initializer) {
  initializer.registerMatch(moduleName, {
    matchInit,
    matchJoinAttempt,
    matchJoin,
    matchLeave,
    matchLoop,
    matchTerminate,
    matchSignal,
  });

  initializer.registerMatch(lobbyModuleName, {
    matchInit: lobbyMatchInit,
    matchJoinAttempt: lobbyMatchJoinAttempt,
    matchJoin: lobbyMatchJoin,
    matchLeave: lobbyMatchLeave,
    matchLoop: lobbyMatchLoop,
    matchTerminate: lobbyMatchTerminate,
    matchSignal: lobbyMatchSignal,
  });

  initializer.registerRpc("create_tictactoe_match", rpcCreateMatch);
  initializer.registerRpc("create_online_lobby", rpcCreateLobby);

  logger.info("Tic-Tac-Toe match handler loaded.");
}

let lobbyMatchId: string | null = null;

// Persist the shared lobby id in Nakama storage so all RPC invocations
// resolve the exact same match (JS runtime globals do not survive across
// RPC call contexts).
const LOBBY_COLLECTION = "nakama_lobby";
const LOBBY_KEY = "match";
// Nakama "system" user id used for server-side storage.
const SYSTEM_USER = "00000000-0000-0000-0000-000000000000";

function rpcCreateMatch(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
  const matchId = nk.matchCreate(moduleName, {});
  logger.info("Created authoritative tictactoe match: %s", matchId);
  return JSON.stringify({ matchId });
}

function rpcCreateLobby(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
  const key = { collection: LOBBY_COLLECTION, key: LOBBY_KEY, userId: SYSTEM_USER };
  const stored = nk.storageRead([key]);
  if (stored && stored.length > 0 && stored[0].value && stored[0].value.matchId) {
    const existing = stored[0].value.matchId as string;
    logger.info("RPC lobby reused: %s", existing);
    return JSON.stringify({ matchId: existing });
  }

  const matchId = nk.matchCreate(lobbyModuleName, {});
  nk.storageWrite([{
    collection: LOBBY_COLLECTION,
    key: LOBBY_KEY,
    userId: SYSTEM_USER,
    value: { matchId },
    permissionRead: 0,
    permissionWrite: 0,
  }]);
  lobbyMatchId = matchId;
  logger.info("Created online lobby match: %s", matchId);
  return JSON.stringify({ matchId });
}

function matchInit(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, params: {[key: string]: any}): {state: TicTacToeState, tickRate: number, label: string} {
  const state: TicTacToeState = {
    board: ["", "", "", "", "", "", "", "", ""],
    players: [],
    currentTurnSessionId: "",
    winner: null,
    gameOver: false,
  };

  return { state, tickRate: 1, label: moduleName };
}

function matchJoinAttempt(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, dispatcher: nkruntime.MatchDispatcher, tick: number, state: TicTacToeState, presence: nkruntime.Presence, metadata: {[key: string]: any}): {state: TicTacToeState, accept: boolean, rejectMessage?: string} | null {
  if (state.players.length >= MAX_PLAYERS) {
    return { state, accept: false, rejectMessage: "Match is full" };
  }

  return { state, accept: true };
}

function matchJoin(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, dispatcher: nkruntime.MatchDispatcher, tick: number, state: TicTacToeState, presences: nkruntime.Presence[]): {state: TicTacToeState} | null {
  for (const presence of presences) {
    const symbol = state.players.length === 0 ? "X" : "O";
    state.players.push({
      sessionId: presence.sessionId,
      userId: presence.userId,
      symbol: symbol as "X" | "O",
    });
    logger.info("Player %s joined as %s (%d/%d)", presence.userId, symbol, state.players.length, MAX_PLAYERS);
  }

  if (state.players.length === MAX_PLAYERS) {
    const firstIndex = Math.floor(Math.random() * 2);
    state.currentTurnSessionId = state.players[firstIndex].sessionId;
    state.board = ["", "", "", "", "", "", "", "", ""];
    state.winner = null;
    state.gameOver = false;
    logger.info("Match started! First turn: %s", state.players[firstIndex].userId);
    broadcastState(dispatcher, state);
  }

  return { state };
}

function matchLeave(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, dispatcher: nkruntime.MatchDispatcher, tick: number, state: TicTacToeState, presences: nkruntime.Presence[]): {state: TicTacToeState} | null {
  for (const presence of presences) {
    state.players = state.players.filter(p => p.sessionId !== presence.sessionId);
    logger.info("Player %s left", presence.userId);
  }

  if (state.players.length === 0) {
    state.gameOver = true;
    state.winner = null;
  } else if (state.players.length === 1 && !state.gameOver) {
    state.gameOver = true;
    state.winner = state.players[0].symbol;
    broadcastState(dispatcher, state);
  }

  return { state };
}

function matchLoop(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, dispatcher: nkruntime.MatchDispatcher, tick: number, state: TicTacToeState, messages: nkruntime.MatchMessage[]): {state: TicTacToeState} | null {
  for (const message of messages) {
    if (message.opCode === OP_CODE_MOVE) {
      if (state.gameOver) continue;
      if (state.currentTurnSessionId !== message.sender.sessionId) continue;

      const payload = JSON.parse(new TextDecoder().decode(message.data));
      const position = payload.position;

      if (position < 0 || position > 8) continue;
      if (state.board[position] !== "") continue;

      const player = state.players.find(p => p.sessionId === message.sender.sessionId);
      if (!player) continue;

      state.board[position] = player.symbol;
      logger.info("Move: %s placed %s at %d", player.userId, player.symbol, position);

      const winner = checkWinner(state.board);
      if (winner) {
        state.gameOver = true;
        state.winner = winner;
        logger.info("Winner: %s", winner);
        broadcastState(dispatcher, state);
        continue;
      }

      if (!state.board.includes("")) {
        state.gameOver = true;
        state.winner = null;
        logger.info("Draw!");
        broadcastState(dispatcher, state);
        continue;
      }

      const otherPlayer = state.players.find(p => p.sessionId !== message.sender.sessionId);
      if (otherPlayer) {
        state.currentTurnSessionId = otherPlayer.sessionId;
      }

      broadcastState(dispatcher, state);
    }
  }

  return { state };
}

function matchTerminate(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, dispatcher: nkruntime.MatchDispatcher, tick: number, state: TicTacToeState, graceSeconds: number): {state: TicTacToeState} | null {
  logger.info("Match terminated, grace: %d", graceSeconds);
  return { state };
}

function matchSignal(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, dispatcher: nkruntime.MatchDispatcher, tick: number, state: TicTacToeState, data: string): {state: TicTacToeState, data?: string} | null {
  return { state, data: "OK" };
}

function checkWinner(board: string[]): string | null {
  for (const line of WIN_LINES) {
    const [a, b, c] = line;
    if (board[a] !== "" && board[a] === board[b] && board[b] === board[c]) {
      return board[a];
    }
  }
  return null;
}

function broadcastState(dispatcher: nkruntime.MatchDispatcher, state: TicTacToeState) {
  const currentTurnPlayer = state.players.find(p => p.sessionId === state.currentTurnSessionId);

  const payload = {
    board: state.board,
    currentTurn: currentTurnPlayer ? currentTurnPlayer.userId : "",
    currentTurnSymbol: currentTurnPlayer ? currentTurnPlayer.symbol : "",
    winner: state.winner,
    gameOver: state.gameOver,
    players: state.players.map(p => ({
      userId: p.userId,
      symbol: p.symbol,
    })),
  };

  dispatcher.broadcastMessage(OP_CODE_STATE, JSON.stringify(payload), null, undefined, true);
}

// --- Online lobby (used only to count online players) ---

const LOBBY_MAX = 1000;

function lobbyMatchInit(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, params: {[key: string]: any}): {state: LobbyState, tickRate: number, label: string} {
  return { state: { occupants: 0 }, tickRate: 10, label: lobbyModuleName };
}

function lobbyMatchJoinAttempt(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, dispatcher: nkruntime.MatchDispatcher, tick: number, state: LobbyState, presence: nkruntime.Presence, metadata: {[key: string]: any}): {state: LobbyState, accept: boolean, rejectMessage?: string} | null {
  if (state.occupants >= LOBBY_MAX) {
    return { state, accept: false, rejectMessage: "Lobby is full" };
  }
  return { state, accept: true };
}

function lobbyMatchJoin(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, dispatcher: nkruntime.MatchDispatcher, tick: number, state: LobbyState, presences: nkruntime.Presence[]): {state: LobbyState} | null {
  state.occupants += presences.length;
  logger.info("Online lobby occupants: %d", state.occupants);
  return { state };
}

function lobbyMatchLeave(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, dispatcher: nkruntime.MatchDispatcher, tick: number, state: LobbyState, presences: nkruntime.Presence[]): {state: LobbyState} | null {
  state.occupants = Math.max(0, state.occupants - presences.length);
  logger.info("Online lobby occupants: %d", state.occupants);
  return { state };
}

function lobbyMatchLoop(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, dispatcher: nkruntime.MatchDispatcher, tick: number, state: LobbyState, messages: nkruntime.MatchMessage[]): {state: LobbyState} | null {
  return { state };
}

function lobbyMatchTerminate(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, dispatcher: nkruntime.MatchDispatcher, tick: number, state: LobbyState, graceSeconds: number): {state: LobbyState} | null {
  return { state };
}

function lobbyMatchSignal(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, dispatcher: nkruntime.MatchDispatcher, tick: number, state: LobbyState, data: string): {state: LobbyState, data?: string} | null {
  return { state, data: "OK" };
}
