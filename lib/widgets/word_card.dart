import 'package:flutter/material.dart';

import '../models/user_progress.dart';
import '../models/word.dart';

class WordCard extends StatelessWidget {
  final Word word;
  final UserProgress? progress;
  final double timerProgress;
  final int remainingSeconds;
  final VoidCallback onPlay;
  final VoidCallback onReplayWord;

  const WordCard({
    super.key,
    required this.word,
    this.progress,
    required this.timerProgress,
    required this.remainingSeconds,
    required this.onPlay,
    required this.onReplayWord,
  });

  Color get _levelColor {
    switch (word.level) {
      case CEFRLevel.a1:
        return Colors.green;
      case CEFRLevel.a2:
        return Colors.lightGreen;
      case CEFRLevel.b1:
        return Colors.blue;
      case CEFRLevel.b2:
        return Colors.indigo;
      case CEFRLevel.c1:
        return Colors.orange;
      case CEFRLevel.c2:
        return Colors.red;
    }
  }

  // 直接读取数据行上记录的熟悉度；为空说明还没评定过（新词）
  Familiarity? get _familiarity => progress?.familiarity;

  String get _familiarityText => _familiarity?.label ?? '新词';

  // 新词显示白色背景
  Color get _backgroundColor => _familiarity?.backgroundColor ?? Colors.white;

  Color get _foregroundColor => _familiarity?.foregroundColor ?? Colors.grey;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _backgroundColor,
      child: Column(
        children: [
          // 倒计时进度条
          _TimerProgressBar(progress: timerProgress, remainingSeconds: remainingSeconds),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 顶部标签
                  Row(
                    children: [
                      Chip(
                        label: Text(word.level.label),
                        backgroundColor: _levelColor.withAlpha(40),
                        labelStyle: TextStyle(
                          color: _levelColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(_familiarityText),
                        backgroundColor: _foregroundColor.withAlpha(40),
                        labelStyle: TextStyle(
                          color: _foregroundColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: onReplayWord,
                        icon: const Icon(Icons.volume_up_outlined),
                        tooltip: '只读单词',
                      ),
                      IconButton(
                        onPressed: onPlay,
                        icon: const Icon(Icons.play_circle_fill),
                        iconSize: 36,
                        color: Theme.of(context).colorScheme.primary,
                        tooltip: '朗读单词和例句',
                      ),
                    ],
                  ),

                  const Spacer(),

                  // 单词主体
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          word.german,
                          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          word.chinese,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.grey[800],
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // 例句区域
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(180),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.grey.withAlpha(40),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '例句',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          word.exampleSentence,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          word.exampleChinese,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.grey[700],
                              ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 底部提示
                  Center(
                    child: Text(
                      '翻页越快 = 越熟悉 · 超时自动翻页',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimerProgressBar extends StatelessWidget {
  final double progress;
  final int remainingSeconds;

  const _TimerProgressBar({
    required this.progress,
    required this.remainingSeconds,
  });

  Color get _color {
    // 剩余时间越少，颜色越红
    if (progress < 0.4) return Colors.green;
    if (progress < 0.6) return Colors.lightGreen;
    if (progress < 0.75) return Colors.orange;
    if (progress < 0.9) return Colors.deepOrange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LinearProgressIndicator(
          value: progress,
          minHeight: 8,
          backgroundColor: Colors.grey.withAlpha(40),
          valueColor: AlwaysStoppedAnimation<Color>(_color),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '反应时间',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              Text(
                '${remainingSeconds}s',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _color,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
