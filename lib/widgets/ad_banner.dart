import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// AdMob banner unit ids (one per platform).
class AdMob {
  static const androidAppId = 'ca-app-pub-5159129783355431~8716113245';
  static const iosAppId = 'ca-app-pub-5159129783355431~6593241731';
  static const androidBanner = 'ca-app-pub-5159129783355431/7403031572';
  static const iosBanner = 'ca-app-pub-5159129783355431/8037456396';
}

/// Places child above a persistent banner pinned to the bottom of the screen.
class AdBoard extends StatelessWidget {
  final Widget child;
  const AdBoard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: child),
        const SafeArea(top: false, child: AdBanner()),
      ],
    );
  }
}

/// Banner widget. Shows nothing on the web (AdMob is mobile-only).
class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _banner;
  bool _loaded = false;

  bool get _supported => !kIsWeb;

  @override
  void initState() {
    super.initState();
    if (!_supported) return;
    final adUnit = defaultTargetPlatform == TargetPlatform.iOS
        ? AdMob.iosBanner
        : AdMob.androidBanner;
    _banner = BannerAd(
      adUnitId: adUnit,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _banner = null;
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_supported || _banner == null || !_loaded) {
      return const SizedBox(height: 62);
    }
    return Container(
      height: 62,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
      child: SizedBox(
        width: 320,
        height: 50,
        child: AdWidget(ad: _banner!),
      ),
    );
  }
}