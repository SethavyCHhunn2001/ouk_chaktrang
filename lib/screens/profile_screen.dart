import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CardApp());
}

// ───────────────────────────── App ─────────────────────────────

const kBg = Color(0xFFF6F5F3);
const kInk = Color(0xFF111111);
const kMuted = Color(0xFF8E8E93);
const kGreen = Color(0xFF2FB36B);

class CardApp extends StatelessWidget {
  const CardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Slate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: kBg,
        splashFactory: NoSplash.splashFactory,
        colorScheme: ColorScheme.fromSeed(seedColor: kInk),
      ),
      home: const CardPickerScreen(),
    );
  }
}

Route<T> fadeRoute<T>(Widget page) => PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 500),
      reverseTransitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: child,
      ),
    );

double seg(double v, double a, double b, [Curve curve = Curves.easeOut]) =>
    curve.transform(((v - a) / (b - a)).clamp(0.0, 1.0));

// ───────────────────────────── Model ─────────────────────────────

class CardTier {
  final String name;
  final int price;
  final List<Color> colors;
  final Color ink;
  const CardTier(this.name, this.price, this.colors, this.ink);
}

const tiers = <CardTier>[
  CardTier('Silver', 99,
      [Color(0xFFD9D9DB), Color(0xFFB9B9BC), Color(0xFFCFCFD1)], Color(0xFF3A3A3C)),
  CardTier('Platinum', 199,
      [Color(0xFFBDBDBD), Color(0xFF8F8F92), Color(0xFFB0B0B2)], Color(0xFF1C1C1E)),
  CardTier('Gold', 349,
      [Color(0xFFD8C79A), Color(0xFFB79F66), Color(0xFFCDB985)], Color(0xFF2B2415)),
];

// ───────────────────────────── Metal card ─────────────────────────────

