import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';

import 'engine.dart';

enum GameMode { vsAi, passAndPlay }

enum Outcome { playing, whiteWins, blackWins, draw }

class MatchConfig {
  final GameMode mode;
  final int aiDepth;
  final int noise;
  final String opponent;
  final int opponentElo;
  final int seconds;
  final String label;
  const MatchConfig({
    required this.mode,
    this.aiDepth = 2,
    this.noise = 0,
    this.opponent = 'Vannak Kem',
    this.opponentElo = 1822,
    this.seconds = 600,
    this.label = 'Ranked • Rapid',
  });
}

Future<Move?> _think(Position p, int depth, int noise, int seed) =>
    Isolate.run(() => bestMove(p, depth, noise: noise, seed: seed));

class GameController extends ChangeNotifier {
  final MatchConfig cfg;
  Position pos = Position.initial();
  final List<Position> snaps = [Position.initial()];
  final List<Move> moves = [];
  final List<String> notation = [];
  final List<Piece> capByWhite = [];
  final List<Piece> capByBlack = [];

  int wTime, bTime;
  int? selected;
  List<Move> targets = [];
  Move? last;
  Outcome outcome = Outcome.playing;
  String reason = '';
  bool thinking = false;

  Timer? _timer;
  bool _disposed = false;

  GameController(this.cfg)
      : wTime = cfg.seconds,
        bTime = cfg.seconds {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  bool get over => outcome != Outcome.playing;
  bool get humanTurn => cfg.mode == GameMode.passAndPlay || pos.turn == Side.white;
  int get countPlies => pos.quiet;
  bool get inCheck => pos.inCheck(pos.turn);

  void _tick() {
    if (over || _disposed) return;
    if (pos.turn == Side.white) {
      wTime--;
      if (wTime <= 0) {
        wTime = 0;
        _finish(Outcome.blackWins, 'on time');
        return;
      }
    } else {
      bTime--;
      if (bTime <= 0) {
        bTime = 0;
        _finish(Outcome.whiteWins, 'on time');
        return;
      }
    }
    notifyListeners();
  }

  void tap(int sq) {
    if (over || thinking || !humanTurn) return;
    final legal = pos.legal();
    if (selected != null) {
      final cands = legal.where((m) => m.from == selected && m.to == sq).toList();
      if (cands.isNotEmpty) {
        _play(cands.first);
        return;
      }
    }
    final p = pos.board[sq];
    if (p != null && p.side == pos.turn) {
      selected = sq;
      targets = legal.where((m) => m.from == sq).toList();
    } else {
      selected = null;
      targets = [];
    }
    notifyListeners();
  }

  void _play(Move m) {
    final before = pos;
    final note = notate(before, m);
    final cap = before.board[m.to];
    if (cap != null) {
      (before.turn == Side.white ? capByWhite : capByBlack).add(cap);
    }
    pos = before.apply(m);
    snaps.add(pos);
    moves.add(m);
    notation.add(note);
    last = m;
    selected = null;
    targets = [];
    _checkEnd();
    notifyListeners();
    if (!over && cfg.mode == GameMode.vsAi && pos.turn == Side.black) _aiMove();
  }

  void _checkEnd() {
    final legal = pos.legal();
    if (legal.isEmpty) {
      if (pos.inCheck(pos.turn)) {
        _finish(pos.turn == Side.white ? Outcome.blackWins : Outcome.whiteWins, 'checkmate');
      } else {
        _finish(Outcome.draw, 'stalemate');
      }
    } else if (pos.quiet >= 128) {
      _finish(Outcome.draw, 'board count (64 moves)');
    }
  }

  Future<void> _aiMove() async {
    thinking = true;
    notifyListeners();
    final started = DateTime.now();
    Move? m;
    try {
      m = await _think(pos, cfg.aiDepth, cfg.noise, moves.length);
    } catch (_) {
      m = bestMove(pos, cfg.aiDepth, noise: cfg.noise, seed: moves.length);
    }
    final elapsed = DateTime.now().difference(started);
    const minThink = Duration(milliseconds: 650);
    if (elapsed < minThink) await Future.delayed(minThink - elapsed);
    thinking = false;
    if (_disposed || over) return;
    if (m == null) {
      notifyListeners();
      return;
    }
    _play(m);
  }

  void resign(Side who) {
    if (over) return;
    _finish(who == Side.white ? Outcome.blackWins : Outcome.whiteWins, 'resignation');
  }

  /// Returns true when the draw offer is accepted.
  bool offerDraw() {
    if (over) return false;
    if (cfg.mode == GameMode.vsAi) {
      // The bot accepts when it is not ahead.
      if (pos.eval(Side.black) <= 0) {
        _finish(Outcome.draw, 'agreement');
        return true;
      }
      return false;
    }
    _finish(Outcome.draw, 'agreement');
    return true;
  }

  void _finish(Outcome o, String why) {
    outcome = o;
    reason = why;
    selected = null;
    targets = [];
    _timer?.cancel();
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
