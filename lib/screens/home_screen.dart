import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/word.dart';
import '../providers/learning_provider.dart';
import '../widgets/level_chip.dart';
import '../widgets/stats_card.dart';
import 'learn_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, int> _stats = {'total': 0, 'mastered': 0, 'dueToday': 0};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadStats());
  }

  Future<void> _loadStats() async {
    final provider = context.read<LearningProvider>();
    final stats = await provider.getStats();
    if (mounted) {
      setState(() => _stats = stats);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LearningProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Deutsch Up'),
        centerTitle: true,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题
              Text(
                '像刷短视频一样记德语单词',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '选择等级，上下滑动开始刷词。听例句、看释义，刷着刷着就记住了。',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[700],
                    ),
              ),
              const SizedBox(height: 24),

              // 等级选择
              Text(
                '选择等级',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  AllLevelsChip(
                    selected: provider.selectedLevel == null,
                    onTap: () => provider.setLevel(null),
                  ),
                  ...CEFRLevel.values.map((level) => LevelChip(
                        level: level,
                        selected: provider.selectedLevel == level,
                        onTap: () => provider.setLevel(level),
                      )),
                ],
              ),
              const SizedBox(height: 32),

              // 统计
              Text(
                '学习统计',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: StatsCard(
                      title: '词库总数',
                      value: _stats['total'] ?? 0,
                      icon: Icons.menu_book_outlined,
                      color: Colors.blue,
                    ),
                  ),
                  Expanded(
                    child: StatsCard(
                      title: '已掌握',
                      value: _stats['mastered'] ?? 0,
                      icon: Icons.check_circle_outline,
                      color: Colors.green,
                    ),
                  ),
                  Expanded(
                    child: StatsCard(
                      title: '待复习',
                      value: _stats['dueToday'] ?? 0,
                      icon: Icons.refresh,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // 开始按钮
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LearnScreen()),
                    );
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('开始刷词', style: TextStyle(fontSize: 18)),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  '当前等级：${provider.selectedLevel?.label ?? '全部'}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
