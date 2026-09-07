import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../theme.dart';
import '../widgets.dart';
import '../i18n/strings.dart';
import 'difficulty_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<GameState>();
    L.lang = s.language;
    return Scaffold(
      body: ParticleLayer(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 12),
                ScreenHeader(title: L.t('settings')),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _toggleTile(
                        context,
                        icon: Icons.volume_up,
                        label: L.t('sound'),
                        value: s.sound,
                        onChanged: (v) {
                          s.sound = v;
                          s.saveSettings();
                          s.notifyListeners();
                        },
                      ),
                      const SizedBox(height: 10),
                      _toggleTile(
                        context,
                        icon: Icons.music_note,
                        label: L.t('music'),
                        value: s.music,
                        onChanged: (v) {
                          s.music = v;
                          s.saveSettings();
                          s.notifyListeners();
                        },
                      ),
                      const SizedBox(height: 10),
                      _toggleTile(
                        context,
                        icon: Icons.vibration,
                        label: L.t('vibration'),
                        value: s.vibration,
                        onChanged: (v) {
                          s.vibration = v;
                          s.saveSettings();
                          s.notifyListeners();
                        },
                      ),
                      const SizedBox(height: 10),
                      _selectTile(
                        context,
                        icon: Icons.palette,
                        label: L.t('theme'),
                        value: s.theme,
                        onTap: () => _pickTheme(context),
                      ),
                      const SizedBox(height: 10),
                      _selectTile(
                        context,
                        icon: Icons.speed,
                        label: L.t('difficulty'),
                        value: _diffLabel(s.difficulty),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const DifficultyScreen()),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _selectTile(
                        context,
                        icon: Icons.language,
                        label: L.t('language'),
                        value: L.options
                            .firstWhere((o) => o.code == s.language,
                                orElse: () => L.options[1])
                            .label,
                        onTap: () => _pickLanguage(context),
                      ),
                      const SizedBox(height: 20),
                      _dangerButton(context),
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

  String _diffLabel(Difficulty d) => L.difficulty(d);

  Widget _toggleTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return NeonCard(
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            NeonIconTile(Icon(icon, color: AppColors.ciano, size: 24)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeTrackColor: AppColors.ciano,
              activeColor: Colors.white,
              inactiveTrackColor: AppColors.bgCard,
            ),
          ],
        ),
      ),
    );
  }

  Widget _selectTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return NeonCard(
      InkWell(
        onTap: onTap ?? () {},
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              NeonIconTile(Icon(icon, color: AppColors.ciano, size: 24)),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
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

  void _pickTheme(BuildContext context) {
    final s = context.read<GameState>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.ciano),
        ),
        title: Text(
          L.t('chooseTheme'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final name in Themes.names)
              ChoiceChip(
                label: Text(name,
                    style: const TextStyle(color: Colors.white)),
                selected: s.theme.toUpperCase() == name.toUpperCase(),
                selectedColor: AppColors.magenta,
                onSelected: (_) {
                  final idx = Themes.names.indexOf(name);
                  s.theme = name;
                  Themes.index = idx;
                  s.saveSettings();
                  s.notifyListeners();
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _pickLanguage(BuildContext context) {
    final s = context.read<GameState>();
    final opts = L.options;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.ciano),
        ),
        title: Text(
          L.t('chooseLanguage'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final o in opts)
              ListTile(
                title: Text(
                  o.label,
                  style: const TextStyle(color: Colors.white),
                ),
                trailing: s.language == o.code
                    ? const Icon(Icons.check, color: AppColors.verde)
                    : null,
                onTap: () {
                  s.language = o.code;
                  s.saveSettings();
                  s.notifyListeners();
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _dangerButton(BuildContext context) {
    return InkWell(
      onTap: () => _confirmReset(context),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.magenta.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.magenta),
        ),
        child: Text(
          L.t('resetProgress'),
          style: const TextStyle(
            color: AppColors.magenta,
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.magenta),
        ),
        title: Text(
          L.t('resetProgress'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        content: Text(
          L.t('confirmReset'),
          style: const TextStyle(color: AppColors.textoClaro),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(L.t('cancel'),
                style: const TextStyle(color: AppColors.textoClaro)),
          ),
          TextButton(
            onPressed: () {
              context.read<GameState>().resetProgress();
              Navigator.pop(ctx);
            },
            child: Text(L.t('restore'),
                style: const TextStyle(color: AppColors.magenta)),
          ),
        ],
      ),
    );
  }
}
