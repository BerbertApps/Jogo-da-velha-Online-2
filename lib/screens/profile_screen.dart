import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/avatars.dart';
import '../models/game_state.dart';
import '../theme.dart';
import '../widgets.dart';
import '../i18n/strings.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _previewAvatar;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<GameState>();
    L.lang = s.language;
    final preview = _previewAvatar ?? s.avatar;

    return Scaffold(
      body: ParticleLayer(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 12),
                ScreenHeader(title: L.t('profile')),
                const SizedBox(height: 24),
                _avatarPreview(preview, s.playerName.isEmpty ? 'Jogador' : s.playerName),
                const SizedBox(height: 16),
                NeonButton(
                  L.t('randomPhoto'),
                  () {
                    setState(() => _previewAvatar = randomAvatar());
                  },
                  icon: Icons.casino,
                  height: 50,
                  fontSize: 15,
                ),
                const SizedBox(height: 8),
                NeonButton(
                  L.t('savePhoto'),
                  () {
                    s.updateProfile(setAvatar: preview);
                    setState(() => _previewAvatar = null);
                    _feedback(context, L.t('photoSaved'));
                  },
                  startColor: AppColors.verde,
                  endColor: AppColors.ciano,
                  height: 50,
                  fontSize: 15,
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _nameCard(context, s),
                      const SizedBox(height: 12),
                      _diamondCard(s),
                      const SizedBox(height: 12),
                      NeonCard(
                        InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SettingsScreen(),
                            ),
                          ),
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            child: Row(
                              children: [
                                NeonIconTile(
                                  const Icon(Icons.tune,
                                      color: AppColors.magenta, size: 24),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    L.t('fullSettings'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.chevron_right,
                                    color: AppColors.textoClaro),
                              ],
                            ),
                          ),
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
  }

  Widget _avatarPreview(String avatar, String name) {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF00E5FF), Color(0xFF9B00FF)],
            ),
            border: Border.all(color: AppColors.ciano, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.ciano.withValues(alpha: 0.5),
                blurRadius: 24,
              ),
            ],
          ),
          child: Center(
            child: Text(avatar, style: const TextStyle(fontSize: 60)),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _nameCard(BuildContext context, GameState s) {
    return NeonCard(
      InkWell(
        onTap: () => _editName(context),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              NeonIconTile(const Icon(Icons.badge, color: AppColors.ciano, size: 24)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      L.t('playerName'),
                      style: const TextStyle(
                        color: AppColors.textoClaro,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s.playerName.isEmpty ? 'Jogador' : s.playerName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.edit, color: AppColors.magenta, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _diamondCard(GameState s) {
    return NeonCard(
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            NeonIconTile(
              const Icon(Icons.diamond, color: AppColors.dourado, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                L.t('myDiamonds'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '${s.diamonds}',
              style: const TextStyle(
                color: AppColors.dourado,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editName(BuildContext context) async {
    final s = context.read<GameState>();
    final controller = TextEditingController(
      text: s.playerName.isEmpty ? 'Jogador' : s.playerName,
    );
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.ciano),
        ),
        title: Text(
          L.t('editName'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        content: TextField(
          controller: controller,
          maxLength: 16,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: L.t('playerName'),
            hintStyle: const TextStyle(color: AppColors.textoClaro),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              L.t('cancel'),
              style: const TextStyle(color: AppColors.textoClaro),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(
              L.t('save'),
              style: const TextStyle(color: AppColors.verde),
            ),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty && mounted) {
      s.updateProfile(name: result);
    }
  }

  void _feedback(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.bgCard,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}