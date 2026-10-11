import 'dart:convert';

class StudyNoteLink {
  final String id;
  final String url;
  final String label; // "ye kis chij ke liye hai" / purpose / description
  final String category; // e.g. "Tutorial", "Documentation", "PDF", "Video", "Reference"

  const StudyNoteLink({
    required this.id,
    required this.url,
    required this.label,
    this.category = 'Resource',
  });

  StudyNoteLink copyWith({
    String? id,
    String? url,
    String? label,
    String? category,
  }) {
    return StudyNoteLink(
      id: id ?? this.id,
      url: url ?? this.url,
      label: label ?? this.label,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'url': url,
      'label': label,
      'category': category,
    };
  }

  factory StudyNoteLink.fromMap(Map<String, dynamic> map) {
    return StudyNoteLink(
      id: map['id'] as String? ?? '',
      url: map['url'] as String? ?? '',
      label: map['label'] as String? ?? '',
      category: map['category'] as String? ?? 'Resource',
    );
  }
}

class StudyNoteItem {
  final String id;
  final String title;
  final String content;
  final String category; // e.g. "Computer Science", "Mathematics", "Exams", "General", "Research"
  final List<String> tags;
  final List<StudyNoteLink> links;
  final bool isPinned;
  final int? colorValue;
  final DateTime createdAt;
  final DateTime updatedAt;

  const StudyNoteItem({
    required this.id,
    required this.title,
    required this.content,
    this.category = 'General',
    this.tags = const [],
    this.links = const [],
    this.isPinned = false,
    this.colorValue,
    required this.createdAt,
    required this.updatedAt,
  });

  StudyNoteItem copyWith({
    String? id,
    String? title,
    String? content,
    String? category,
    List<String>? tags,
    List<StudyNoteLink>? links,
    bool? isPinned,
    int? colorValue,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StudyNoteItem(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      links: links ?? this.links,
      isPinned: isPinned ?? this.isPinned,
      colorValue: colorValue ?? this.colorValue,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'category': category,
      'tags': jsonEncode(tags),
      'links': jsonEncode(links.map((l) => l.toMap()).toList()),
      'isPinned': isPinned ? 1 : 0,
      'colorValue': colorValue,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory StudyNoteItem.fromMap(Map<String, dynamic> map) {
    List<String> parseTags(dynamic raw) {
      if (raw == null) return [];
      try {
        final decoded = jsonDecode(raw.toString()) as List<dynamic>;
        return decoded.map((e) => e.toString()).toList();
      } catch (_) {
        return [];
      }
    }

    List<StudyNoteLink> parseLinks(dynamic raw) {
      if (raw == null) return [];
      try {
        final decoded = jsonDecode(raw.toString()) as List<dynamic>;
        return decoded
            .map((e) => StudyNoteLink.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList();
      } catch (_) {
        return [];
      }
    }

    return StudyNoteItem(
      id: map['id'] as String,
      title: map['title'] as String,
      content: map['content'] as String? ?? '',
      category: map['category'] as String? ?? 'General',
      tags: parseTags(map['tags']),
      links: parseLinks(map['links']),
      isPinned: (map['isPinned'] as num?) == 1,
      colorValue: map['colorValue'] as int?,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
