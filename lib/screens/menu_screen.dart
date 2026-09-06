import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../theme.dart';
import '../widgets.dart';
import '../widgets/ad_banner.dart';
import '../i18n/strings.dart';
import 'difficulty_screen.dart';
import 'game_mode_screen.dart';
import 'score_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

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
                const SizedBox(height: 30),
                NeonTitle(L.t('appTitle'), fontSize: 34, uppercase: true),
                const SizedBox(height: 40),
                NeonButton(L.t('play'), () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GameModeScreen()),
                  );
                }, height: 64, fontSize: 24),
                const SizedBox(height: 40),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _menuTile(
                        context,
                        icon: Icons.sports_esports,
                        label: L.t('gameMode'),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const GameModeScreen()),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _menuTile(
                        context,
                        icon: Icons.speed,
                        label: L.t('difficulty'),
                        value: L.difficulty(state.difficulty),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const DifficultyScreen()),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _menuTile(
                        context,
                        icon: Icons.emoji_events,
                        label: L.t('score'),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ScoreScreen()),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _menuTile(
                        context,
                        icon: Icons.settings,
                        label: L.t('settings'),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SettingsScreen()),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _footerIcon(Icons.emoji_events, AppColors.dourado, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ScoreScreen()),
                        );
                      }),
                      _footerIcon(Icons.star, AppColors.ciano, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const StatsScreen()),
                        );
                      }),
                      _footerIcon(Icons.share, AppColors.magenta, () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(L.t('shareLink')),
                            backgroundColor: AppColors.bgCard,
                          ),
                        );
                      }),
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

  Widget _footerIcon(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.bgCard.withValues(alpha: 0.6),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 10),
          ],
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }

  Widget _menuTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    String? value,
  }) {
    return NeonCard(
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              NeonIconTile(Icon(icon, color: AppColors.ciano, size: 24)),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.branco,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
              if (value != null)
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.magenta,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: AppColors.textoClaro),
            ],
          ),
        ),
      ),
    );
  }
}
