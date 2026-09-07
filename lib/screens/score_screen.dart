import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../models/player_record.dart';
import '../theme.dart';
import '../widgets.dart';
import '../i18n/strings.dart';
import 'profile_screen.dart';

class ScoreScreen extends StatelessWidget {
  const ScoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();
    L.lang = state.language;
    final players = [...state.players]
      ..sort((a, b) {
        final byWins = b.wins.compareTo(a.wins);
        if (byWins != 0) return byWins;
        return b.diamonds.compareTo(a.diamonds);
      });

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: ParticleLayer(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  ScreenHeader(title: L.t('score')),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.center,
                    child: _diamondsBadge(state.diamonds),
                  ),
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
                  const SizedBox(height: 12),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _rankingList(context, state, players),
                        _friendsPlaceholder(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _diamondsBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.dourado, Color(0xFFFFAA00)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.diamond, color: Color(0xFF3B2A00), size: 16),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: const TextStyle(
              color: Color(0xFF3B2A00),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _rankingList(
      BuildContext context, GameState state, List<PlayerRecord> players) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 12),
      children: [
        _profileCard(context, state),
        const SizedBox(height: 14),
        if (players.isEmpty)
          Text(
            L.t('noPlayers'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textoClaro, height: 1.5),
          )
        else
          for (var i = 0; i < players.length; i++) ...[
            _rankingRow(players[i], i + 1),
            const SizedBox(height: 8),
          ],
      ],
    );
  }

  Widget _profileCard(BuildContext context, GameState state) {
    return NeonCard(
      InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        ),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.ciano, AppColors.roxo],
                  ),
                ),
                child: Text(
                  state.avatar,
                  style: const TextStyle(fontSize: 30),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.playerName.isEmpty ? 'Jogador' : state.playerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _statChip('${state.wins}', L.t('wins'), AppColors.verde),
                        const SizedBox(width: 8),
                        _statChip('${state.ties}', L.t('draws'), AppColors.ciano),
                        const SizedBox(width: 8),
                        _statChip('${state.losses}', L.t('losses'),
                            AppColors.magenta),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.edit, color: AppColors.textoClaro, size: 18),
            ],
          ),
        ),
      ),
      borderColor: AppColors.ciano,
      highlighted: true,
    );
  }

  Widget _statChip(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Text(
        '$value $label',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _rankingRow(PlayerRecord p, int rank) {
    final isYou = p.isSelf;
    return NeonCard(
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 30,
              child: rank <= 3
                  ? _medalIcon(rank)
                  : Text(
                      '$rank',
                      style: const TextStyle(
                        color: AppColors.textoClaro,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.bgCard,
                border: Border.all(color: AppColors.azulNeon, width: 1),
              ),
              child: Text(p.avatar, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isYou ? '${p.name} (${L.t('you')})' : p.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isYou ? AppColors.ciano : Colors.white,
                      fontSize: 14,
                      fontWeight: isYou ? FontWeight.w900 : FontWeight.w600,
                      shadows: isYou
                          ? [Shadow(color: AppColors.ciano, blurRadius: 8)]
                          : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${p.wins} ${L.t('wins')}  •  ${p.ties} ${L.t('draws')}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textoClaro,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.diamond, color: AppColors.dourado, size: 15),
            const SizedBox(width: 4),
            Text(
              '${p.diamonds}',
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
  }

  Widget _medalIcon(int rank) {
    Color color;
    switch (rank) {
      case 1:
        color = AppColors.dourado;
        break;
      case 2:
        color = const Color(0xFFC0C0C0);
        break;
      default:
        color = const Color(0xFFCD7F32);
    }
    return Icon(Icons.emoji_events, color: color, size: 20);
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