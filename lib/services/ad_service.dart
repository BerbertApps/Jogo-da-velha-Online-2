import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../widgets/ad_banner.dart';

/// Gerencia o anúncio interstitial. Exibe um anúncio a cada 5 partidas
/// concluídas, no momento em que o jogador sai/avança para outra tela.
class AdService {
  static final AdService instance = AdService._();
  AdService._();

  InterstitialAd? _interstitial;
  bool _loading = false;

  /// Conta para qual total de partidas o interstitial já foi exibido.
  int _gamesShownFor = 0;

  /// Pré-carrega um interstitial em segundo plano.
  void loadInterstitial() {
    if (kIsWeb || _loading || _interstitial != null) return;
    final adUnit = defaultTargetPlatform == TargetPlatform.iOS
        ? AdMob.iosInterstitial
        : AdMob.androidInterstitial;
    _loading = true;
    InterstitialAd.load(
      adUnitId: adUnit,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitial = ad;
          _loading = false;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (_) {
              _interstitial = null;
            },
            onAdFailedToShowFullScreenContent: (_, _) {
              _interstitial = null;
            },
          );
        },
        onAdFailedToLoad: (_) {
          _loading = false;
          _interstitial = null;
        },
      ),
    );
  }

  /// Exibe o interstitial quando o total de partidas for múltiplo de 5
  /// (5ª jogada, 10ª, 15ª...), uma única vez por múltiplo.
  void maybeShowInterstitial(int totalGames) {
    if (kIsWeb) return;
    if (totalGames < 5) return;
    if (totalGames % 5 != 0) return;
    if (totalGames == _gamesShownFor) return;

    final ad = _interstitial;
    if (ad == null) {
      loadInterstitial();
      return;
    }

    _gamesShownFor = totalGames;
    _interstitial = null;
    ad.show();
    loadInterstitial();
  }
}