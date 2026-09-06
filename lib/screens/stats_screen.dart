import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../theme.dart';
import '../widgets.dart';
import '../i18n/strings.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<GameState>();
    L.lang = s.language;
    final winRate = s.totalGames == 0
        ? 0
        : ((s.wins + s.ties * 0.5) / s.totalGames * 100).round();

    return Scaffold(
      body: ParticleLayer(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 12),
                ScreenHeader(title: L.t('stats')),
                const SizedBox(height: 24),
                // Círculo de desempenho
                _winRing(winRate),
                const SizedBox(height: 24),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _statCard(Icons.extension, L.t('totalMatches'), s.totalGames,
                          AppColors.ciano),
                      _statCard(Icons.emoji_events, L.t('wins'), s.wins,
                          AppColors.ciano),
                      _statCard(Icons.handshake, L.t('draws'), s.ties,
                          AppColors.roxo),
                      _statCard(Icons.close, L.t('losses'), s.losses,
                          AppColors.magenta),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _winRing(int rate) {
    return Column(
      children: [
        SizedBox(
          width: 160,
          height: 160,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: rate / 100,
                strokeWidth: 12,
                backgroundColor: AppColors.bgCard,
                valueColor: const AlwaysStoppedAnimation(AppColors.ciano),
                strokeCap: StrokeCap.round,
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$rate%',
                      style: const TextStyle(
                        color: AppColors.ciano,
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        shadows: [Shadow(color: AppColors.ciano, blurRadius: 14)],
                      ),
                    ),
                    Text(
                      L.t('winRate'),
                      style: const TextStyle(
                        color: AppColors.textoClaro,
                        fontSize: 11,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statCard(IconData icon, String label, int value, Color color) {
    return NeonCard(
      Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 10),
            Text(
              '$value',
              style: TextStyle(
                color: color,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                shadows: [Shadow(color: color, blurRadius: 12)],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textoClaro,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
      borderColor: color,
    );
  }
}
