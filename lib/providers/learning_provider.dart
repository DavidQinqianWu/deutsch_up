import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/user_progress.dart';
import '../models/word.dart';
import '../services/database_service.dart';
import '../services/spaced_repetition_service.dart';
import '../services/tts_service.dart';

class LearningProvider extends ChangeNotifier {
  final DatabaseService _database = DatabaseService();
  final TTSService _tts = TTSService();

  VoidCallback? onAutoFlip;

  List<Word> _words = [];
  final Map<String, UserProgress> _progressMap = {};
  int _currentIndex = 0;
  CEFRLevel? _selectedLevel;
  bool _isLoading = true;

  Timer? _cardTimer;
  DateTime? _cardVisibleSince;
  int _elapsedMs = 0;
  static const int _cardTimeoutMs = SpacedRepetitionService.cardTimeoutSeconds * 1000;

  List<Word> get words => _words;
  int get currentIndex => _currentIndex;
  CEFRLevel? get selectedLevel => _selectedLevel;
  bool get isLoading => _isLoading;
  Word? get currentWord => _words.isEmpty ? null : _words[_currentIndex];

  /// 0.0 ~ 1.0，剩余时间越少值越大
  double get timerProgress => min(_elapsedMs / _cardTimeoutMs, 1.0);

  /// 剩余秒数
  int get remainingSeconds => max(0, ((_cardTimeoutMs - _elapsedMs) / 1000).ceil());

  Future<void> initialize() async {
    // TTS 在桌面端可能不被支持，给初始化加超时，避免一直卡在加载页
    try {
      await _tts.initialize().timeout(const Duration(seconds: 5));
    } catch (_) {
      // 初始化失败或超时：忽略语音，继续加载词库
    }
    await loadWords(level: _selectedLevel);
  }

  Future<void> loadWords({CEFRLevel? level}) async {
    _isLoading = true;
    notifyListeners();

    _selectedLevel = level;
    _words = await _database.getDueWords(level: level, limit: 100);
    _progressMap.clear();
    _progressMap.addAll(await _database.getAllProgress());
    _currentIndex = 0;
    _isLoading = false;

    notifyListeners();
    _startCardTimer();
    // 不要 await 语音，否则 TTS 卡住会阻塞整个加载流程
    unawaited(_speakCurrent());
  }

  void setLevel(CEFRLevel? level) {
    if (_selectedLevel == level) return;
    loadWords(level: level);
  }

  void onCardVisible(int index) {
    if (index < 0 || index >= _words.length) return;
    _finishCurrentCard();
    _currentIndex = index;
    notifyListeners();
    _startCardTimer();
    _speakCurrent();
  }

  /// 页面重新进入时恢复当前卡片计时，不结算上一张
  void resumeCurrentCard() {
    if (_words.isEmpty) return;
    _startCardTimer();
    _speakCurrent();
  }

  void onCardHidden() {
    _finishCurrentCard();
  }

  /// 用户手动翻页时调用
  void onManualSwipe() {
    _finishCurrentCard();
  }

  void _finishCurrentCard() {
    final word = currentWord;
    if (word == null || _cardVisibleSince == null) return;

    final dwellMs = DateTime.now().difference(_cardVisibleSince!).inMilliseconds;
    _stopCardTimer();

    final existing = _progressMap[word.id] ?? UserProgress(wordId: word.id);
    final updated = SpacedRepetitionService.review(existing, dwellMs);
    _progressMap[word.id] = updated;

    _database.saveProgress(updated);
  }

  void _startCardTimer() {
    _stopCardTimer();
    _cardVisibleSince = DateTime.now();
    _elapsedMs = 0;

    _cardTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (_cardVisibleSince == null) return;
      _elapsedMs = DateTime.now().difference(_cardVisibleSince!).inMilliseconds;
      notifyListeners();

      if (_elapsedMs >= _cardTimeoutMs) {
        _onCardTimeout();
      }
    });
  }

  void _stopCardTimer() {
    _cardTimer?.cancel();
    _cardTimer = null;
  }

  void _onCardTimeout() {
    _stopCardTimer();
    _finishCurrentCard();

    // 通知页面执行自动翻页动画
    onAutoFlip?.call();
  }

  Future<void> _speakCurrent() async {
    final word = currentWord;
    if (word == null) return;
    await _tts.speakWordAndSentence(word.german, word.exampleSentence);
  }

  Future<void> replayCurrent() async {
    await _speakCurrent();
  }

  Future<void> speakGermanOnly() async {
    final word = currentWord;
    if (word == null) return;
    await _tts.speak(word.german);
  }

  UserProgress? progressFor(String wordId) => _progressMap[wordId];

  Future<Map<String, int>> getStats() async {
    final total = await _database.countWords(level: _selectedLevel);
    final mastered = await _database.countMasteredWords();
    final dueToday = _words.length;

    return {
      'total': total,
      'mastered': mastered,
      'dueToday': dueToday,
    };
  }

  @override
  void dispose() {
    onCardHidden();
    _tts.stop();
    super.dispose();
  }
}
