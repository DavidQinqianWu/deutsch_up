import '../models/user_progress.dart';

/// 每张卡片有 20 秒倒计时。
/// 用户翻页越快 = 越熟悉（绿色，复习间隔长）。
/// 停留越久 / 超时 = 越陌生（红色，复习间隔短，频繁出现）。
class SpacedRepetitionService {
  static const int cardTimeoutSeconds = 20;

  /// 根据用户在卡片上停留的秒数判断熟悉度
  /// 0-4s: 掌握 | 4-8s: 熟悉 | 8-12s: 需复习 | 12-16s: 生疏 | 16s+: 陌生
  static Familiarity rateTimeOnCard(int millisecondsOnCard) {
    final seconds = millisecondsOnCard / 1000;
    if (seconds < 4) return Familiarity.mastered;
    if (seconds < 8) return Familiarity.familiar;
    if (seconds < 12) return Familiarity.needsPractice;
    if (seconds < 16) return Familiarity.struggling;
    return Familiarity.unknown;
  }

  static UserProgress review(
    UserProgress progress,
    int millisecondsOnCard,
  ) {
    final familiarity = rateTimeOnCard(millisecondsOnCard);

    // 停留越久，间隔越短；翻页越快，间隔越长
    double intervalDays;
    switch (familiarity) {
      case Familiarity.mastered:
        intervalDays = progress.intervalDays <= 0 ? 3 : progress.intervalDays * 2.5;
        break;
      case Familiarity.familiar:
        intervalDays = progress.intervalDays <= 0 ? 1 : progress.intervalDays * 1.8;
        break;
      case Familiarity.needsPractice:
        intervalDays = 0.02; // ~30 分钟
        break;
      case Familiarity.struggling:
        intervalDays = 0.0035; // ~5 分钟
        break;
      case Familiarity.unknown:
        intervalDays = 0.0007; // ~1 分钟
        break;
    }

    // 上限防止 interval 过大
    if (intervalDays > 30) intervalDays = 30;

    final quality = familiarity == Familiarity.mastered
        ? 5
        : familiarity == Familiarity.familiar
            ? 4
            : familiarity == Familiarity.needsPractice
                ? 3
                : familiarity == Familiarity.struggling
                    ? 2
                    : 1;

    var easinessFactor = progress.easinessFactor +
        (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
    if (easinessFactor < 1.3) easinessFactor = 1.3;

    final repetitions = familiarity.index >= Familiarity.familiar.index
        ? progress.repetitions + 1
        : 0;

    final nextReviewAt = DateTime.now().add(
      Duration(minutes: (intervalDays * 24 * 60).round()),
    );

    return progress.copyWith(
      easinessFactor: easinessFactor,
      repetitions: repetitions,
      intervalDays: intervalDays,
      lastReviewedAt: DateTime.now(),
      nextReviewAt: nextReviewAt,
      totalDwellMs: progress.totalDwellMs + millisecondsOnCard,
      lastDwellMs: millisecondsOnCard,
      reviewCount: progress.reviewCount + 1,
    );
  }
}
