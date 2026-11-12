import 'package:flutter/material.dart';

import '../game/board_view.dart';
import '../game/controller.dart';
import '../game/engine.dart';
import '../theme.dart';
import 'analysis_screen.dart';

class MatchScreen extends StatefulWidget {
  final MatchConfig cfg;
  const MatchScreen({super.key, required this.cfg});

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  late final GameController g = GameController(widget.cfg);
  bool _shown = false;
  bool _handedOff = false;

  @override
  void initState() {
    super.initState();
    g.addListener(_onChange);
  }

  void _onChange() {
    if (g.over && !_shown) {
      _shown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _showResult());
    }
  }

  Future<void> _showResult() async {
    if (!mounted) return;
    final title = switch (g.outcome) {
      Outcome.whiteWins =>
        g.cfg.mode == GameMode.vsAi ? 'Victory • ជ័យជម្នះ' : 'White wins',
      Outcome.blackWins =>
        g.cfg.mode == GameMode.vsAi ? 'Defeat • បរាជ័យ' : 'Black wins',
      _ => 'Draw • ស្មើ',
    };
    final analyse = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: C.surfaceLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(title, style: serif(20, color: C.primary)),
        content: Text('Game ended by ${g.reason}.', style: body(14)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Lobby')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: C.primary, foregroundColor: C.onPrimary),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('View analysis'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (analyse == true) {
      _handedOff =
          true; // AnalysisScreen now owns (and disposes) the controller
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => AnalysisScreen(game: g)),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    g.removeListener(_onChange);
    if (!_handedOff) g.dispose();
    super.dispose();
  }

  Future<void> _confirmResign() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: C.surfaceLow,
        title: Text('Resign this game?', style: serif(18)),
        content:
            Text('Your opponent will be awarded the win.', style: body(14)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: C.error, foregroundColor: Colors.black),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Resign'),
          ),
        ],
      ),
    );
    if (ok == true) {
      g.resign(g.cfg.mode == GameMode.vsAi ? Side.white : g.pos.turn);
    }
  }

  void _offerDraw() {
    final msg = g.cfg.mode == GameMode.passAndPlay;
    if (msg) {
      showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: C.surfaceLow,
          title: Text('Draw offered', style: serif(18)),
          content:
              Text('Does the other player accept a draw?', style: body(14)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Decline')),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                g.offerDraw();
              },
              child: const Text('Accept'),
            ),
          ],
        ),
      );
      return;
    }
    final accepted = g.offerDraw();
    if (!accepted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${g.cfg.opponent} declined the draw')));
    }
  }

  void _showCount() {
    final moves = g.countPlies ~/ 2;
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: C.surfaceLow,
        title: Text('ការរាប់ក្ដារ • Board count', style: serif(18)),
        content: Text(
          'Moves since the last capture or Trey move: $moves / 64.\n\n'
          'At 64 the game is drawn. Shorter counts (8, 16, 22, 32) apply when a lone Ang is chased — see the Learn tab.',
          style: body(14),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('OK'))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: g,
      builder: (context, _) {
        final pp = g.cfg.mode == GameMode.passAndPlay;
        final top = _PlayerBar(
          name: g.cfg.opponent,
          elo: g.cfg.opponentElo,
          captured: g.capByBlack, // pieces Black has taken (White pieces)
          seconds: g.bTime,
          active: g.pos.turn == Side.black && !g.over,
          status: g.thinking ? 'Thinking…' : null,
          initial: g.cfg.opponent.isEmpty ? '?' : g.cfg.opponent[0],
        );
        final bottom = _PlayerBar(
          name: pp ? 'Player 1' : 'Sophea Pich',
          elo: pp ? 0 : 1840,
          captured: g.capByWhite,
          seconds: g.wTime,
          active: g.pos.turn == Side.white && !g.over,
          initial: pp ? '1' : 'S',
        );
        return Scaffold(
          backgroundColor: C.bg,
          appBar: AppBar(
            backgroundColor: C.surfaceLow,
            elevation: 0,
            title:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Active Match', style: serif(17, color: C.primary)),
              Text(g.cfg.label, style: body(11)),
            ]),
            actions: [
              if (g.inCheck && !g.over)
                Container(
                  margin: const EdgeInsets.only(right: 14),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: C.error.withValues(alpha: .18),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text('CHECK', style: mono(11, color: C.error)),
                ),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
              children: [
                pp ? RotatedBox(quarterTurns: 2, child: top) : top,
                const SizedBox(height: 12),
                BoardView(
                  pos: g.pos,
                  selected: g.selected,
                  targets: g.targets.map((m) => m.to).toSet(),
                  last: g.last,
                  onTap: g.tap,
                ),
                const SizedBox(height: 12),
                bottom,
                if (g.countPlies >= 40) ...[
                  const SizedBox(height: 12),
                  _countBanner(),
                ],
                const SizedBox(height: 12),
                _notation(),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                      child: _action(
                          Icons.handshake_outlined, 'Draw', _offerDraw)),
                  const SizedBox(width: 10),
                  Expanded(child: _action(Icons.grid_4x4, 'Count', _showCount)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _action(
                          Icons.flag_outlined, 'Resign', _confirmResign,
                          danger: true)),
                ]),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _countBanner() => Container(
        padding: const EdgeInsets.all(12),
        decoration:
            card(color: C.high, border: C.secondary.withValues(alpha: .4)),
        child: Row(children: [
          const Icon(Icons.timer_outlined, color: C.secondary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
                'Board count ${g.countPlies ~/ 2} / 64 — a capture or Trey move resets it.',
                style: body(12.5, color: C.onSurface)),
          ),
        ]),
      );

  Widget _notation() {
    final rows = <String>[];
    for (var i = 0; i < g.notation.length; i += 2) {
      final w = g.notation[i];
      final b = i + 1 < g.notation.length ? g.notation[i + 1] : '';
      rows.add('${i ~/ 2 + 1}. $w  $b');
    }
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: card(color: C.surfaceLow, radius: 12),
      child: rows.isEmpty
          ? Align(
              alignment: Alignment.centerLeft,
              child: Text('Move tape — make your first move', style: body(12)))
          : ListView.separated(
              reverse: true,
              scrollDirection: Axis.horizontal,
              itemCount: rows.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (_, i) => Center(
                child: Text(rows[rows.length - 1 - i],
                    style: mono(12, color: i == 0 ? C.primary : C.onVar)),
              ),
            ),
    );
  }

  Widget _action(IconData icon, String label, VoidCallback onTap,
          {bool danger = false}) =>
      OutlinedButton.icon(
        onPressed: g.over ? null : onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: danger ? C.error : C.primary,
          side: BorderSide(
              color: (danger ? C.error : C.primaryContainer)
                  .withValues(alpha: .5)),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
}

