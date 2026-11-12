import 'dart:math';

/// Pure-Dart rules engine for Ouk Chaktrang (Cambodian chess).
///
/// Board: 8x8, index = rank * 8 + file. rank 0 = White's back rank (rank "1").
/// White moves toward higher ranks, Black toward lower ranks.

enum Side { white, black }

extension SideX on Side {
  Side get other => this == Side.white ? Side.black : Side.white;
  int get fwd => this == Side.white ? 1 : -1;

  /// Rank index where a Trey (fish) promotes: 6th rank for both sides.
  int get promoRank => this == Side.white ? 5 : 2;
}

enum Kind { trey, bompong, neang, koul, ses, touk, ang }

class Piece {
  final Kind kind;
  final Side side;
  const Piece(this.kind, this.side);

  int get value => switch (kind) {
        Kind.trey => 100,
        Kind.bompong => 200,
        Kind.neang => 200,
        Kind.koul => 300,
        Kind.ses => 300,
        Kind.touk => 500,
        Kind.ang => 0,
      };

  String get glyph => switch (kind) {
        Kind.trey => 'ត',
        Kind.bompong => 'ប',
        Kind.neang => 'ន',
        Kind.koul => 'គ',
        Kind.ses => 'ស',
        Kind.touk => 'ទ',
        Kind.ang => 'អ',
      };
}

class Move {
  final int from, to;
  final bool promo; // Trey -> Trei Bompong
  final bool leap; // King's first-move leap
  const Move(this.from, this.to, {this.promo = false, this.leap = false});
}

String sqName(int i) => '${'abcdefgh'[i % 8]}${i ~/ 8 + 1}';

class Position {
  final List<Piece?> board;
  final Side turn;
  final bool wKingMoved, bKingMoved;

  /// Plies since the last capture or Trey move (used for the counting draw).
  final int quiet;

  const Position(this.board, this.turn,
      {this.wKingMoved = false, this.bKingMoved = false, this.quiet = 0});

  factory Position.initial() {
    final b = List<Piece?>.filled(64, null);
    const back = [
      Kind.touk, Kind.ses, Kind.koul, Kind.ang,
      Kind.neang, Kind.koul, Kind.ses, Kind.touk,
    ];
    for (var f = 0; f < 8; f++) {
      b[f] = Piece(back[f], Side.white);
      b[16 + f] = const Piece(Kind.trey, Side.white); // Treys start on rank 3
      b[40 + f] = const Piece(Kind.trey, Side.black); // ...and rank 6
      b[56 + f] = Piece(back[f], Side.black);
    }
    return Position(b, Side.white);
  }

  factory Position.empty() => Position(List<Piece?>.filled(64, null), Side.white);

  Position withPiece(int sq, Piece? p) {
    final nb = List<Piece?>.of(board);
    nb[sq] = p;
    return Position(nb, turn, wKingMoved: wKingMoved, bKingMoved: bKingMoved, quiet: quiet);
  }

  static const _diag = [[1, 1], [1, -1], [-1, 1], [-1, -1]];
  static const _orth = [[1, 0], [-1, 0], [0, 1], [0, -1]];
  static const _knight = [
    [1, 2], [2, 1], [-1, 2], [-2, 1], [1, -2], [2, -1], [-1, -2], [-2, -1],
  ];

  /// Pseudo-legal moves (may leave own Ang in check).
  /// With [attacks] true, returns the squares each piece attacks (used for check detection).
  List<Move> pseudo(Side s, {bool attacks = false}) {
    final out = <Move>[];
    for (var i = 0; i < 64; i++) {
      final p = board[i];
      if (p == null || p.side != s) continue;
      final f = i % 8, r = i ~/ 8;

      void step(int df, int dr, {bool capOnly = false, bool quietOnly = false}) {
        final nf = f + df, nr = r + dr;
        if (nf < 0 || nf > 7 || nr < 0 || nr > 7) return;
        final to = nr * 8 + nf;
        if (attacks) {
          if (!quietOnly) out.add(Move(i, to));
          return;
        }
        final t = board[to];
        final promo = p.kind == Kind.trey && nr == s.promoRank;
        if (t == null) {
          if (!capOnly) out.add(Move(i, to, promo: promo));
        } else if (t.side != s && !quietOnly) {
          out.add(Move(i, to, promo: promo));
        }
      }

      void slide(int df, int dr) {
        var nf = f + df, nr = r + dr;
        while (nf >= 0 && nf < 8 && nr >= 0 && nr < 8) {
          final to = nr * 8 + nf;
          final t = board[to];
          if (t == null) {
            out.add(Move(i, to));
          } else {
            if (attacks || t.side != s) out.add(Move(i, to));
            break;
          }
          nf += df;
          nr += dr;
        }
      }

      switch (p.kind) {
        case Kind.trey:
          step(0, s.fwd, quietOnly: true);
          step(1, s.fwd, capOnly: true);
          step(-1, s.fwd, capOnly: true);
        case Kind.bompong:
        case Kind.neang:
          for (final d in _diag) {
            step(d[0], d[1]);
          }
        case Kind.koul:
          for (final d in _diag) {
            step(d[0], d[1]);
          }
          step(0, s.fwd);
        case Kind.ses:
          for (final d in _knight) {
            step(d[0], d[1]);
          }
        case Kind.touk:
          for (final d in _orth) {
            slide(d[0], d[1]);
          }
        case Kind.ang:
          for (final d in _diag) {
            step(d[0], d[1]);
          }
          for (final d in _orth) {
            step(d[0], d[1]);
          }
      }
    }
    return out;
  }

