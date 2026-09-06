import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'models/game_state.dart';
import 'screens/splash_screen.dart';
import 'theme.dart';
import 'i18n/strings.dart';
import 'widgets/ad_banner.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    try {
      MobileAds.instance.initialize();
    } catch (_) {}
  }
  runApp(
    ChangeNotifierProvider(
      create: (_) => GameState(),
      child: const JogoDaVelhaApp(),
    ),
  );
}

class JogoDaVelhaApp extends StatelessWidget {
  const JogoDaVelhaApp({super.key});

  // Mapeia o nome de tema salvo para o índice usado em [themeColorFilterFor].
  static int themeIndexFor(String theme) {
    final t = theme.toUpperCase();
    var idx = Themes.names.indexWhere((n) => n.toUpperCase() == t);
    if (idx < 0) idx = 0;
    return idx;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();
    L.lang = state.language;
    final filter = themeColorFilterFor(themeIndexFor(state.theme));
    return ColorFiltered(
      colorFilter: filter,
      child: MaterialApp(
        title: L.t('appTitle'),
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          scaffoldBackgroundColor: AppColors.bgMain,
          fontFamily: 'sans',
          colorScheme: ColorScheme.dark(
            primary: AppColors.ciano,
            secondary: AppColors.magenta,
            surface: AppColors.bgCard,
          ),
          useMaterial3: true,
        ),
        builder: (context, child) => SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(child: child!),
              const AdBanner(),
            ],
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
