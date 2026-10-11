import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/dayflow_theme_context.dart';
import '../../../models/study_note_model.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/dayflow_button.dart';
import '../../../shared/widgets/dayflow_chip.dart';
import '../../../shared/widgets/dayflow_text_field.dart';

class NoteFormDialog extends ConsumerStatefulWidget {
  final StudyNoteItem? initialNote;

  const NoteFormDialog({super.key, this.initialNote});

  @override
  ConsumerState<NoteFormDialog> createState() => _NoteFormDialogState();
}

class _LinkDraft {
  String id;
  TextEditingController urlController;
  TextEditingController labelController;
  String category;

  _LinkDraft({
    required this.id,
    required this.urlController,
    required this.labelController,
    this.category = 'Resource',
  });
}

class _NoteFormDialogState extends ConsumerState<NoteFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _tagController;
  late TextEditingController _customCategoryController;

  late String _selectedCategory;
  late bool _isPinned;
  late List<_LinkDraft> _linkDrafts;
  late List<String> _tags;

  final List<String> _presetCategories = const [
    'Study Material',
    'Computer Science',
    'Coding',
    'Mathematics',
    'Research',
    'Documentation',
    'Exam Prep',
    'General',
  ];

  final List<String> _linkCategoryPresets = const [
    'Resource',
    'Video',
    'Docs',
    'GitHub',
    'Article',
    'PDF',
    'Practice',
  ];

  @override
  void initState() {
    super.initState();
    final note = widget.initialNote;

    _titleController = TextEditingController(text: note?.title ?? '');
    _contentController = TextEditingController(text: note?.content ?? '');
    _tagController = TextEditingController();
    _customCategoryController = TextEditingController();

    _selectedCategory = note?.category ?? 'Study Material';
    _isPinned = note?.isPinned ?? false;
    _tags = note != null ? List<String>.from(note.tags) : [];

    _linkDrafts = [];
    if (note != null && note.links.isNotEmpty) {
      for (final l in note.links) {
        _linkDrafts.add(
          _LinkDraft(
            id: l.id,
            urlController: TextEditingController(text: l.url),
            labelController: TextEditingController(text: l.label),
            category: l.category,
          ),
        );
      }
    } else {
      // Start with 1 empty link slot ready for study material
      _linkDrafts.add(
        _LinkDraft(
          id: const Uuid().v4(),
          urlController: TextEditingController(),
          labelController: TextEditingController(),
          category: 'Resource',
        ),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    _customCategoryController.dispose();
    for (final l in _linkDrafts) {
      l.urlController.dispose();
      l.labelController.dispose();
    }
    super.dispose();
  }

  void _addLinkSlot() {
    setState(() {
      _linkDrafts.add(
        _LinkDraft(
          id: const Uuid().v4(),
          urlController: TextEditingController(),
          labelController: TextEditingController(),
          category: 'Resource',
        ),
      );
    });
  }

  void _removeLinkSlot(int index) {
    if (_linkDrafts.length > 1) {
      setState(() {
        final removed = _linkDrafts.removeAt(index);
        removed.urlController.dispose();
        removed.labelController.dispose();
      });
    } else {
      // Just clear the single slot
      _linkDrafts[0].urlController.clear();
      _linkDrafts[0].labelController.clear();
      setState(() {});
    }
  }

  Future<void> _pasteUrlInto(TextEditingController controller) async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null && data!.text!.isNotEmpty) {
      controller.text = data.text!.trim();
      setState(() {});
    }
  }

  void _addTag() {
    final t = _tagController.text.trim();
    if (t.isNotEmpty && !_tags.contains(t)) {
      setState(() {
        _tags.add(t);
        _tagController.clear();
      });
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    final category = _customCategoryController.text.trim().isNotEmpty
        ? _customCategoryController.text.trim()
        : _selectedCategory;

    // Collect valid links
    final List<StudyNoteLink> validLinks = [];
    for (final draft in _linkDrafts) {
      final url = draft.urlController.text.trim();
      final label = draft.labelController.text.trim();
      if (url.isNotEmpty) {
        validLinks.add(
          StudyNoteLink(
            id: draft.id,
            url: url,
            label: label.isNotEmpty ? label : 'Study Link',
            category: draft.category,
          ),
        );
      }
    }

    final now = DateTime.now();

    if (widget.initialNote == null) {
      final newNote = StudyNoteItem(
        id: const Uuid().v4(),
        title: title,
        content: content,
        category: category,
        tags: _tags,
        links: validLinks,
        isPinned: _isPinned,
        createdAt: now,
        updatedAt: now,
      );
      ref.read(notesProvider.notifier).createNote(newNote);
    } else {
      final updatedNote = widget.initialNote!.copyWith(
        title: title,
        content: content,
        category: category,
        tags: _tags,
        links: validLinks,
        isPinned: _isPinned,
        updatedAt: now,
      );
      ref.read(notesProvider.notifier).updateNote(updatedNote);
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.themeTokens;
    final isEditing = widget.initialNote != null;

    return Dialog(
      backgroundColor: tokens.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.cardRadius),
        side: BorderSide(color: tokens.borderColor, width: tokens.borderWidth),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 720),
        padding: EdgeInsets.all(tokens.cardPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: tokens.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.menu_book_rounded,
                          color: tokens.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        isEditing ? 'Edit Study Note' : 'Add Study Material & Note',
                        style: context.getTextStyle(
                          fontSize: 18,
                          fontWeight: tokens.headingWeight,
                          color: tokens.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: tokens.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Form fields in scroll view
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Note Title
                      Text(
                        'Title / Subject Topic *',
                        style: context.getTextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: tokens.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      DayFlowTextField(
                        controller: _titleController,
                        hintText: 'e.g. Data Structures Roadmap, Physics Formulae...',
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Please enter a title' : null,
                      ),
                      const SizedBox(height: 14),

                      // Category Selector
                      Text(
                        'Category',
                        style: context.getTextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: tokens.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _presetCategories.map<Widget>((c) {
                          final isSelected = _selectedCategory == c;
                          return DayFlowChip(
                            label: c,
                            isSelected: isSelected,
                            onTap: () {
                              setState(() {
                                _selectedCategory = c;
                                _customCategoryController.clear();
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                      DayFlowTextField(
                        controller: _customCategoryController,
                        hintText: 'Or enter custom category...',
                        onChanged: (v) {
                          if (v.trim().isNotEmpty) {
                            setState(() => _selectedCategory = v.trim());
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Study Notes & Explanation Content
                      Text(
                        'Notes & Explanation',
                        style: context.getTextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: tokens.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      DayFlowTextField(
                        controller: _contentController,
                        hintText: 'Write your study notes, important formulas, reminders, or chapter takeaways...',
                        maxLines: 4,
                      ),
                      const SizedBox(height: 18),

                      // ================= STUDY LINKS SECTION =================
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: tokens.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: tokens.borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.link_rounded,
                                        color: tokens.primary, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Study Links & Resources',
                                      style: context.getTextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: tokens.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                TextButton.icon(
                                  onPressed: _addLinkSlot,
                                  icon: const Icon(Icons.add, size: 16),
                                  label: const Text('Add Link'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: tokens.primary,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Save URLs (videos, docs, sheets) and explain what each link is for ("ye kis chij ke liye hai").',
                              style: context.getTextStyle(
                                fontSize: 11,
                                color: tokens.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Link Drafts
                            ..._linkDrafts.asMap().entries.map((entry) {
                              final index = entry.key;
                              final draft = entry.value;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: tokens.cardColor,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: tokens.borderColor),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: tokens.primary.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'Link #${index + 1}',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: tokens.primary,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        // Link Category selector
                                        DropdownButton<String>(
                                          value: draft.category,
                                          underline: const SizedBox.shrink(),
                                          dropdownColor: tokens.cardColor,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: tokens.textPrimary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          items: _linkCategoryPresets.map((cat) {
                                            return DropdownMenuItem<String>(
                                              value: cat,
                                              child: Text(cat),
                                            );
                                          }).toList(),
                                          onChanged: (val) {
                                            if (val != null) {
                                              setState(() => draft.category = val);
                                            }
                                          },
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.delete_outline,
                                              color: tokens.error, size: 18),
                                          tooltip: 'Remove link',
                                          onPressed: () => _removeLinkSlot(index),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    // URL Field
                                    Row(
                                      children: [
                                        Expanded(
                                          child: DayFlowTextField(
                                            controller: draft.urlController,
                                            hintText: 'https://example.com/lecture-notes',
                                            prefixIcon: const Icon(Icons.language, size: 18),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        IconButton(
                                          icon: const Icon(Icons.content_paste, size: 18),
                                          tooltip: 'Paste from Clipboard',
                                          onPressed: () => _pasteUrlInto(draft.urlController),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    // Purpose / "Ye kis chij ke liye hai"
                                    DayFlowTextField(
                                      controller: draft.labelController,
                                      hintText: 'Ye kis chij ke liye hai? e.g. Chapter 4 Video, Formula Sheet PDF...',
                                      prefixIcon: const Icon(Icons.description_outlined, size: 18),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Tags
                      Text(
                        'Tags (optional)',
                        style: context.getTextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: tokens.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: DayFlowTextField(
                              controller: _tagController,
                              hintText: 'Add tag (e.g. Physics, Sem2, Urgent)...',
                              onFieldSubmitted: (_) => _addTag(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(Icons.add_circle, color: tokens.primary),
                            onPressed: _addTag,
                          ),
                        ],
                      ),
                      if (_tags.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _tags.map((t) {
                            return Chip(
                              backgroundColor: tokens.surface,
                              side: BorderSide(color: tokens.borderColor),
                              label: Text(
                                '#$t',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: tokens.textPrimary,
                                ),
                              ),
                              deleteIcon: const Icon(Icons.close, size: 14),
                              onDeleted: () {
                                setState(() => _tags.remove(t));
                              },
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 16),

                      // Pin to Top Switch
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Pin to Top of Resource Hub',
                          style: context.getTextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: tokens.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          'Keep this study material at the top of your tracker',
                          style: context.getTextStyle(
                            fontSize: 11,
                            color: tokens.textSecondary,
                          ),
                        ),
                        value: _isPinned,
                        activeColor: tokens.primary,
                        onChanged: (val) => setState(() => _isPinned = val),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Bottom Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  DayFlowButton(
                    label: 'Cancel',
                    variant: DayFlowButtonVariant.outline,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 10),
                  DayFlowButton(
                    label: isEditing ? 'Update Note' : 'Save Note',
                    icon: Icons.check,
                    variant: DayFlowButtonVariant.primary,
                    onPressed: _save,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
