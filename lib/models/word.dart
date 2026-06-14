enum CEFRLevel { a1, a2, b1, b2, c1, c2 }

extension CEFRLevelX on CEFRLevel {
  String get label {
    switch (this) {
      case CEFRLevel.a1:
        return 'A1';
      case CEFRLevel.a2:
        return 'A2';
      case CEFRLevel.b1:
        return 'B1';
      case CEFRLevel.b2:
        return 'B2';
      case CEFRLevel.c1:
        return 'C1';
      case CEFRLevel.c2:
        return 'C2';
    }
  }
}

class Word {
  final String id;
  final String german;
  final String chinese;
  final CEFRLevel level;
  final String exampleSentence;
  final String exampleChinese;
  final List<String> tags;

  const Word({
    required this.id,
    required this.german,
    required this.chinese,
    required this.level,
    required this.exampleSentence,
    required this.exampleChinese,
    this.tags = const [],
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'german': german,
        'chinese': chinese,
        'level': level.label,
        'exampleSentence': exampleSentence,
        'exampleChinese': exampleChinese,
        'tags': tags.join(','),
      };

  factory Word.fromMap(Map<String, dynamic> map) => Word(
        id: map['id'] as String,
        german: map['german'] as String,
        chinese: map['chinese'] as String,
        level: _parseLevel(map['level'] as String),
        exampleSentence: map['exampleSentence'] as String,
        exampleChinese: map['exampleChinese'] as String,
        tags: (map['tags'] as String? ?? '').split(',').where((s) => s.isNotEmpty).toList(),
      );

  static CEFRLevel _parseLevel(String value) {
    return CEFRLevel.values.firstWhere(
      (e) => e.label == value,
      orElse: () => CEFRLevel.a1,
    );
  }
}
