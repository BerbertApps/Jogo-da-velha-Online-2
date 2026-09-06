import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../theme.dart';
import '../widgets.dart';
import '../i18n/strings.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  // Contagem regressiva para próximos desafios
  int _seconds = 6 * 3600 + 45 * 60 + 12;

  @override
  void initState() {
    super.initState();
    Timer.periodic(const Duration(seconds: 1), (_) {
      if (_seconds > 0 && mounted) {
        setState(() => _seconds--);
      }
    });
  }

  String _fmt(int s) {
    final h = (s ~/ 3600).toString().padLeft(2, '0');
    final m = ((s % 3600) ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$h:$m:$sec';
  }

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
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
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
                        L.fmt('newChallengesIn',
                            {'time': _fmt(_seconds)}),
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
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _challengeTile(
                        text: L.t('win2matches'),
                        progress: '2/2',
                        reward: '',
                        claimed: true,
                      ),
                      const SizedBox(height: 12),
                      _challengeTile(
                        text: L.t('win5matches'),
                        progress: '2/5',
                        reward: L.fmt('diamonds', {'n': '+50'}),
                      ),
                      const SizedBox(height: 12),
                      _challengeTile(
                        text: L.t('make3draws'),
                        progress: '1/3',
                        reward: L.fmt('diamonds', {'n': '+30'}),
                      ),
                      const SizedBox(height: 12),
                      _challengeTile(
                        text: L.t('play1online'),
                        progress: '0/1',
                        reward: L.fmt('diamonds', {'n': '+20'}),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: NeonButton(
                    L.t('redeemAll'),
                    () {},
                    startColor: AppColors.verde,
                    endColor: AppColors.ciano,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _challengeTile({
    required String text,
    required String progress,
    required String reward,
    bool claimed = false,
  }) {
    final parts = progress.split('/');
    final cur = int.tryParse(parts[0]) ?? 0;
    final total = int.tryParse(parts[1]) ?? 1;
    final pct = (cur / total).clamp(0.0, 1.0);
    return NeonCard(
      Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (claimed)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.verde.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.verde),
                    ),
                    child: Text(
                      L.t('claim'),
                      style: const TextStyle(
                        color: AppColors.verde,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  )
                else
                  Text(
                    progress,
                    style: const TextStyle(
                      color: AppColors.ciano,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 6,
                backgroundColor: AppColors.bgCard,
                valueColor: AlwaysStoppedAnimation(
                  claimed ? AppColors.verde : AppColors.ciano,
                ),
              ),
            ),
            if (reward.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                reward,
                style: const TextStyle(
                  color: AppColors.dourado,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
