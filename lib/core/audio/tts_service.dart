import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Text-to-speech for Baybayin glyphs and translation results.
///
/// Wire a tap-to-hear button on: the character gallery, translate output,
/// and quiz answers. Baybayin is a spoken language first, so pronunciation is
/// a high-value, low-risk learning feature.
///
/// Usage:
///   final tts = ref.read(ttsServiceProvider);
///   await tts.speak('ba');
class TtsService {
  TtsService([FlutterTts? tts]) : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;
  bool _configured = false;

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    try {
      // Filipino locale; falls back to the device default if unavailable.
      await _tts.setLanguage('fil-PH');
      await _tts.setSpeechRate(0.45);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
    } catch (e) {
      debugPrint('[TtsService] configure failed: $e');
    }
    _configured = true;
  }

  Future<void> speak(String text) async {
    final String trimmed = text.trim();
    if (trimmed.isEmpty) return;
    await _ensureConfigured();
    try {
      await _tts.stop();
      await _tts.speak(trimmed);
    } catch (e) {
      debugPrint('[TtsService] speak failed: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}

/// Hand-written provider (no codegen needed) so screens can read the service.
final Provider<TtsService> ttsServiceProvider = Provider<TtsService>((ref) {
  final TtsService service = TtsService();
  ref.onDispose(service.stop);
  return service;
});
