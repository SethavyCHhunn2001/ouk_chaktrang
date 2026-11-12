import 'package:flutter/material.dart';

import '../theme.dart';
import 'engine.dart';

/// A carved wooden playing piece. Khmer initial on a bronze/teak disc.
class PieceDisc extends StatelessWidget {
  final Piece piece;
  final double? size;
  const PieceDisc(this.piece, {super.key, this.size});

  @override
  Widget build(BuildContext context) {
    final white = piece.side == Side.white;
    final disc = Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-.3, -.4),
          colors: white
              ? const [Color(0xFFFFF3DF), Color(0xFFD2AE7C)]
              : const [Color(0xFF5A3F2A), Color(0xFF1A110A)],
        ),
        border: Border.all(
          color: piece.kind == Kind.bompong
              ? C.secondary
              : (white ? const Color(0xFF8A6238) : C.primaryContainer),
          width: piece.kind == Kind.bompong ? 2.2 : 1.2,
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 3, offset: Offset(0, 2))
        ],
      ),
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: FittedBox(
          child: Text(
            piece.glyph,
            style: TextStyle(
              color: white ? const Color(0xFF3B2410) : C.primary,
              fontWeight: FontWeight.w800,
              fontSize: 40,
            ),
          ),
        ),
      ),
    );
    if (size != null) return SizedBox(width: size, height: size, child: disc);
    return FractionallySizedBox(
        widthFactor: .84, heightFactor: .84, child: disc);
  }
}

/// 8x8 board. Pass [onTap] = null for a read-only board (replay / diagrams).
class BoardView extends StatelessWidget {
  final Position pos;
  final int? selected;
  final Set<int> targets;
  final Move? last;
  final void Function(int sq)? onTap;
  final bool showCoords;

  const BoardView({
    super.key,
    required this.pos,
    this.selected,
    this.targets = const {},
    this.last,
    this.onTap,
    this.showCoords = true,
  });

  @override
  Widget build(BuildContext context) {
    final checkSq = pos.inCheck(pos.turn) ? pos.kingSq(pos.turn) : -1;
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF5A3A1E), Color(0xFF2E1B0C)],
          ),
          border: Border.all(
              color: C.primaryContainer.withValues(alpha: .55), width: 1.4),
          boxShadow: const [
            BoxShadow(
                color: Colors.black54, blurRadius: 18, offset: Offset(0, 8))
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Column(
            children: [
              for (var r = 7; r >= 0; r--)
                Expanded(
                  child: Row(
                    children: [
                      for (var f = 0; f < 8; f++)
                        Expanded(child: _cell(r, f, checkSq)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cell(int r, int f, int checkSq) {
    final sq = r * 8 + f;
    final light = (r + f) % 2 == 1;
    final base = light ? C.woodLight : C.woodDark;
    final piece = pos.board[sq];
    final isLast = last != null && (last!.from == sq || last!.to == sq);
    final isTarget = targets.contains(sq);
    final coordColor = light ? C.woodDark : C.woodLight;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap == null ? null : () => onTap!(sq),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: base),
          if (isLast) ColoredBox(color: C.primary.withValues(alpha: .38)),
          if (sq == selected)
            Container(
              decoration: BoxDecoration(
                color: C.secondary.withValues(alpha: .35),
                border: Border.all(color: C.secondary, width: 2),
              ),
            ),
          if (sq == checkSq)
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                    colors: [Color(0xCCFF5449), Color(0x00FF5449)]),
              ),
            ),
          if (showCoords && f == 0)
            Positioned(
              left: 2,
              top: 1,
              child: Text('${r + 1}',
                  style: TextStyle(
                      fontSize: 8,
                      color: coordColor,
                      fontWeight: FontWeight.w700)),
            ),
          if (showCoords && r == 0)
            Positioned(
              right: 2,
              bottom: 0,
              child: Text('abcdefgh'[f],
                  style: TextStyle(
                      fontSize: 8,
                      color: coordColor,
                      fontWeight: FontWeight.w700)),
            ),
          if (piece != null) Center(child: PieceDisc(piece)),
          if (isTarget)
            Center(
              child: piece == null
                  ? Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                          color: C.secondaryContainer.withValues(alpha: .9),
                          shape: BoxShape.circle),
                    )
                  : FractionallySizedBox(
                      widthFactor: .92,
                      heightFactor: .92,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: C.error, width: 2.4),
                        ),
                      ),
                    ),
            ),
        ],
      ),
    );
  }
}
