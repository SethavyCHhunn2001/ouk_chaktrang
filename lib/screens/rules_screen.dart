import 'package:flutter/material.dart';

import '../game/board_view.dart';
import '../game/engine.dart';
import '../theme.dart';

class RulesScreen extends StatefulWidget {
  const RulesScreen({super.key});
  @override
  State<RulesScreen> createState() => _RulesScreenState();
}

class _RulesScreenState extends State<RulesScreen> {
  int _tab = 0;
  static const _tabs = ['Pieces', 'Special', 'Counting', 'Lore'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        backgroundColor: C.surfaceLow,
        elevation: 0,
        title: Text('Rules & Guide', style: serif(18, color: C.primary)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient:
                  const LinearGradient(colors: [Color(0xFF3A2814), C.high]),
              border:
                  Border.all(color: C.primaryContainer.withValues(alpha: .35)),
            ),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('TUTORIAL & ACADEMY', style: mono(10, color: C.secondary)),
              const SizedBox(height: 6),
              Text('Master the Ancient Art',
                  style: serif(24, color: C.primary)),
              const SizedBox(height: 6),
              Text(
                'Ouk Chaktrang (អុកចត្រង្គ) blends patient Angkorian tactics with forward pawn pressure. '
                'Learn the pieces, the promotion flip and the sacred draw count.',
                style: body(13),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          Row(children: [
            _metric('8×8', 'UNCHECKERED'),
            const SizedBox(width: 8),
            _metric('Rank 3', 'TREY LAUNCH'),
            const SizedBox(width: 8),
            _metric('64', 'ENDGAME DRAW'),
          ]),
          const SizedBox(height: 14),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _tabs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => ChoiceChip(
                label: Text(_tabs[i]),
                selected: _tab == i,
                onSelected: (_) => setState(() => _tab = i),
                selectedColor: C.primary,
                backgroundColor: C.high,
                labelStyle: TextStyle(
                  color: _tab == i ? C.onPrimary : C.onVar,
                  fontWeight: FontWeight.w700,
                ),
                side: BorderSide.none,
                showCheckmark: false,
              ),
            ),
          ),
          const SizedBox(height: 14),
          ..._section(),
          const SizedBox(height: 20),
          Text('Practice: promote a Trey', style: serif(20)),
          const SizedBox(height: 4),
          Text('Tap the Trey, then its glowing target square.',
              style: body(13)),
          const SizedBox(height: 10),
          const _PromotionPractice(),
        ],
      ),
    );
  }

  List<Widget> _section() {
    switch (_tab) {
      case 0:
        return [
          _pieceCard(Kind.trey, 'ត្រី', 'Trey (Fish)',
              'Steps one square forward, captures one square diagonally forward. Starts on the 3rd rank — there is no double step and no en passant.'),
          _pieceCard(Kind.bompong, 'ត្រីបំពង់', 'Trei Bompong',
              'A Trey that reaches the 6th rank is promoted at once. It moves like the Neang: one step diagonally in any direction.'),
          _pieceCard(Kind.neang, 'នាង', 'Neang (Queen)',
              'A close guardian: one step diagonally in any of four directions.'),
          _pieceCard(Kind.koul, 'គោល', 'Koul (General)',
              'Five points: one step diagonally in any direction, plus one step straight forward.'),
          _pieceCard(Kind.ses, 'សេះ', 'Ses (Horse)',
              'Leaps in an L-shape and may jump over other pieces.'),
          _pieceCard(Kind.touk, 'ទូក', 'Touk (Boat)',
              'Slides any distance along ranks and files.'),
          _pieceCard(Kind.ang, 'អង្គ', 'Ang (King)',
              'One step in any direction. Once per game, if not in check, it may leap forward like a Horse onto an empty square.'),
        ];
      case 1:
        return [
          _note(
              Icons.flag_outlined,
              'No checkmating with the leap',
              'FOUNDATIONAL',
              "The King's opening leap cannot land on an occupied square or put the enemy Ang directly in check. There is no castling in Ouk Chaktrang."),
          _note(Icons.sync_alt, 'No double-step opening', 'ORGANIC CLASH',
              'Treys already start perched on rank 3, so there is neither a double step nor en passant. Every clash is deliberate.'),
          _note(Icons.upgrade, 'Instant promotion', 'RANK 6',
              'A Trey that reaches the 6th rank (3rd rank for Black) becomes a Trei Bompong immediately.'),
        ];
      case 2:
        return [
          Text(
            'When a defender has only a lone Ang left, the Fleeing King rule applies: if the attacker cannot '
            'checkmate within the count, the game is an honourable draw.',
            style: body(13),
          ),
          const SizedBox(height: 10),
          _count('Universal board limit', '64 moves', Icons.grid_4x4),
          _count('Attacker has 2 Boats (Touk)', '8 moves', Icons.sailing),
          _count(
              'Attacker has 1 Boat (Touk)', '16 moves', Icons.directions_boat),
          _count('Attacker has 2 Generals (Koul)', '22 moves',
              Icons.shield_outlined),
          _count('Attacker has 2 Horses (Ses)', '32 moves',
              Icons.pest_control_rodent_outlined),
          _count('Attacker has only Neang / Fish', '64 moves', Icons.swap_vert),
        ];
      default:
        return [
          _note(
              Icons.account_balance_outlined,
              'Carved on the walls of Angkor',
              'BAYON TEMPLE • c. 1190 AD',
              'Bas-relief carvings at Angkor Wat and Bayon show royal officers locked in Ouk Chaktrang matches, '
                  'reflecting classical Khmer naval and military deployments.'),
        ];
    }
  }

  Widget _metric(String big, String small) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: card(color: C.high, radius: 12),
          child: Column(children: [
            Text(big, style: serif(18, color: C.primary)),
            const SizedBox(height: 2),
            Text(small, style: mono(9, color: C.outline)),
          ]),
        ),
      );

  Widget _count(String label, String value, IconData icon) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: card(color: C.high, radius: 12),
        child: Row(children: [
          Icon(icon, color: C.secondary, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: body(13, color: C.onSurface))),
          Text(value, style: mono(13, color: C.primary)),
        ]),
      );

  Widget _note(IconData icon, String title, String tag, String text) =>
      Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: card(color: C.high, radius: 14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: C.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tag, style: mono(9, color: C.secondary)),
              const SizedBox(height: 2),
              Text(title, style: serif(16)),
              const SizedBox(height: 4),
              Text(text, style: body(12.5)),
            ]),
          ),
        ]),
      );

  Widget _pieceCard(Kind kind, String khmer, String name, String text) =>
      Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: card(color: C.high, radius: 14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 112, height: 112, child: _MoveDiagram(kind)),
          const SizedBox(width: 14),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(khmer,
                  style: body(12, color: C.primary, w: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(name, style: serif(16)),
              const SizedBox(height: 6),
              Text(text, style: body(12.5)),
            ]),
          ),
        ]),
      );
}

