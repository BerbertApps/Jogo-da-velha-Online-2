import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../theme.dart';
import '../widgets.dart';
import '../i18n/strings.dart';

class _Challenge {
  final String id;
  final String labelKey;
  final int target;
  final int reward;
  int Function(GameState s) current;

  _Challenge(
      {required this.id,
      required this.labelKey,
      required this.target,
      required this.reward,
      required this.current});
}

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  late Timer _timer;
  Duration _untilMidnight = const Duration();

  @override
  void initState() {
    super.initState();
    _computeMidnight();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _computeMidnight() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    _untilMidnight = tomorrow.difference(now);
  }

  void _tick() {
    if (!mounted) return;
    final s = context.read<GameState>();
    if (_untilMidnight.inSeconds <= 1) {
      s.checkDailyReset();
      _computeMidnight();
    } else {
      setState(() => _untilMidnight -= const Duration(seconds: 1));
    }
  }

  String _fmt(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final sec = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$sec';
  }

  List<_Challenge> _challenges() => [
        _Challenge(
          id: 'win2',
          labelKey: 'win2matches',
          target: 2,
          reward: 20,
          current: (s) => s.dailyWins,
        ),
        _Challenge(
          id: 'win5',
          labelKey: 'win5matches',
          target: 5,
          reward: 50,
          current: (s) => s.dailyWins,
        ),
        _Challenge(
          id: 'draw3',
          labelKey: 'make3draws',
          target: 3,
          reward: 30,
          current: (s) => s.dailyDraws,
        ),
        _Challenge(
          id: 'online1',
          labelKey: 'play1online',
          target: 1,
          reward: 20,
          current: (s) => s.dailyOnlineGames,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final s = context.watch<GameState>();
    L.lang = s.language;
    return Scaffold(
      body: ParticleLayer(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 12),
                ScreenHeader(title: L.t('dailyChallenges')),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.azulNeon, width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.timer, color: AppColors.ciano, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        L.fmt('newChallengesIn', {'time': _fmt(_untilMidnight)}),
                        style: const TextStyle(
                          color: AppColors.ciano,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.diamond, color: AppColors.dourado, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      '${s.diamonds}',
                      style: const TextStyle(
                        color: AppColors.dourado,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      L.t('myDiamonds'),
                      style: const TextStyle(
                        color: AppColors.textoClaro,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: _challenges().map((c) {
                      final cur = c.current(s);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _challengeTile(s, c, cur),
                      );
                    }).toList(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _redeemAllButton(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _challengeTile(GameState s, _Challenge c, int cur) {
    final done = cur >= c.target;
    final claimed = s.isChallengeClaimed(c.id);
    final pct = (cur / c.target).clamp(0.0, 1.0);

    return NeonCard(
      Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.diamond, color: AppColors.dourado, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    L.t(c.labelKey),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 6,
                      backgroundColor: AppColors.bgCard,
                      valueColor: AlwaysStoppedAnimation(
                        claimed || done ? AppColors.verde : AppColors.ciano,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 42,
                  child: Text(
                    '$cur/${c.target}',
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      color: AppColors.textoClaro,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  L.fmt('diamonds', {'n': '+${c.reward}'}),
                  style: const TextStyle(
                    color: AppColors.dourado,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (claimed)
                  _statusChip(
                    L.t('claimed'),
                    Colors.grey,
                    const Icon(Icons.check_circle, size: 15, color: Colors.grey),
                  )
                else if (done)
                  _claimButton(
                    L.fmt('claimReward', {'n': '${c.reward}'}),
                    () => s.claimChallenge(c.id, c.reward),
                  )
                else
                  const SizedBox.shrink(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String label, Color color, Widget icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _claimButton(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.verde, AppColors.ciano],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.workspace_premium, size: 15, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _redeemAllButton(BuildContext context) {
    final s = context.read<GameState>();
    var totalReward = 0;
    var any = false;
    for (final c in _challenges()) {
      if (c.current(s) >= c.target && !s.isChallengeClaimed(c.id)) {
        any = true;
        totalReward += c.reward;
      }
    }
    return NeonButton(
      any
          ? L.fmt('claimReward', {'n': '+$totalReward'})
          : L.t('redeemAllDone'),
      () {
        if (!any) return;
        for (final c in _challenges()) {
          if (c.current(s) >= c.target && !s.isChallengeClaimed(c.id)) {
            s.claimChallenge(c.id, c.reward);
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              L.fmt('claimReward', {'n': '+$totalReward'}),
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: AppColors.bgCard,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      startColor: AppColors.verde,
      endColor: AppColors.ciano,
    );
  }
}