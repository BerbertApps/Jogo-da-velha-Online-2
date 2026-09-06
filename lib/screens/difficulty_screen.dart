import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../theme.dart';
import '../widgets.dart';
import '../i18n/strings.dart';

class DifficultyScreen extends StatelessWidget {
  const DifficultyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();
    L.lang = state.language;
    return Scaffold(
      body: ParticleLayer(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 12),
                ScreenHeader(title: L.t('difficulty')),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _diffTile(
                        context,
                        icon: Icons.sentiment_satisfied,
                        title: L.t('easy'),
                        desc: L.t('easyDesc'),
                        diff: Difficulty.facil,
                      ),
                      const SizedBox(height: 14),
                      _diffTile(
                        context,
                        icon: Icons.sentiment_neutral,
                        title: L.t('medium'),
                        desc: L.t('mediumDesc'),
                        diff: Difficulty.medio,
                      ),
                      const SizedBox(height: 14),
                      _diffTile(
                        context,
                        icon: Icons.sentiment_dissatisfied,
                        title: L.t('hard'),
                        desc: L.t('hardDesc'),
                        diff: Difficulty.dificil,
                      ),
                      const SizedBox(height: 14),
                      _diffTile(
                        context,
                        icon: Icons.smart_toy,
                        title: L.t('masterTitle'),
                        desc: L.t('masterDesc'),
                        diff: Difficulty.mestre,
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
  }

  Widget _diffTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String desc,
    required Difficulty diff,
  }) {
    final state = context.watch<GameState>();
    final selected = state.difficulty == diff;
    final color = _diffColor(diff);
    return GestureDetector(
      onTap: () {
        state.difficulty = diff;
        state.resetGame();
        Navigator.pop(context);
      },
      child: NeonCard(
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              NeonIconTile(Icon(icon, color: color, size: 28)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: selected ? color : AppColors.branco,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      desc,
                      style: const TextStyle(
                        color: AppColors.textoClaro,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle, color: color, size: 24),
            ],
          ),
        ),
        highlighted: selected,
        borderColor: color,
      ),
    );
  }

  Color _diffColor(Difficulty d) {
    switch (d) {
      case Difficulty.facil:
        return AppColors.verde;
      case Difficulty.medio:
        return AppColors.ciano;
      case Difficulty.dificil:
        return AppColors.roxo;
      case Difficulty.mestre:
        return AppColors.magenta;
    }
  }
}