class _PlayerBar extends StatelessWidget {
  final String name, initial;
  final int elo, seconds;
  final List<Piece> captured;
  final bool active;
  final String? status;

  const _PlayerBar({
    required this.name,
    required this.initial,
    required this.elo,
    required this.captured,
    required this.seconds,
    required this.active,
    this.status,
  });

  String get _clock {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: card(
        color: C.high,
        radius: 14,
        border: active ? C.secondary.withValues(alpha: .7) : Colors.transparent,
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: C.woodDark,
          child: Text(initial, style: serif(18, color: C.woodLight)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(
                  child: Text(name,
                      style: serif(15), overflow: TextOverflow.ellipsis)),
              if (elo > 0) ...[
                const SizedBox(width: 6),
                Text('$elo', style: mono(11, color: C.primary)),
              ],
              if (status != null) ...[
                const SizedBox(width: 8),
                Text(status!, style: body(11, color: C.secondary)),
              ],
            ]),
            const SizedBox(height: 4),
            SizedBox(
              height: 18,
              child: captured.isEmpty
                  ? Text('No captures yet', style: body(10.5, color: C.outline))
                  : ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final p in captured)
                          Padding(
                            padding: const EdgeInsets.only(right: 3),
                            child: PieceDisc(p, size: 18),
                          ),
                      ],
                    ),
            ),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: active
                ? C.secondaryContainer.withValues(alpha: .25)
                : C.surface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(_clock,
              style: mono(20, color: active ? C.secondary : C.onVar)),
        ),
      ]),
    );
  }
}
