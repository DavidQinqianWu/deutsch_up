import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/word.dart';
import '../providers/learning_provider.dart';
import '../widgets/word_card.dart';

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // 自动翻页回调： provider 触发，页面执行动画
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<LearningProvider>();
      provider.resumeCurrentCard();
      provider.onAutoFlip = () {
        if (_pageController.hasClients && provider.currentIndex < provider.words.length - 1) {
          _pageController.animateToPage(
            provider.currentIndex + 1,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
          );
        } else if (_pageController.hasClients) {
          // 最后一页超时，回到第一页或刷新
          provider.loadWords(level: provider.selectedLevel);
        }
      };
    });
  }

  @override
  void dispose() {
    context.read<LearningProvider>().onAutoFlip = null;
    _pageController.dispose();
    context.read<LearningProvider>().onCardHidden();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LearningProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('${provider.selectedLevel?.label ?? '全部'} · 刷词'),
        centerTitle: true,
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.words.isEmpty
              ? _buildEmptyState()
              : PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  itemCount: provider.words.length,
                  onPageChanged: (index) {
                    // 用户手动滑动也会触发 onPageChanged
                    // 需要先结算上一张卡片，再显示新卡片
                    if (index != provider.currentIndex) {
                      provider.onManualSwipe();
                      provider.onCardVisible(index);
                    }
                  },
                  itemBuilder: (context, index) {
                    final word = provider.words[index];
                    final progress = provider.progressFor(word.id);
                    final isCurrent = index == provider.currentIndex;
                    return WordCard(
                      word: word,
                      progress: progress,
                      timerProgress: isCurrent ? provider.timerProgress : 0,
                      remainingSeconds: isCurrent ? provider.remainingSeconds : 0,
                      onPlay: () => provider.replayCurrent(),
                      onReplayWord: () => provider.speakGermanOnly(),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, size: 80, color: Colors.green[300]),
            const SizedBox(height: 16),
            Text(
              '暂时没有待复习的单词',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '你已经完成了当前等级的复习任务，稍后再来吧！',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('返回主页'),
            ),
          ],
        ),
      ),
    );
  }
}
