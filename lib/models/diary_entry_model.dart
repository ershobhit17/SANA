import 'dart:convert';

class DiaryEntry {
  final String id;
  final String title;
  final String content;
  final DateTime entryDate;
  final List<String> tags;
  final List<String> imagePaths;
  final String mood; // 'Great', 'Good', 'Neutral', 'Low', 'Tired'
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DiaryEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.entryDate,
    this.tags = const [],
    this.imagePaths = const [],
    this.mood = 'Good',
    this.isFavorite = false,
    required this.createdAt,
    required this.updatedAt,
  });

  int get wordCount {
    if (content.trim().isEmpty) return 0;
    return content.trim().split(RegExp(r'\s+')).length;
  }

  int get estimatedReadMinutes {
    final words = wordCount;
    return (words / 200).ceil().clamp(1, 60);
  }

  DiaryEntry copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? entryDate,
    List<String>? tags,
    List<String>? imagePaths,
    String? mood,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DiaryEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      entryDate: entryDate ?? this.entryDate,
      tags: tags ?? this.tags,
      imagePaths: imagePaths ?? this.imagePaths,
      mood: mood ?? this.mood,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'entryDate': entryDate.toIso8601String(),
      'tags': jsonEncode(tags),
      'imagePaths': jsonEncode(imagePaths),
      'mood': mood,
      'isFavorite': isFavorite ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory DiaryEntry.fromMap(Map<String, dynamic> map) {
    List<String> parsedTags = [];
    if (map['tags'] != null) {
      try {
        final decoded = jsonDecode(map['tags'] as String) as List<dynamic>;
        parsedTags = decoded.map((e) => e.toString()).toList();
      } catch (_) {}
    }

    List<String> parsedImages = [];
    if (map['imagePaths'] != null) {
      try {
        final decoded =
            jsonDecode(map['imagePaths'] as String) as List<dynamic>;
        parsedImages = decoded.map((e) => e.toString()).toList();
      } catch (_) {}
    }

    return DiaryEntry(
      id: map['id'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      entryDate: DateTime.parse(map['entryDate'] as String),
      tags: parsedTags,
      imagePaths: parsedImages,
      mood: map['mood'] as String? ?? 'Good',
      isFavorite: (map['isFavorite'] as num?) == 1,
      createdAt: DateTime.parse(
          map['createdAt'] as String? ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(
          map['updatedAt'] as String? ?? DateTime.now().toIso8601String()),
    );
  }
}
