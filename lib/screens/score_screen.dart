import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../theme.dart';
import '../widgets.dart';
import '../i18n/strings.dart';

class ScoreScreen extends StatelessWidget {
  const ScoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();
    L.lang = state.language;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: ParticleLayer(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  ScreenHeader(title: L.t('score')),
                  const SizedBox(height: 10),
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppColors.azulNeon, width: 1),
                    ),
                    child: TabBar(
                      indicator: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF00E5FF),
                            Color(0xFF9B00FF),
                          ],
                        ),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelColor: Colors.white,
                      unselectedLabelColor: AppColors.textoClaro,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                      tabs: [
                        Tab(text: L.t('global')),
                        Tab(text: L.t('friends')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _rankingList(),
                        _friendsPlaceholder(),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: NeonButton(L.t('seeAll'), () {}),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _rankingList() {
    final rows = [
      ['1', 'Jogador Mestre', '1520', 'gold'],
      ['2', 'XxDestroyerX', '1450', 'silver'],
      ['3', 'O Gênio', '1380', 'bronze'],
      ['4', L.t('you'), '1250', 'you'],
      ['5', 'NeonPlayer', '1100', ''],
      ['6', 'TicTacPro', '980', ''],
      ['7', 'VelhaKing', '850', ''],
    ];
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: rows.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final r = rows[i];
        final isYou = r[3] == 'you';
        final medal = r[3];
        return NeonCard(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 34,
                  child: medal == ''
                      ? Text(
                          r[0],
                          style: const TextStyle(
                            color: AppColors.textoClaro,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        )
                      : _medalIcon(medal),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    r[1],
                    style: TextStyle(
                      color: isYou ? AppColors.ciano : Colors.white,
                      fontSize: 15,
                      fontWeight: isYou ? FontWeight.w900 : FontWeight.w600,
                      shadows: isYou
                          ? [Shadow(color: AppColors.ciano, blurRadius: 8)]
                          : null,
                    ),
                  ),
                ),
                Text(
                  r[2],
                  style: const TextStyle(
                    color: AppColors.dourado,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          borderColor: isYou ? AppColors.ciano : AppColors.azulNeon,
          highlighted: isYou,
        );
      },
    );
  }

  Widget _medalIcon(String m) {
    IconData icon;
    Color color;
    switch (m) {
      case 'gold':
        icon = Icons.emoji_events;
        color = AppColors.dourado;
        break;
      case 'silver':
        icon = Icons.emoji_events;
        color = const Color(0xFFC0C0C0);
        break;
      default:
        icon = Icons.emoji_events;
        color = const Color(0xFFCD7F32);
    }
    return Icon(icon, color: color, size: 22);
  }

  Widget _friendsPlaceholder() {
    return Center(
      child: Text(
        L.t('noFriends'),
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.textoClaro, height: 1.5),
      ),
    );
  }
}
