import 'package:flutter/material.dart';

import '../game/controller.dart';
import '../theme.dart';
import 'match_screen.dart';

class LobbyScreen extends StatelessWidget {
  final VoidCallback onLearn;
  const LobbyScreen({super.key, required this.onLearn});

  void _start(BuildContext context, MatchConfig cfg) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => MatchScreen(cfg: cfg)));
  }

  Future<void> _matchmake(BuildContext context,
      {required String label, required int seconds}) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _MatchmakingDialog(),
    );
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!context.mounted) return;
    Navigator.of(context).pop();
    _start(
      context,
      MatchConfig(
        mode: GameMode.vsAi,
        aiDepth: 2,
        opponent: 'Vannak Kem',
        opponentElo: 1822,
        seconds: seconds,
        label: label,
      ),
    );
  }

  Future<int?> _pickTime(BuildContext context) => showModalBottomSheet<int>(
        context: context,
        backgroundColor: C.surfaceLow,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
        builder: (_) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Time Control', style: serif(20)),
                  const SizedBox(height: 4),
                  Text('Choose how long each player has.', style: body(13)),
                  const SizedBox(height: 14),
                  for (final o in const [
                    (180, 'Blitz', '3 min'),
                    (600, 'Rapid', '10 min'),
                    (900, 'Classical', '15 min')
                  ])
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading:
                          const Icon(Icons.timer_outlined, color: C.primary),
                      title: Text(o.$2,
                          style:
                              body(15, color: C.onSurface, w: FontWeight.w600)),
                      trailing: Text(o.$3, style: mono(14, color: C.primary)),
                      onTap: () => Navigator.of(context).pop(o.$1),
                    ),
                ]),
          ),
        ),
      );

  Future<void> _pickBot(BuildContext context) async {
    final bot = await showModalBottomSheet<MatchConfig>(
      context: context,
      backgroundColor: C.surfaceLow,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Training', style: serif(20)),
                const SizedBox(height: 4),
                Text('Practice against a master bot.', style: body(13)),
                const SizedBox(height: 14),
                for (final b in const [
                  ('Neak Ta', 'Gentle guardian • makes mistakes', 1, 220, 1200),
                  ('Preah Khan', 'Balanced tactician', 2, 40, 1600),
                  ('Angkor', 'Relentless grandmaster', 3, 0, 2000),
                ])
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                        backgroundColor: C.high,
                        child:
                            Icon(Icons.smart_toy_outlined, color: C.primary)),
                    title: Text(b.$1,
                        style:
                            body(15, color: C.onSurface, w: FontWeight.w600)),
                    subtitle: Text(b.$2, style: body(12)),
                    trailing:
                        Text('${b.$5}', style: mono(14, color: C.secondary)),
                    onTap: () => Navigator.of(context).pop(MatchConfig(
                      mode: GameMode.vsAi,
                      aiDepth: b.$3,
                      noise: b.$4,
                      opponent: b.$1,
                      opponentElo: b.$5,
                      seconds: 900,
                      label: 'AI Training',
                    )),
                  ),
              ]),
        ),
      ),
    );
    if (bot != null && context.mounted) _start(context, bot);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        backgroundColor: C.surfaceLow,
        elevation: 0,
        titleSpacing: 16,
        title: Row(children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
                shape: BoxShape.circle, color: C.primaryContainer),
            child: Text('អ',
                style: serif(18, color: C.onPrimary, w: FontWeight.w800)),
          ),
          const SizedBox(width: 10),
          Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: [
                  Text('Ouk Chaktrang', style: serif(18, color: C.primary)),
                  const SizedBox(width: 6),
                  Text('អុកចត្រង្គ', style: body(11, color: C.outline)),
                ]),
                Text('Play Lobby', style: body(11)),
              ]),
        ]),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 14),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
                color: C.high, borderRadius: BorderRadius.circular(20)),
            child: Row(children: [
              const Icon(Icons.monetization_on_outlined,
                  color: C.primary, size: 17),
              const SizedBox(width: 5),
              Text('2,450', style: mono(13, color: C.primary)),
            ]),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          _profileCard(),
          const SizedBox(height: 16),
          _hero(context),
          const SizedBox(height: 20),
          Text('Game Modes', style: serif(20)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: _modeCard(
                icon: Icons.public,
                title: 'Online Arena',
                sub: 'Ranked & casual • 12,480 online',
                onTap: () =>
                    _matchmake(context, label: 'Online Arena', seconds: 600),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _modeCard(
                icon: Icons.people_alt_outlined,
                title: 'Pass & Play',
                sub: 'Two players, one phone',
                onTap: () async {
                  final secs = await _pickTime(context);
                  if (secs != null && context.mounted) {
                    _start(
                      context,
                      MatchConfig(
                        mode: GameMode.passAndPlay,
                        opponent: 'Player 2',
                        opponentElo: 0,
                        seconds: secs,
                        label: 'Pass & Play',
                      ),
                    );
                  }
                },
              ),
            ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: _modeCard(
                icon: Icons.smart_toy_outlined,
                title: 'AI Training',
                sub: 'Neak Ta • Preah Khan • Angkor',
                onTap: () => _pickBot(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _modeCard(
                icon: Icons.extension_outlined,
                title: 'Daily Puzzle',
                sub: 'Endgame tactics',
                onTap: onLearn,
              ),
            ),
          ]),
          const SizedBox(height: 20),
          _tournament(context),
        ],
      ),
    );
  }

  Widget _profileCard() => Container(
        padding: const EdgeInsets.all(14),
        decoration: card(color: C.high, radius: 16),
        child: Column(children: [
          Row(children: [
            Stack(clipBehavior: Clip.none, children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                      colors: [C.primaryContainer, C.woodDark]),
                  border: Border.all(color: C.primary.withValues(alpha: .5)),
                ),
                child: Text('S',
                    style: serif(26, color: C.onPrimary, w: FontWeight.w800)),
              ),
              Positioned(
                right: -4,
                bottom: -4,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: C.primary),
                  child: const Icon(Icons.spa, size: 15, color: C.onPrimary),
                ),
              ),
            ]),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Flexible(
                          child: Text('Sophea Pich',
                              style: serif(20),
                              overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                            color: C.surface,
                            borderRadius: BorderRadius.circular(20)),
                        child: Text('GM',
                            style:
                                body(11, color: C.primary, w: FontWeight.w700)),
                      ),
                    ]),
                    const SizedBox(height: 2),
                    Text.rich(TextSpan(
                      text: 'កំពូលអ្នកលេង ',
                      style: body(12, color: C.primary, w: FontWeight.w600),
                      children: [
                        TextSpan(text: '• Grandmaster Tier', style: body(12))
                      ],
                    )),
                  ]),
            ),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            _stat('ELO', '1,840', C.primary),
            _stat('Win rate', '68.4%', C.secondary),
            _stat('National', '#14', C.onSurface),
          ]),
        ]),
      );

  Widget _stat(String label, String value, Color c) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
              color: C.surface, borderRadius: BorderRadius.circular(12)),
          child: Column(children: [
            Text(value, style: mono(20, color: c)),
            const SizedBox(height: 2),
            Text(label, style: body(11)),
          ]),
        ),
      );

  Widget _hero(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3A2814), C.high],
          ),
          border: Border.all(color: C.primaryContainer.withValues(alpha: .35)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                  color: C.primary.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(20)),
              child: Text('RANKED • RAPID 10+0',
                  style: mono(10, color: C.primary)),
            ),
            const Spacer(),
            const Icon(Icons.shield_outlined, size: 15, color: C.secondary),
            const SizedBox(width: 4),
            Text('Anti-cheat on', style: body(11, color: C.secondary)),
          ]),
          const SizedBox(height: 14),
          Text('Quick Ranked Match', style: serif(26, color: C.primary)),
          const SizedBox(height: 4),
          Text('Face a Grandmaster. One tap, fair rating.', style: body(13)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () =>
                    _matchmake(context, label: 'Ranked • Rapid', seconds: 600),
                style: FilledButton.styleFrom(
                  backgroundColor: C.primary,
                  foregroundColor: C.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Play Now',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
            const SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('~0:08', style: mono(15, color: C.secondary)),
              Text('avg queue', style: body(10)),
            ]),
          ]),
        ]),
      );

  Widget _modeCard({
    required IconData icon,
    required String title,
    required String sub,
    required VoidCallback onTap,
  }) =>
      Material(
        color: C.high,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: C.surface, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: C.primary),
              ),
              const SizedBox(height: 12),
              Text(title, style: serif(16)),
              const SizedBox(height: 3),
              Text(sub,
                  style: body(11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ]),
          ),
        ),
      );

  Widget _tournament(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: card(color: C.high, radius: 16, border: C.outlineVar),
        child: Row(children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient:
                  const LinearGradient(colors: [C.woodDark, Color(0xFF2E1B0C)]),
            ),
            child: const Icon(Icons.emoji_events_outlined,
                color: C.primary, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('SPOTLIGHT', style: mono(10, color: C.secondary)),
              const SizedBox(height: 2),
              Text('32nd SEA Games Championship', style: serif(15)),
              Text('Replay with live commentary', style: body(12)),
            ]),
          ),
          IconButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Replay coming soon'))),
            icon: const Icon(Icons.play_circle_outline,
                color: C.primary, size: 30),
          ),
        ]),
      );
}

class _MatchmakingDialog extends StatelessWidget {
  const _MatchmakingDialog();

  @override
  Widget build(BuildContext context) => Dialog(
        backgroundColor: C.surfaceLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(
              width: 64,
              height: 64,
              child:
                  CircularProgressIndicator(strokeWidth: 4, color: C.primary),
            ),
            const SizedBox(height: 20),
            Text('Finding an opponent…', style: serif(18)),
            const SizedBox(height: 6),
            Text('Matching by rating', style: body(13)),
          ]),
        ),
      );
}
