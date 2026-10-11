import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/dayflow_theme_context.dart';
import '../../../models/diary_entry_model.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/dayflow_chip.dart';

class JournalEditorScreen extends ConsumerStatefulWidget {
  final DiaryEntry? initialEntry;
  final DateTime? defaultDate;

  const JournalEditorScreen({
    super.key,
    this.initialEntry,
    this.defaultDate,
  });

  @override
  ConsumerState<JournalEditorScreen> createState() =>
      _JournalEditorScreenState();
}

class _JournalEditorScreenState extends ConsumerState<JournalEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _tagInputController;

  late String _id;
  late DateTime _entryDate;
  String _mood = 'Good';
  bool _isFavorite = false;
  List<String> _tags = [];
  List<String> _imagePaths = [];

  Timer? _autosaveTimer;
  bool _hasUnsavedChanges = false;
  DateTime? _lastSavedAt;

  final List<String> _moods = [
    '🌟 Great',
    '✨ Inspired',
    '😊 Good',
    '🌿 Calm',
    '💖 Grateful',
    '💭 Reflective',
    '🌧️ Low',
    '🌙 Tired',
  ];

  @override
  void initState() {
    super.initState();
    final entry = widget.initialEntry;
    _id = entry?.id ?? const Uuid().v4();
    _entryDate = entry?.entryDate ?? widget.defaultDate ?? DateTime.now();
    _titleController = TextEditingController(text: entry?.title ?? '');
    _contentController = TextEditingController(text: entry?.content ?? '');
    _tagInputController = TextEditingController();

    final rawMood = entry?.mood ?? 'Good';
    _mood = _moods.firstWhere(
      (m) => m.toLowerCase().contains(rawMood.toLowerCase()),
      orElse: () => '😊 Good',
    );
    _isFavorite = entry?.isFavorite ?? false;
    _tags = entry != null ? List.from(entry.tags) : [];
    _imagePaths = entry != null ? List.from(entry.imagePaths) : [];

    _titleController.addListener(_onTextChanged);
    _contentController.addListener(_onTextChanged);

    // Setup periodic autosave every 5 seconds if changed
    _autosaveTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_hasUnsavedChanges) {
        _saveEntry(isSilentAutosave: true);
      }
    });
  }

  void _onTextChanged() {
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    if (_hasUnsavedChanges) {
      _saveEntry(isSilentAutosave: true);
    }
    _titleController.dispose();
    _contentController.dispose();
    _tagInputController.dispose();
    super.dispose();
  }

  void _addTag() {
    final t = _tagInputController.text.trim().replaceAll('#', '');
    if (t.isNotEmpty && !_tags.contains(t)) {
      setState(() {
        _tags.add(t);
        _hasUnsavedChanges = true;
      });
      _tagInputController.clear();
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
      _hasUnsavedChanges = true;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() {
          _imagePaths.add(picked.path);
          _hasUnsavedChanges = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not attach image: $e')),
        );
      }
    }
  }

  Future<void> _pickMultipleImages() async {
    try {
      final picker = ImagePicker();
      final pickedList = await picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (pickedList.isNotEmpty) {
        setState(() {
          for (final f in pickedList) {
            if (!_imagePaths.contains(f.path)) {
              _imagePaths.add(f.path);
            }
          }
          _hasUnsavedChanges = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not attach images: $e')),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imagePaths.removeAt(index);
      _hasUnsavedChanges = true;
    });
  }

  void _showImagePickerOptions() {
    final tokens = context.themeTokens;
    showModalBottomSheet(
      context: context,
      backgroundColor: tokens.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Photo to Diary 📸',
                style: ctx.getTextStyle(
                  fontSize: 18,
                  fontWeight: tokens.headingWeight,
                  color: tokens.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: tokens.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.photo_library_outlined,
                      color: tokens.primary),
                ),
                title: Text('Choose from Gallery',
                    style: ctx.getTextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: tokens.textPrimary)),
                subtitle: Text('Select one or multiple photos',
                    style: ctx.getTextStyle(
                        fontSize: 12, color: tokens.textSecondary)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickMultipleImages();
                },
              ),
              const SizedBox(height: 6),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: tokens.secondary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.camera_alt_outlined,
                      color: tokens.secondary),
                ),
                title: Text('Take Photo with Camera',
                    style: ctx.getTextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: tokens.textPrimary)),
                subtitle: Text('Capture a moment right now',
                    style: ctx.getTextStyle(
                        fontSize: 12, color: tokens.textSecondary)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _previewImage(String path) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                File(path),
                fit: BoxFit.contain,
              ),
            ),
            IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.black54,
                radius: 16,
                child: Icon(Icons.close, color: Colors.white, size: 18),
              ),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      ),
    );
  }

  void _saveEntry({bool isSilentAutosave = false}) {
    final title = _titleController.text.trim().isEmpty
        ? 'Untitled Entry'
        : _titleController.text.trim();
    final content = _contentController.text.trim();

    // If both empty and no images, don't save empty ghost notes
    if (title == 'Untitled Entry' &&
        content.isEmpty &&
        _imagePaths.isEmpty &&
        widget.initialEntry == null) {
      return;
    }

    final cleanMood = _mood.contains(' ')
        ? _mood.split(' ').sublist(1).join(' ')
        : _mood;

    final entry = DiaryEntry(
      id: _id,
      title: title,
      content: content,
      entryDate: _entryDate,
      tags: _tags,
      imagePaths: _imagePaths,
      mood: cleanMood,
      isFavorite: _isFavorite,
      createdAt: widget.initialEntry?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (widget.initialEntry != null || _lastSavedAt != null) {
      ref.read(diaryProvider.notifier).updateEntry(entry);
    } else {
      ref.read(diaryProvider.notifier).createEntry(entry);
    }

    _hasUnsavedChanges = false;
    _lastSavedAt = DateTime.now();

    if (!isSilentAutosave && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Diary entry saved!'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.themeTokens;
    final wordCount = _contentController.text.trim().isEmpty
        ? 0
        : _contentController.text.trim().split(RegExp(r'\s+')).length;
    final readTimeMin = (wordCount / 200).ceil().clamp(1, 60);

    return Scaffold(
      backgroundColor: tokens.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('MMMM d, y').format(_entryDate),
              style: context.getTextStyle(
                fontSize: 16,
                fontWeight: tokens.headingWeight,
                color: tokens.textPrimary,
              ),
            ),
            Text(
              _lastSavedAt != null
                  ? 'Autosaved at ${DateFormat("h:mm a").format(_lastSavedAt!)}'
                  : _hasUnsavedChanges
                      ? 'Unsaved changes'
                      : 'Saved',
              style: context.getTextStyle(
                fontSize: 11,
                color: _hasUnsavedChanges ? tokens.warning : tokens.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate_outlined),
            tooltip: 'Add Photo',
            color: tokens.textPrimary,
            onPressed: _showImagePickerOptions,
          ),
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.star : Icons.star_border,
              color: _isFavorite ? tokens.warning : tokens.textSecondary,
            ),
            onPressed: () {
              setState(() {
                _isFavorite = !_isFavorite;
                _hasUnsavedChanges = true;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Save',
            color: tokens.primary,
            onPressed: () {
              _saveEntry();
              Navigator.of(context).pop();
            },
          ),
          if (widget.initialEntry != null)
            IconButton(
              icon: Icon(Icons.delete_outline, color: tokens.error),
              tooltip: 'Delete',
              onPressed: () {
                ref.read(diaryProvider.notifier).deleteEntry(_id);
                Navigator.of(context).pop();
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Metadata Bar: Mood selector & Reading stats
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: tokens.screenPadding,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: tokens.surface,
                border: Border(bottom: BorderSide(color: tokens.borderColor)),
              ),
              child: Row(
                children: [
                  Text(
                    'Mood: ',
                    style: context.getTextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: tokens.textSecondary,
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _moods.map((m) {
                          final isSelected = _mood == m;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: DayFlowChip(
                              label: m,
                              isSelected: isSelected,
                              onTap: () {
                                setState(() {
                                  _mood = m;
                                  _hasUnsavedChanges = true;
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$wordCount words • ${readTimeMin}m read',
                    style: context.getTextStyle(
                      fontSize: 11,
                      color: tokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Writing Area
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(tokens.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title field
                    TextField(
                      controller: _titleController,
                      style: context.getTextStyle(
                        fontSize: 22,
                        fontWeight: tokens.headingWeight,
                        color: tokens.textPrimary,
                      ),
                      cursorColor: tokens.primary,
                      decoration: InputDecoration(
                        hintText: 'Entry Title...',
                        hintStyle: context.getTextStyle(
                          fontSize: 22,
                          fontWeight: tokens.headingWeight,
                          color: tokens.textSecondary.withOpacity(0.5),
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                    const Divider(height: 20),

                    // Attached Images Strip
                    if (_imagePaths.isNotEmpty) ...[
                      SizedBox(
                        height: 110,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _imagePaths.length + 1,
                          separatorBuilder: (_, _) =>
                              const SizedBox(width: 10),
                          itemBuilder: (ctx, index) {
                            if (index == _imagePaths.length) {
                              return InkWell(
                                onTap: _showImagePickerOptions,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: 90,
                                  decoration: BoxDecoration(
                                    color: tokens.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: tokens.borderColor,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_photo_alternate_outlined,
                                          color: tokens.primary, size: 24),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Add More',
                                        style: ctx.getTextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: tokens.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            final path = _imagePaths[index];
                            final file = File(path);
                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                GestureDetector(
                                  onTap: () => _previewImage(path),
                                  child: Container(
                                    width: 100,
                                    decoration: BoxDecoration(
                                      borderRadius:
                                          BorderRadius.circular(12),
                                      border: Border.all(
                                        color: tokens.borderColor,
                                        width: tokens.borderWidth,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(12),
                                      child: file.existsSync()
                                          ? Image.file(
                                              file,
                                              fit: BoxFit.cover,
                                              width: 100,
                                              height: 110,
                                            )
                                          : Container(
                                              color: tokens.surface,
                                              child: Icon(
                                                Icons.broken_image,
                                                color: tokens.textSecondary,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Content field (Distraction-free)
                    TextField(
                      controller: _contentController,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      style: context.getTextStyle(
                        fontSize: 16,
                        height: 1.6,
                        color: tokens.textPrimary,
                      ),
                      cursorColor: tokens.primary,
                      decoration: InputDecoration(
                        hintText:
                            'Write your thoughts, reflections, milestones, or ideas for today...',
                        hintStyle: context.getTextStyle(
                          fontSize: 16,
                          color: tokens.textSecondary.withOpacity(0.5),
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Tags & Media Bottom Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: tokens.surface,
                border: Border(top: BorderSide(color: tokens.borderColor)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.add_photo_alternate_outlined,
                        size: 20, color: tokens.primary),
                    tooltip: 'Attach Photo',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: _showImagePickerOptions,
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.label_outline,
                      size: 18, color: tokens.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ..._tags.map((tag) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Chip(
                                label: Text(
                                  '#$tag',
                                  style: context.getTextStyle(
                                    fontSize: 11,
                                    color: tokens.textPrimary,
                                  ),
                                ),
                                deleteIcon: const Icon(Icons.close, size: 12),
                                onDeleted: () => _removeTag(tag),
                                backgroundColor: tokens.background,
                                padding: EdgeInsets.zero,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                            );
                          }),
                          SizedBox(
                            width: 120,
                            child: TextField(
                              controller: _tagInputController,
                              style: context.getTextStyle(
                                fontSize: 12,
                                color: tokens.textPrimary,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Add tag...',
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              onSubmitted: (_) => _addTag(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 18),
                    onPressed: _addTag,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
