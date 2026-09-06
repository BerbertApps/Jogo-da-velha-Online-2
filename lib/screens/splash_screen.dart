import 'dart:async';
import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets.dart';
import '../i18n/strings.dart';
import 'menu_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..addListener(() {
        setState(() => _progress = _controller.value);
      });
    _controller.forward();
    Timer(const Duration(milliseconds: 2600), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MenuScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ParticleLayer(
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              // Símbolos X e O animados
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _symbol('X', AppColors.ciano),
                  const SizedBox(width: 40),
                  _symbol('O', AppColors.magenta),
                ],
              ),
              const SizedBox(height: 24),
              NeonTitle(L.t('appTitle'), fontSize: 40, uppercase: true),
              const SizedBox(height: 16),
              Text(
                L.t('classicFastStrategic'),
                style: const TextStyle(
                  color: AppColors.textoClaro,
                  fontSize: 12,
                  letterSpacing: 3,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(flex: 3),
              // Barra de carregamento
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 60),
                child: Column(
                  children: [
                    Text(
                      L.t('loading'),
                      style: const TextStyle(
                        color: AppColors.textoClaro,
                        letterSpacing: 3,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: _progress,
                        minHeight: 5,
                        backgroundColor: AppColors.bgCard,
                        valueColor: const AlwaysStoppedAnimation(AppColors.ciano),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(_progress * 100).round()}%',
                      style: const TextStyle(
                        color: AppColors.ciano,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _symbol(String s, Color color) {
    return Container(
      width: 60,
      height: 60,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.4), width: 2),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 20),
        ],
      ),
      child: Text(
        s,
        style: TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.w900,
          color: color,
          shadows: [Shadow(color: color, blurRadius: 15)],
        ),
      ),
    );
  }
}
