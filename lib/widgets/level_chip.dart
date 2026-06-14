import 'package:flutter/material.dart';

import '../models/word.dart';

class LevelChip extends StatelessWidget {
  final CEFRLevel level;
  final bool selected;
  final VoidCallback? onTap;

  const LevelChip({
    super.key,
    required this.level,
    this.selected = false,
    this.onTap,
  });

  Color get _color {
    switch (level) {
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

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(level.label),
      selected: selected,
      onSelected: onTap != null ? (_) => onTap!() : null,
      selectedColor: _color.withAlpha(230),
      backgroundColor: _color.withAlpha(40),
      labelStyle: TextStyle(
        color: selected ? Colors.white : _color,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class AllLevelsChip extends StatelessWidget {
  final bool selected;
  final VoidCallback? onTap;

  const AllLevelsChip({super.key, this.selected = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: const Text('全部'),
      selected: selected,
      onSelected: onTap != null ? (_) => onTap!() : null,
      selectedColor: Colors.purple.withAlpha(230),
      backgroundColor: Colors.purple.withAlpha(40),
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.purple,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
