import 'package:flutter/material.dart';

enum Familiarity {
  unknown, // 完全不知道 - 红色
  struggling, // 生疏 - 橙红
  needsPractice, // 需要练习 - 橙色
  familiar, // 熟悉 - 浅绿
  mastered, // 掌握 - 绿色
}

extension FamiliarityX on Familiarity {
  String get label {
    switch (this) {
      case Familiarity.unknown:
        return '陌生';
      case Familiarity.struggling:
        return '生疏';
      case Familiarity.needsPractice:
        return '需复习';
      case Familiarity.familiar:
        return '熟悉';
      case Familiarity.mastered:
        return '掌握';
    }
  }

  int get sortOrder {
    switch (this) {
      case Familiarity.unknown:
        return 0;
      case Familiarity.struggling:
        return 1;
      case Familiarity.needsPractice:
        return 2;
      case Familiarity.familiar:
        return 3;
      case Familiarity.mastered:
        return 4;
    }
  }

  /// 白色只给全新单词，其余按红→橙→绿渐变
  Color get backgroundColor {
    switch (this) {
      case Familiarity.unknown:
        return const Color(0xFFFFE5E5); // 浅红
      case Familiarity.struggling:
        return const Color(0xFFFFE8D6); // 橙红
      case Familiarity.needsPractice:
        return const Color(0xFFFFF3CD); // 橙色
      case Familiarity.familiar:
        return const Color(0xFFD4EDDA); // 浅绿
      case Familiarity.mastered:
        return const Color(0xFFC3E6CB); // 绿色
    }
  }

  Color get foregroundColor {
    switch (this) {
      case Familiarity.unknown:
        return const Color(0xFFC0392B);
      case Familiarity.struggling:
        return const Color(0xFFD35400);
      case Familiarity.needsPractice:
        return const Color(0xFFF39C12);
      case Familiarity.familiar:
        return const Color(0xFF27AE60);
      case Familiarity.mastered:
        return const Color(0xFF1E8449);
    }
  }
}

class UserProgress {
  final String wordId;
  final double easinessFactor;
  final int repetitions;
  final double intervalDays;
  final DateTime? lastReviewedAt;
  final DateTime? nextReviewAt;
  final int totalDwellMs;
  final int lastDwellMs;
  final int reviewCount;
  final Familiarity? familiarity;

  const UserProgress({
    required this.wordId,
    this.easinessFactor = 2.5,
    this.repetitions = 0,
    this.intervalDays = 0,
    this.lastReviewedAt,
    this.nextReviewAt,
    this.totalDwellMs = 0,
    this.lastDwellMs = 0,
    this.reviewCount = 0,
    this.familiarity,
  });

  bool get isDue => nextReviewAt == null || nextReviewAt!.isBefore(DateTime.now());

  Map<String, dynamic> toMap() => {
        'wordId': wordId,
        'easinessFactor': easinessFactor,
        'repetitions': repetitions,
        'intervalDays': intervalDays,
        'lastReviewedAt': lastReviewedAt?.millisecondsSinceEpoch,
        'nextReviewAt': nextReviewAt?.millisecondsSinceEpoch,
        'totalDwellMs': totalDwellMs,
        'lastDwellMs': lastDwellMs,
        'reviewCount': reviewCount,
        'familiarity': familiarity?.index,
      };

  factory UserProgress.fromMap(Map<String, dynamic> map) => UserProgress(
        wordId: map['wordId'] as String,
        easinessFactor: (map['easinessFactor'] as num?)?.toDouble() ?? 2.5,
        repetitions: map['repetitions'] as int? ?? 0,
        intervalDays: (map['intervalDays'] as num?)?.toDouble() ?? 0,
        lastReviewedAt: map['lastReviewedAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['lastReviewedAt'] as int)
            : null,
        nextReviewAt: map['nextReviewAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['nextReviewAt'] as int)
            : null,
        totalDwellMs: map['totalDwellMs'] as int? ?? 0,
        lastDwellMs: map['lastDwellMs'] as int? ?? 0,
        reviewCount: map['reviewCount'] as int? ?? 0,
        familiarity: map['familiarity'] != null
            ? Familiarity.values[map['familiarity'] as int]
            : null,
      );

  UserProgress copyWith({
    double? easinessFactor,
    int? repetitions,
    double? intervalDays,
    DateTime? lastReviewedAt,
    DateTime? nextReviewAt,
    int? totalDwellMs,
    int? lastDwellMs,
    int? reviewCount,
    Familiarity? familiarity,
  }) =>
      UserProgress(
        wordId: wordId,
        easinessFactor: easinessFactor ?? this.easinessFactor,
        repetitions: repetitions ?? this.repetitions,
        intervalDays: intervalDays ?? this.intervalDays,
        lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
        nextReviewAt: nextReviewAt ?? this.nextReviewAt,
        totalDwellMs: totalDwellMs ?? this.totalDwellMs,
        lastDwellMs: lastDwellMs ?? this.lastDwellMs,
        reviewCount: reviewCount ?? this.reviewCount,
        familiarity: familiarity ?? this.familiarity,
      );
}
