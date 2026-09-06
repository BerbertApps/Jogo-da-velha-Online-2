import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../theme.dart';
import '../widgets.dart';
import '../i18n/strings.dart';
import 'game_screen.dart';
import 'online_screen.dart';
import 'challenges_screen.dart';

class GameModeScreen extends StatelessWidget {
  const GameModeScreen({super.key});

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
                ScreenHeader(title: L.t('gameMode')),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _modeTile(
                        context,
                        icon: Icons.smart_toy,
                        title: L.t('vsAI'),
                        desc: L.t('vsAIDesc'),
                        onTap: () {
                          state.mode = GameMode.vsAI;
                          state.resetGame();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const GameScreen()),
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      _modeTile(
                        context,
                        icon: Icons.people,
                        title: L.t('vsFriend'),
                        desc: L.t('vsFriendDesc'),
                        onTap: () {
                          state.mode = GameMode.vsFriend;
                          state.resetGame();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const GameScreen()),
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      _modeTile(
                        context,
                        icon: Icons.public,
                        title: L.t('online'),
                        desc: L.t('onlineDesc'),
                        onTap: () {
                          state.mode = GameMode.online;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const OnlineScreen()),
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      _modeTile(
                        context,
                        icon: Icons.track_changes,
                        title: L.t('dailyChallenges'),
                        desc: L.t('dailyChallengesDesc'),
                        highlighted: true,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ChallengesScreen()),
                          );
                        },
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

  Widget _modeTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String desc,
    required VoidCallback onTap,
    bool highlighted = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: NeonCard(
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              NeonIconTile(
                Icon(icon,
                    color: highlighted ? AppColors.magenta : AppColors.ciano,
                    size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: highlighted ? AppColors.magenta : AppColors.branco,
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
                        letterSpacing: 1,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.textoClaro),
            ],
          ),
        ),
        highlighted: highlighted,
      ),
    );
  }
}
