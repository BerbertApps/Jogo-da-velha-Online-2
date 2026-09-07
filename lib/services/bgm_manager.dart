import 'package:audioplayers/audioplayers.dart';

/// Toca a música de fundo em loop. Ligada/desligada pelo toggle "Música".
class BgmManager {
  static final BgmManager instance = BgmManager._();
  BgmManager._();

  final AudioPlayer _player = AudioPlayer();
  bool _playing = false;

  /// Sincroniza o estado da música com o toggle das configurações.
  Future<void> sync(bool musicEnabled) async {
    if (musicEnabled) {
      if (_playing) return;
      _playing = true;
      try {
        await _player.setReleaseMode(ReleaseMode.loop);
        await _player.setVolume(0.45);
        await _player.play(AssetSource('music'));
      } catch (_) {
        _playing = false;
      }
    } else {
      _playing = false;
      try {
        await _player.stop();
      } catch (_) {}
    }
  }

  Future<void> dispose() async {
    try {
      await _player.dispose();
    } catch (_) {}
  }
}