import 'dart:isolate';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../game/board_view.dart';
import '../game/controller.dart';
import '../game/engine.dart';
import '../theme.dart';

Future<List<PlyReview>> _review(List<Position> snaps, List<Move> moves) =>
    Isolate.run(() => reviewGame(snaps, moves));

class AnalysisScreen extends StatefulWidget {
  final GameController game;
  const AnalysisScreen({super.key, required this.game});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  GameController get g => widget.game;
  List<PlyReview>? _reviews;
  late int _idx = g.moves.length;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    List<PlyReview> r;
    try {
      r = await _review(List.of(g.snaps), List.of(g.moves));
    } catch (_) {
      r = reviewGame(g.snaps, g.moves);
    }
    if (mounted) setState(() => _reviews = r);
  }

  @override
  void dispose() {
    g.dispose();
    super.dispose();
  }

  // ───────── derived stats ─────────
  bool get _vsAi => g.cfg.mode == GameMode.vsAi;
  bool get _won => g.outcome == Outcome.whiteWins;
  bool get _draw => g.outcome == Outcome.draw;

  int get _eloDelta {
    if (!_vsAi) return 0;
    const me = 1840;
    final expected = 1 / (1 + math.pow(10, (g.cfg.opponentElo - me) / 400));
    final score = _won ? 1.0 : (_draw ? .5 : 0.0);
    return (32 * (score - expected)).round();
  }

  List<PlyReview> _mine() {
    final r = _reviews;
    if (r == null) return const [];
    return [for (var i = 0; i < r.length; i += 2) r[i]]; // White's plies
  }

  double get _accuracy {
    final m = _mine();
    if (m.isEmpty) return 100;
    final avg = m.map((e) => e.loss).reduce((a, b) => a + b) / m.length;
    return (100 - avg / 10).clamp(0, 100).toDouble();
  }

  int get _best => _mine().where((e) => e.loss == 0).length;
  int get _blunders => _mine().where((e) => e.loss >= 300).length;
  int get _inacc => _mine().where((e) => e.loss >= 100 && e.loss < 300).length;

  String _cls(int loss) {
    if (loss == 0) return 'Best';
    if (loss < 100) return 'Good';
    if (loss < 300) return 'Inaccuracy';
    return 'Blunder';
  }

  Color _clsColor(int loss) {
    if (loss == 0) return C.secondary;
    if (loss < 100) return C.primary;
    if (loss < 300) return const Color(0xFFFFC857);
    return C.error;
  }

  @override
  Widget build(BuildContext context) {
    final title = _draw ? 'ស្មើ' : (_won ? 'ជ័យជម្នះ' : 'បរាជ័យ');
    final sub = _draw ? 'DRAW' : (_won ? 'VICTORY' : 'DEFEAT');
    final delta = _eloDelta;
    final newElo = 1840 + delta;
    final idx = _idx.clamp(0, g.moves.length);

    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        backgroundColor: C.surfaceLow,
        elevation: 0,
        title: Text('Match Analysis', style: serif(18, color: C.primary)),
        leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          // Victory banner
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: RadialGradient(
                radius: 1.1,
                colors: [C.primary.withValues(alpha: _won ? .22 : .08), C.high],
              ),
              border:
                  Border.all(color: C.primaryContainer.withValues(alpha: .4)),
            ),
            child: Column(children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient:
                      const LinearGradient(colors: [C.primary, C.woodDark]),
                  boxShadow: [
                    BoxShadow(
                        color: C.primary.withValues(alpha: .4), blurRadius: 24)
                  ],
                ),
                child: Icon(_won ? Icons.star_rounded : Icons.balance,
                    size: 42, color: C.onPrimary),
              ),
              const SizedBox(height: 14),
              Text(title,
                  style: serif(34, color: C.primary, w: FontWeight.w700)),
              Text(sub, style: mono(13, color: C.onVar)),
              const SizedBox(height: 4),
              Text('by ${g.reason}', style: body(12)),
            ]),
          ),
          const SizedBox(height: 14),

          // Rating
          if (_vsAi)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: card(color: C.high, radius: 16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text('Rating', style: body(12)),
                      const Spacer(),
                      Text('${delta >= 0 ? '+' : ''}$delta',
                          style: mono(18,
                              color: delta >= 0 ? C.secondary : C.error)),
                    ]),
                    const SizedBox(height: 2),
                    Text('$newElo', style: mono(32, color: C.primary)),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: ((newElo - 1800) / 200).clamp(0.0, 1.0),
                        minHeight: 8,
                        color: C.primary,
                        backgroundColor: C.surface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text('Grandmaster tier • 1800 – 2000', style: body(11)),
                  ]),
            ),
          if (_vsAi) const SizedBox(height: 14),

          // Metrics
          Row(children: [
            _metric(
                'Accuracy',
                _reviews == null ? '…' : '${_accuracy.toStringAsFixed(1)}%',
                C.secondary),
            const SizedBox(width: 10),
            _metric('Best moves', _reviews == null ? '…' : '$_best', C.primary),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _metric('Blunders', _reviews == null ? '…' : '$_blunders', C.error),
            const SizedBox(width: 10),
            _metric('Inaccuracies', _reviews == null ? '…' : '$_inacc',
                const Color(0xFFFFC857)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _metric('Moves', '${(g.moves.length + 1) ~/ 2}', C.onSurface),
            const SizedBox(width: 10),
            _metric('Captures', '${g.capByWhite.length + g.capByBlack.length}',
                C.onSurface),
            const SizedBox(width: 10),
            _metric('Time used', _fmt(g.cfg.seconds - g.wTime), C.onSurface),
          ]),
          const SizedBox(height: 18),

          // Replay
          Text('Move-by-move review', style: serif(20)),
          const SizedBox(height: 10),
          BoardView(
            pos: g.snaps[idx],
            last: idx > 0 ? g.moves[idx - 1] : null,
          ),
          const SizedBox(height: 10),
          _movePanel(idx),
          Row(children: [
            IconButton(
              onPressed: idx > 0 ? () => setState(() => _idx = idx - 1) : null,
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Slider(
                value: idx.toDouble(),
                min: 0,
                max: math.max(1, g.moves.length).toDouble(),
                divisions: math.max(1, g.moves.length),
                activeColor: C.primary,
                inactiveColor: C.highest,
                onChanged: g.moves.isEmpty
                    ? null
                    : (v) => setState(() => _idx = v.round()),
              ),
            ),
            IconButton(
              onPressed: idx < g.moves.length
                  ? () => setState(() => _idx = idx + 1)
                  : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ]),
          Center(
              child: Text('Move $idx / ${g.moves.length}',
                  style: mono(12, color: C.onVar))),
          const SizedBox(height: 18),

          // CTAs
          FilledButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.replay),
            label: const Text('Back to lobby',
                style: TextStyle(fontWeight: FontWeight.w700)),
            style: FilledButton.styleFrom(
              backgroundColor: C.primary,
              foregroundColor: C.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () {
              final pgn = [
                for (var i = 0; i < g.notation.length; i += 2)
                  '${i ~/ 2 + 1}. ${g.notation[i]} ${i + 1 < g.notation.length ? g.notation[i + 1] : ''}'
              ].join(' ');
              showDialog<void>(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: C.surfaceLow,
                  title: Text('Move list', style: serif(18)),
                  content: SelectableText(pgn, style: mono(13, color: C.onVar)),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'))
                  ],
                ),
              );
            },
            icon: const Icon(Icons.ios_share, size: 18),
            label: const Text('Share move list'),
            style: OutlinedButton.styleFrom(
              foregroundColor: C.primary,
              side: BorderSide(color: C.primaryContainer.withValues(alpha: .5)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _movePanel(int idx) {
    if (idx == 0) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: card(color: C.surfaceLow, radius: 12),
        child: Text('Starting position. Drag the slider to replay the game.',
            style: body(13)),
      );
    }
    final note = g.notation[idx - 1];
    final r = _reviews;
    final rev = (r != null && idx - 1 < r.length) ? r[idx - 1] : null;
    String advice = 'Analysing…';
    if (rev != null) {
      if (rev.loss == 0) {
        advice = 'The engine agrees — this was the strongest continuation.';
      } else if (rev.best != null) {
        advice = 'A stronger idea was ${notate(g.snaps[idx - 1], rev.best!)} '
            '(about ${(rev.loss / 100).toStringAsFixed(1)} Trey of value).';
      }
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(12),
      decoration: card(color: C.surfaceLow, radius: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('${(idx + 1) ~/ 2}${idx.isOdd ? '.' : '…'} $note',
              style: mono(16, color: C.primary)),
          const SizedBox(width: 10),
          if (rev != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: _clsColor(rev.loss).withValues(alpha: .16),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(_cls(rev.loss),
                  style:
                      body(11, color: _clsColor(rev.loss), w: FontWeight.w700)),
            ),
        ]),
        const SizedBox(height: 6),
        Text(advice, style: body(12.5)),
      ]),
    );
  }

  Widget _metric(String label, String value, Color c) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: card(color: C.high, radius: 14),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: mono(22, color: c)),
            const SizedBox(height: 2),
            Text(label, style: body(11)),
          ]),
        ),
      );

  String _fmt(int s) => '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}
