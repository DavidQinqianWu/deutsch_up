import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter_tts/flutter_tts.dart';

/// 德语语音播报。初始化时优先挑选设备上最自然的德语语音，
/// 并按平台配置音频/引擎。桌面端语音质量有限，真机（Android/iOS）效果最好。
class TTSService {
  final FlutterTts _flutterTts = FlutterTts();

  // 学习场景下略慢更清晰；该数值在各平台并非线性，调整时需真机验证
  static const double _speechRate = 0.45;

  Future<void> initialize() async {
    await _configurePlatformAudio();
    await _flutterTts.setLanguage('de-DE');
    await _selectGermanVoice();
    await _flutterTts.setSpeechRate(_speechRate);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.awaitSpeakCompletion(true);
  }

  Future<void> _configurePlatformAudio() async {
    if (kIsWeb) return;
    try {
      if (Platform.isIOS) {
        await _flutterTts.setSharedInstance(true);
        await _flutterTts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [
            IosTextToSpeechAudioCategoryOptions.mixWithOthers,
            IosTextToSpeechAudioCategoryOptions.duckOthers,
          ],
        );
      } else if (Platform.isAndroid) {
        final engines = await _flutterTts.getEngines;
        if (engines is List && engines.contains('com.google.android.tts')) {
          await _flutterTts.setEngine('com.google.android.tts');
        }
      }
    } catch (_) {
      // 平台不支持相关设置时忽略
    }
  }

  /// 在所有德语语音里挑选质量最高的一个，避免使用默认的机械音。
  Future<void> _selectGermanVoice() async {
    try {
      final raw = await _flutterTts.getVoices;
      if (raw is! List) return;
      final german = raw
          .whereType<Map>()
          .map((v) => v.map((k, val) => MapEntry('$k', '${val ?? ''}')))
          .where((v) => (v['locale'] ?? '').toLowerCase().startsWith('de'))
          .toList();
      if (german.isEmpty) return;

      german.sort((a, b) => _voiceScore(b).compareTo(_voiceScore(a)));
      final best = german.first;
      await _flutterTts.setVoice({
        'name': best['name'] ?? '',
        'locale': best['locale'] ?? 'de-DE',
      });
      debugPrint('TTS voice: ${best['name']} (${best['locale']})');
    } catch (_) {
      // 取不到语音列表时退回 setLanguage 的默认语音
    }
  }

  static int _voiceScore(Map<String, String> v) {
    final name = (v['name'] ?? '').toLowerCase();
    final quality = (v['quality'] ?? '').toLowerCase();
    var s = 0;
    if (quality.contains('enhanced') || quality.contains('premium')) s += 100;
    if (name.contains('enhanced') ||
        name.contains('premium') ||
        name.contains('neural')) {
      s += 80;
    }
    if (name.contains('siri')) s += 60;
    if (name.contains('network')) s += 40; // Android 在线语音通常更自然
    final q = int.tryParse(v['quality'] ?? '');
    if (q != null) s += q ~/ 10; // Android 数值质量：300/400 → 30/40
    if ((v['locale'] ?? '').toLowerCase() == 'de-de') s += 5;
    const lowQuality = [
      'anna', 'eddy', 'flo', 'grandma', 'grandpa', 'reed', 'rocko', 'sandy',
      'shelley', 'compact',
    ];
    if (lowQuality.any((b) => name.contains(b))) s -= 30;
    return s;
  }

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    await _flutterTts.stop();
    await _flutterTts.speak(text);
  }

  /// 先念单词，停顿一下，再念例句，让发音更清晰。
  Future<void> speakWordAndSentence(String word, String sentence) async {
    await _flutterTts.stop();
    if (word.trim().isNotEmpty) {
      await _flutterTts.speak(word);
    }
    if (sentence.trim().isNotEmpty) {
      await Future.delayed(const Duration(milliseconds: 250));
      await _flutterTts.speak(sentence);
    }
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }
}