class MetalCard extends StatelessWidget {
  final CardTier tier;
  const MetalCard({super.key, required this.tier});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.586,
      child: LayoutBuilder(builder: (context, c) {
        final s = c.maxWidth / 320;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16 * s),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 24 * s,
                offset: Offset(0, 12 * s),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16 * s),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: tier.colors,
                ),
              ),
              child: CustomPaint(
                painter: _BrushedPainter(),
                child: Stack(
                  children: [
                    Positioned(
                      top: 16 * s,
                      right: 18 * s,
                      child: Icon(Icons.contactless_outlined,
                          size: 26 * s, color: tier.ink.withValues(alpha: 0.7)),
                    ),
                    Positioned(
                      left: 20 * s,
                      bottom: 18 * s,
                      child: Text(
                        'DailyFlutterUI',
                        style: TextStyle(
                          fontSize: 11 * s,
                          fontWeight: FontWeight.w500,
                          color: tier.ink.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 20 * s,
                      bottom: 12 * s,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'VISA',
                            style: TextStyle(
                              fontSize: 28 * s,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              height: 1,
                              color: tier.ink,
                            ),
                          ),
                          Text(
                            tier.name,
                            style: TextStyle(
                              fontSize: 8 * s,
                              color: tier.ink.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// Fine horizontal grain to fake brushed metal.
class _BrushedPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = math.Random(3);
    final p = Paint()..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 1.6) {
      final light = r.nextBool();
      p.color = (light ? Colors.white : Colors.black)
          .withValues(alpha: 0.02 + r.nextDouble() * 0.04);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ───────────────────────────── 1. Card picker ─────────────────────────────

class CardPickerScreen extends StatefulWidget {
  const CardPickerScreen({super.key});

  @override
  State<CardPickerScreen> createState() => _CardPickerScreenState();
}

class _CardPickerScreenState extends State<CardPickerScreen> {
  final _pc = PageController(viewportFraction: 0.58, initialPage: 1);
  double _page = 1;

  @override
  void initState() {
    super.initState();
    _pc.addListener(() => setState(() => _page = _pc.page ?? 1));
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  int get _index => _page.round().clamp(0, tiers.length - 1);

  @override
  Widget build(BuildContext context) {
    final tier = tiers[_index];
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () {},
                icon: const Icon(Icons.chevron_left_rounded, size: 30),
              ),
            ),
            const SizedBox(height: 4),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: Column(
                key: ValueKey(tier.name),
                children: [
                  Text(tier.name,
                      style: const TextStyle(
                          fontSize: 26, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text.rich(
                    TextSpan(
                      text: '\$${tier.price}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
                      children: const [
                        TextSpan(
                          text: ' / year',
                          style: TextStyle(
                              color: kMuted, fontWeight: FontWeight.w400),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pc,
                itemCount: tiers.length,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (_) => HapticFeedback.selectionClick(),
                itemBuilder: (_, i) {
                  final d = (_page - i).abs().clamp(0.0, 1.0);
                  return Center(
                    child: Opacity(
                      opacity: 1 - 0.55 * d,
                      child: Transform.scale(
                        scale: 1 - 0.14 * d,
                        child: SizedBox(
                          width: 210,
                          height: 333,
                          child: RotatedBox(
                            quarterTurns: 1,
                            child: MetalCard(tier: tiers[i]),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(tiers.length, (i) {
                final active = i == _index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  width: active ? 18 : 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: active ? kInk : const Color(0xFFD1D1D6),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: kInk,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26)),
                  ),
                  onPressed: () => Navigator.push(
                      context, fadeRoute(ConfirmScreen(tier: tier))),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: Text('Choose ${tier.name}',
                        key: ValueKey(tier.name),
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────── Shared bits ─────────────────────────────

class DetailsCard extends StatelessWidget {
  final List<(String, String)> rows;
  final bool boldLast;
  const DetailsCard({super.key, required this.rows, this.boldLast = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(rows[i].$1,
                      style: TextStyle(
                          fontSize: 12,
                          color: (boldLast && i == rows.length - 1)
                              ? kInk
                              : kMuted)),
                  Text(rows[i].$2,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: (boldLast && i == rows.length - 1)
                              ? FontWeight.w700
                              : FontWeight.w500)),
                ],
              ),
            ),
            if (i != rows.length - 1)
              const Divider(height: 1, color: Color(0xFFEFEFF1)),
          ],
        ],
      ),
    );
  }
}

class PulseDots extends StatefulWidget {
  const PulseDots({super.key});
  @override
  State<PulseDots> createState() => _PulseDotsState();
}

class _PulseDotsState extends State<PulseDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(2, (i) {
          final t = math.sin((_c.value + i * 0.5) * 2 * math.pi);
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 5),
            width: 10 + 2 * t,
            height: 10 + 2 * t,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.55 + 0.35 * t),
            ),
          );
        }),
      ),
    );
  }
}

// ───────────────────────────── 2. Confirm order ─────────────────────────────

class ConfirmScreen extends StatefulWidget {
  final CardTier tier;
  const ConfirmScreen({super.key, required this.tier});

  @override
  State<ConfirmScreen> createState() => _ConfirmScreenState();
}

class _ConfirmScreenState extends State<ConfirmScreen> {
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) setState(() => _processing = true);
    });
    Future.delayed(const Duration(milliseconds: 4200), () {
      if (mounted) {
        Navigator.pushReplacement(
            context, fadeRoute(SuccessScreen(tier: widget.tier)));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tier;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _processing ? 0.25 : 1,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                  onPressed: _processing ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.chevron_left_rounded, size: 30),
                ),
              ),
              const SizedBox(height: 8),
              const Text('Confirm order',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              const Text('Review your new card before you pay.',
                  style: TextStyle(fontSize: 12, color: kMuted)),
              const SizedBox(height: 20),
              MetalCard(tier: t),
              const SizedBox(height: 18),
              DetailsCard(
                boldLast: true,
                rows: [
                  ('Card', '${t.name} metal'),
                  ('Annual fee', '\$${t.price}.00'),
                  ('Delivery', 'Free · 5–7 days'),
                  ('Total today', '\$${t.price}.00'),
                ],
              ),
              const Spacer(),
              Center(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 400),
                  opacity: _processing ? 1 : 0,
                  child: Column(
                    children: [
                      Container(
                        width: 88,
                        height: 46,
                        decoration: BoxDecoration(
                          color: kInk,
                          borderRadius: BorderRadius.circular(23),
                        ),
                        child: const Center(child: PulseDots()),
                      ),
                      const SizedBox(height: 12),
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_user_outlined,
                              size: 12, color: kMuted),
                          SizedBox(width: 5),
                          Text('Confirming your payment…',
                              style: TextStyle(fontSize: 11, color: kMuted)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────── 3. Order placed ─────────────────────────────

class PosTerminal extends StatelessWidget {
  final double check; // 0..1
  const PosTerminal({super.key, required this.check});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2C2C2E), Color(0xFF111111)],
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 30,
              offset: const Offset(0, 16)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Transform.scale(
                scale: check,
                child: const Icon(Icons.check_rounded, color: kGreen, size: 36),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(
              12,
              (i) => Container(
                width: 58,
                height: 20,
                decoration: BoxDecoration(
                  color: i == 11 ? kGreen : const Color(0xFF48484A),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SuccessScreen extends StatefulWidget {
  final CardTier tier;
  const SuccessScreen({super.key, required this.tier});

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2600))
    ..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tier;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, __) {
              final v = _c.value;
              final drop = seg(v, 0.0, 0.45, Curves.easeInOutCubic);
              final check = seg(v, 0.45, 0.6, Curves.elasticOut);
              final text = seg(v, 0.55, 0.8);
              final btn = seg(v, 0.75, 1.0);
              return Column(
                children: [
                  const Spacer(),
                  SizedBox(
                    height: 270,
                    width: 260,
                    child: Stack(
                      alignment: Alignment.topCenter,
                      children: [
                        Positioned(bottom: 0, child: PosTerminal(check: check)),
                        Positioned(
                          top: -40 + 100 * drop,
                          child: Transform.rotate(
                            angle: -0.22,
                            child: SizedBox(
                                width: 150, child: MetalCard(tier: t)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Opacity(
                    opacity: text,
                    child: Transform.translate(
                      offset: Offset(0, 12 * (1 - text)),
                      child: Column(
                        children: [
                          const Text('Order placed',
                              style: TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Text(
                            'Your ${t.name} card is on its way.\n'
                            "We'll let you know the moment it ships.",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 12, color: kMuted, height: 1.4),
                          ),
                          const SizedBox(height: 20),
                          DetailsCard(rows: [
                            ('Paid', '\$${t.price}.00'),
                            ('Arrives', '5–7 business days'),
                          ]),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  Opacity(
                    opacity: btn,
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: kInk,
                              side: BorderSide.none,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25)),
                            ),
                            onPressed: btn < 1
                                ? null
                                : () => Navigator.push(context,
                                    fadeRoute(ReceiptScreen(tier: t))),
                            icon: const Icon(Icons.receipt_long_outlined,
                                size: 16),
                            label: const Text('View receipt',
                                style: TextStyle(fontSize: 13)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: kInk,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25)),
                            ),
                            onPressed: () => Navigator.popUntil(
                                context, (r) => r.isFirst),
                            child: const Text('Done',
                                style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w500)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────── 4. Receipt ─────────────────────────────

class ReceiptScreen extends StatefulWidget {
  final CardTier tier;
  const ReceiptScreen({super.key, required this.tier});

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 4200))
    ..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tier;
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0F),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) {
            final v = _c.value;
            final print = seg(v, 0.05, 0.7, Curves.easeInOutSine);
            final stamp = seg(v, 0.74, 0.86, Curves.elasticOut);
            final done = seg(v, 0.88, 1.0);
            final printing = 1 - seg(v, 0.7, 0.8);
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.chevron_left_rounded,
                            color: Colors.white70, size: 30),
                      ),
                      const Expanded(
                        child: Text('Receipt',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                const _PrinterHead(),
                // Paper emerges from the slot: bottom edge leads.
                ClipRect(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    heightFactor: print,
                    child: _Paper(tier: t, stamp: stamp),
                  ),
                ),
                const Spacer(),
                Opacity(
                  opacity: printing,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.print_outlined, size: 12, color: Colors.white38),
                      SizedBox(width: 6),
                      Text('Printing your receipt…',
                          style: TextStyle(fontSize: 11, color: Colors.white38)),
                    ],
                  ),
                ),
                Opacity(
                  opacity: done,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white24),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24)),
                              ),
                              onPressed:
                                  done < 1 ? null : () => _c.forward(from: 0),
                              icon: const Icon(Icons.print_outlined, size: 16),
                              label: const Text('Print again',
                                  style: TextStyle(fontSize: 13)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: kInk,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24)),
                              ),
                              onPressed: () => Navigator.popUntil(
                                  context, (r) => r.isFirst),
                              child: const Text('Done',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PrinterHead extends StatelessWidget {
  const _PrinterHead();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 286,
      height: 40,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF0F0F0), Color(0xFFC9C9CC)],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SLATE',
              style: TextStyle(
                  fontSize: 7, letterSpacing: 2, color: Color(0xFF9A9A9E))),
          Container(
            width: 5,
            height: 5,
            decoration:
                const BoxDecoration(color: kGreen, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }
}

class _Paper extends StatelessWidget {
  final CardTier tier;
  final double stamp; // 0..1
  const _Paper({required this.tier, required this.stamp});

  static const _mono = TextStyle(
      fontFamily: 'Courier', fontSize: 9, color: Color(0xFF444444), height: 1.5);
  static const _months = [
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
  ];

  Widget _row(String l, String r, {TextStyle? style}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 1.5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l, style: style ?? _mono),
            Text(r, style: style ?? _mono),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final date = '${now.day} ${_months[now.month - 1]} ${now.year} · '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final price = '\$${tier.price}.00';
    return ClipPath(
      clipper: _ZigZagClipper(),
      child: Container(
        width: 250,
        color: const Color(0xFFF7F6F2),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('SLATE',
                    style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 20,
                        letterSpacing: 6,
                        color: kInk)),
                const Text('CARD ORDER RECEIPT',
                    style: TextStyle(
                        fontSize: 6, letterSpacing: 1.5, color: kMuted)),
                const SizedBox(height: 10),
                const _Dashed(),
                const SizedBox(height: 6),
                _row('RECEIPT', 'SL-260919-1090'),
                _row('DATE', date),
                _row('CARDHOLDER', 'DAILYFLUTTERUI'),
                const SizedBox(height: 6),
                const _Dashed(),
                const SizedBox(height: 6),
                _row('${tier.name} metal card', price,
                    style: _mono.copyWith(fontWeight: FontWeight.w700)),
                _row('Annual fee · billed yearly', ''),
                _row('Card issuance', 'FREE'),
                _row('Delivery · 5–7 days', 'FREE'),
                const SizedBox(height: 6),
                Container(height: 1, color: kInk),
                const SizedBox(height: 8),
                _row('TOTAL', price,
                    style: const TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: kInk)),
                _row('PAID BY VISA', 'APPROVED',
                    style: _mono.copyWith(fontSize: 7, color: kMuted)),
                const SizedBox(height: 14),
                SizedBox(
                  height: 38,
                  width: double.infinity,
                  child: CustomPaint(painter: _BarcodePainter()),
                ),
                const SizedBox(height: 4),
                Text('SL-260919-1090',
                    style: _mono.copyWith(fontSize: 6, letterSpacing: 2)),
                const SizedBox(height: 10),
                const Text('Thank you for choosing Slate.',
                    style: TextStyle(
                        fontFamily: 'Georgia',
                        fontStyle: FontStyle.italic,
                        fontSize: 11,
                        color: Color(0xFF333333))),
              ],
            ),
            Positioned(
              right: 4,
              top: 148,
              child: Opacity(
                opacity: stamp.clamp(0.0, 1.0),
                child: Transform.rotate(
                  angle: -0.3,
                  child: Transform.scale(
                    scale: 1.6 - 0.6 * stamp,
                    child: const _PaidStamp(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaidStamp extends StatelessWidget {
  const _PaidStamp();

  @override
  Widget build(BuildContext context) {
    const c = Color(0xFF2E8B57);
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: c.withValues(alpha: 0.75), width: 2),
      ),
      child: Center(
        child: Text('PAID',
            style: TextStyle(
                color: c.withValues(alpha: 0.8),
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 1)),
      ),
    );
  }
}

class _Dashed extends StatelessWidget {
  const _Dashed();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, c) {
      final n = (c.maxWidth / 5).floor();
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(
            n, (_) => Container(width: 3, height: 1, color: const Color(0xFFBBBBBB))),
      );
    });
  }
}

class _BarcodePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = math.Random(7);
    final p = Paint()..color = kInk;
    double x = 0;
    while (x < size.width) {
      final w = 1.0 + r.nextInt(3);
      canvas.drawRect(Rect.fromLTWH(x, 0, math.min(w, size.width - x), size.height), p);
      x += w + 1 + r.nextInt(3);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _ZigZagClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size s) {
    const depth = 5.0;
    final n = (s.width / 8).floor();
    final step = s.width / n;
    final p = Path()
      ..moveTo(0, 0)
      ..lineTo(s.width, 0)
      ..lineTo(s.width, s.height - depth);
    for (int i = 0; i < n; i++) {
      p.lineTo(s.width - step * (i + 0.5), s.height);
      p.lineTo(s.width - step * (i + 1), s.height - depth);
    }
    return p..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> old) => false;
}