  int kingSq(Side s) {
    for (var i = 0; i < 64; i++) {
      final p = board[i];
      if (p != null && p.kind == Kind.ang && p.side == s) return i;
    }
    return -1;
  }

  bool inCheck(Side s) {
    final k = kingSq(s);
    if (k < 0) return false;
    return pseudo(s.other, attacks: true).any((m) => m.to == k);
  }

  Position apply(Move m) {
    final nb = List<Piece?>.of(board);
    final p = nb[m.from]!;
    final cap = nb[m.to];
    nb[m.from] = null;
    nb[m.to] = m.promo ? Piece(Kind.bompong, p.side) : p;
    final reset = cap != null || p.kind == Kind.trey;
    return Position(
      nb,
      turn.other,
      wKingMoved: wKingMoved || (p.kind == Kind.ang && p.side == Side.white),
      bKingMoved: bKingMoved || (p.kind == Kind.ang && p.side == Side.black),
      quiet: reset ? 0 : quiet + 1,
    );
  }

  List<Move> legal() {
    final out = <Move>[];
    for (final m in pseudo(turn)) {
      if (!apply(m).inCheck(turn)) out.add(m);
    }
    // King's one-time opening leap: a forward knight jump onto an empty square,
    // only when not in check, and never giving direct check to the enemy Ang.
    final moved = turn == Side.white ? wKingMoved : bKingMoved;
    if (!moved && !inCheck(turn)) {
      final k = kingSq(turn);
      if (k >= 0) {
        final f = k % 8, r = k ~/ 8;
        for (final d in _knight) {
          final nf = f + d[0], nr = r + d[1];
          if (nf < 0 || nf > 7 || nr < 0 || nr > 7) continue;
          if ((nr - r) * turn.fwd <= 0) continue;
          final to = nr * 8 + nf;
          if (board[to] != null) continue;
          final m = Move(k, to, leap: true);
          final np = apply(m);
          if (!np.inCheck(turn) && !np.inCheck(turn.other)) out.add(m);
        }
      }
    }
    return out;
  }

  /// Material + advancement score from [s]'s point of view.
  int eval(Side s) {
    var score = 0;
    for (var i = 0; i < 64; i++) {
      final p = board[i];
      if (p == null) continue;
      var v = p.value;
      if (p.kind == Kind.trey) {
        final progress = p.side == Side.white ? i ~/ 8 - 2 : 5 - i ~/ 8;
        v += progress * 8;
      }
      score += p.side == s ? v : -v;
    }
    return score;
  }
}

String notate(Position before, Move m) {
  const letters = {
    Kind.trey: '', Kind.bompong: 'B', Kind.neang: 'N',
    Kind.koul: 'K', Kind.ses: 'S', Kind.touk: 'T', Kind.ang: 'A',
  };
  final p = before.board[m.from]!;
  final cap = before.board[m.to] != null;
  var s = letters[p.kind]!;
  if (cap) {
    if (p.kind == Kind.trey) s += 'abcdefgh'[m.from % 8];
    s += 'x';
  }
  s += sqName(m.to);
  if (m.promo) s += '=B';
  if (m.leap) s += '~';
  final after = before.apply(m);
  if (after.inCheck(after.turn)) {
    s += after.legal().isEmpty ? '#' : '+';
  }
  return s;
}

// ───────────────────────── Search (alpha-beta negamax) ─────────────────────────

int _capValue(Position p, Move m) => p.board[m.to]?.value ?? 0;

int _search(Position p, int depth, int alpha, int beta) {
  final moves = p.legal();
  if (moves.isEmpty) return p.inCheck(p.turn) ? -100000 - depth : 0;
  if (depth == 0) return p.eval(p.turn);
  moves.sort((a, b) => _capValue(p, b) - _capValue(p, a));
  var best = -1000000;
  for (final m in moves) {
    final s = -_search(p.apply(m), depth - 1, -beta, -alpha);
    if (s > best) best = s;
    if (best > alpha) alpha = best;
    if (alpha >= beta) break;
  }
  return best;
}

/// Best move for the side to move. [noise] adds randomness (weaker bots).
/// Top-level + sendable arguments so it can run inside an Isolate.
Move? bestMove(Position p, int depth, {int noise = 0, int seed = 0}) {
  final moves = p.legal();
  if (moves.isEmpty) return null;
  final rnd = Random(seed);
  moves.shuffle(rnd);
  Move? best;
  var bestScore = -1 << 30;
  for (final m in moves) {
    var s = -_search(p.apply(m), depth - 1, -1000000, 1000000);
    if (noise > 0) s += rnd.nextInt(noise);
    if (s > bestScore) {
      bestScore = s;
      best = m;
    }
  }
  return best;
}

class PlyReview {
  /// Evaluation lost versus the engine's best move (100 = one Trey).
  final int loss;
  final Move? best;
  const PlyReview(this.loss, this.best);
}

/// Reviews every ply of a finished game with a shallow engine search.
List<PlyReview> reviewGame(List<Position> snaps, List<Move> moves) {
  final out = <PlyReview>[];
  for (var i = 0; i < moves.length; i++) {
    final p = snaps[i];
    var bestScore = -1 << 30;
    Move? bestM;
    for (final m in p.legal()) {
      final s = -_search(p.apply(m), 1, -1000000, 1000000);
      if (s > bestScore) {
        bestScore = s;
        bestM = m;
      }
    }
    final played = -_search(p.apply(moves[i]), 1, -1000000, 1000000);
    out.add(PlyReview(max(0, bestScore - played), bestM));
  }
  return out;
}