/// Small 8x8 diagram: piece in the middle, dots on every square it can reach.
class _MoveDiagram extends StatelessWidget {
  final Kind kind;
  const _MoveDiagram(this.kind);

  @override
  Widget build(BuildContext context) {
    final home =
        kind == Kind.trey ? 2 * 8 + 3 : 3 * 8 + 3; // d3 for Trey, d4 otherwise
    var pos = Position.empty().withPiece(home, Piece(kind, Side.white));
    final dots = <int>{};
    for (final m in pos.pseudo(Side.white, attacks: true)) {
      dots.add(m.to);
    }
    if (kind == Kind.trey) {
      dots
        ..clear()
        ..addAll([home + 8, home + 7, home + 9]);
    }
    if (kind == Kind.ang) {
      for (final d in const [
        [1, 2],
        [-1, 2]
      ]) {
        dots.add((home ~/ 8 + d[1]) * 8 + home % 8 + d[0]);
      }
    }
    return BoardView(pos: pos, targets: dots, showCoords: false);
  }
}

class _PromotionPractice extends StatefulWidget {
  const _PromotionPractice();
  @override
  State<_PromotionPractice> createState() => _PromotionPracticeState();
}

class _PromotionPracticeState extends State<_PromotionPractice> {
  static const _start = 4 * 8 + 5; // f5
  static const _goal = 5 * 8 + 5; // f6
  int stage = 0; // 0 pick, 1 move, 2 done

  Position get _pos {
    final base = Position.empty();
    if (stage == 2)
      return base.withPiece(_goal, const Piece(Kind.bompong, Side.white));
    return base.withPiece(_start, const Piece(Kind.trey, Side.white));
  }

  void _tap(int sq) {
    setState(() {
      if (stage == 0 && sq == _start) {
        stage = 1;
      } else if (stage == 1 && sq == _goal) {
        stage = 2;
      } else if (stage == 1) {
        stage = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      BoardView(
        pos: _pos,
        selected: stage == 1 ? _start : null,
        targets: stage == 1 ? {_goal} : const {},
        onTap: _tap,
      ),
      const SizedBox(height: 10),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: card(
            color: stage == 2
                ? C.secondaryContainer.withValues(alpha: .2)
                : C.surfaceLow,
            radius: 12),
        child: Row(children: [
          Icon(stage == 2 ? Icons.check_circle : Icons.touch_app_outlined,
              color: stage == 2 ? C.secondary : C.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              switch (stage) {
                0 => 'Select the Trey on f5.',
                1 => 'Now move it to f6 — the 6th rank.',
                _ => 'Promoted! The Trey became a Trei Bompong.',
              },
              style: body(13, color: C.onSurface),
            ),
          ),
          if (stage == 2)
            TextButton(
                onPressed: () => setState(() => stage = 0),
                child: const Text('Reset')),
        ]),
      ),
    ]);
  }
}
