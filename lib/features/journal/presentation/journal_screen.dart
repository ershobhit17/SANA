import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/dayflow_theme_context.dart';
import '../../../models/diary_entry_model.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/dayflow_card.dart';
import '../../../shared/widgets/dayflow_chip.dart';
import '../../../shared/widgets/dayflow_empty_state.dart';
import '../../../shared/widgets/dayflow_text_field.dart';
import 'journal_editor_screen.dart';

class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  String _searchQuery = '';
  bool _onlyFavorites = false;
  String? _selectedTag;
  String? _selectedMood;
  final TextEditingController _searchController = TextEditingController();

  bool _isUnlocked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAppLock();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _checkAppLock() {
    final settings = ref.read(appSettingsProvider);
    if (settings.appLockEnabled &&
        settings.appLockPin != null &&
        !_isUnlocked) {
      _showPinDialog(settings.appLockPin!);
    } else {
      setState(() => _isUnlocked = true);
    }
  }

  void _showPinDialog(String expectedPin) {
    final tokens = context.themeTokens;
    final pinController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: tokens.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.cardRadius),
          side: BorderSide(color: tokens.borderColor),
        ),
        title: Row(
          children: [
            Icon(Icons.lock, color: tokens.primary),
            const SizedBox(width: 8),
            Text(
              'Journal Locked',
              style: ctx.getTextStyle(
                fontSize: 18,
                fontWeight: tokens.headingWeight,
                color: tokens.textPrimary,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter your 4-digit PIN to access private journal entries:',
              style: ctx.getTextStyle(
                fontSize: 13,
                color: tokens.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            DayFlowTextField(
              controller: pinController,
              hintText: '4-digit PIN',
              keyboardType: TextInputType.number,
              obscureText: true,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: Text('Cancel',
                style: ctx.getTextStyle(color: tokens.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              if (pinController.text.trim() == expectedPin) {
                setState(() => _isUnlocked = true);
                Navigator.of(ctx).pop();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Incorrect PIN. Access denied.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: Text(
              'Unlock',
              style: ctx.getTextStyle(
                color: tokens.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openEditor([DiaryEntry? entry]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => JournalEditorScreen(initialEntry: entry),
      ),
    );
  }

  Future<bool> _confirmDeleteEntry(DiaryEntry entry) async {
    final tokens = context.themeTokens;
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: tokens.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.cardRadius),
          side: BorderSide(color: tokens.borderColor),
        ),
        title: Row(
          children: [
            Icon(Icons.delete_outline, color: tokens.error, size: 24),
            const SizedBox(width: 8),
            Text(
              'Delete Entry',
              style: ctx.getTextStyle(
                fontSize: 18,
                fontWeight: tokens.headingWeight,
                color: tokens.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          'Delete journal entry "${entry.title}"? This cannot be undone.',
          style: ctx.getTextStyle(
            fontSize: 14,
            color: tokens.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel',
                style: ctx.getTextStyle(color: tokens.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop(true);
            },
            child: Text(
              'Delete',
              style: ctx.getTextStyle(
                color: tokens.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (res == true && mounted) {
      final deleted = entry;
      ref.read(diaryProvider.notifier).deleteEntry(entry.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Entry "${entry.title}" deleted'),
          action: SnackBarAction(
            label: 'UNDO',
            textColor: tokens.primary,
            onPressed: () {
              ref.read(diaryProvider.notifier).createEntry(deleted);
            },
          ),
        ),
      );
      return true;
    }
    return false;
  }

  String _getMoodEmoji(String mood) {
    switch (mood.toLowerCase()) {
      case 'great':
        return '🌟';
      case 'inspired':
        return '✨';
      case 'good':
        return '😊';
      case 'calm':
        return '🌿';
      case 'grateful':
        return '💖';
      case 'reflective':
        return '💭';
      case 'low':
        return '🌧️';
      case 'tired':
        return '🌙';
      default:
        return '✨';
    }
  }

  Color _getMoodColor(String mood, BuildContext context) {
    final tokens = context.themeTokens;
    switch (mood.toLowerCase()) {
      case 'great':
        return const Color(0xFFF59E0B);
      case 'inspired':
        return const Color(0xFFA855F7);
      case 'good':
        return const Color(0xFF10B981);
      case 'calm':
        return const Color(0xFF06B6D4);
      case 'grateful':
        return const Color(0xFFEC4899);
      case 'reflective':
        return tokens.primary;
      case 'low':
        return const Color(0xFF64748B);
      case 'tired':
        return const Color(0xFF6366F1);
      default:
        return tokens.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.themeTokens;
    final allEntries = ref.watch(diaryProvider);

    if (!_isUnlocked) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 48, color: tokens.textSecondary),
              const SizedBox(height: 12),
              Text(
                'Journal is Locked',
                style: context.getTextStyle(
                  fontSize: 16,
                  fontWeight: tokens.headingWeight,
                  color: tokens.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: tokens.primary,
                  foregroundColor: Colors.black,
                ),
                onPressed: _checkAppLock,
                icon: const Icon(Icons.key),
                label: const Text('Enter PIN to Unlock'),
              ),
            ],
          ),
        ),
      );
    }

    // Filter logic
    final filteredEntries = allEntries.where((entry) {
      if (_onlyFavorites && !entry.isFavorite) return false;
      if (_selectedMood != null &&
          entry.mood.toLowerCase() != _selectedMood!.toLowerCase()) {
        return false;
      }
      if (_selectedTag != null && !entry.tags.contains(_selectedTag)) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchTitle = entry.title.toLowerCase().contains(q);
        final matchContent = entry.content.toLowerCase().contains(q);
        final matchTag =
            entry.tags.any((t) => t.toLowerCase().contains(q));
        if (!matchTitle && !matchContent && !matchTag) return false;
      }
      return true;
    }).toList();

    // Extract all unique tags
    final Set<String> allTags = {};
    for (final e in allEntries) {
      allTags.addAll(e.tags);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'Personal Diary',
          style: context.getTextStyle(
            fontSize: 20,
            fontWeight: tokens.headingWeight,
            color: tokens.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _onlyFavorites ? Icons.star : Icons.star_border,
              color: _onlyFavorites ? tokens.warning : tokens.textSecondary,
            ),
            tooltip: 'Filter Favorites',
            onPressed: () =>
                setState(() => _onlyFavorites = !_onlyFavorites),
          ),
          IconButton.filled(
            style: IconButton.styleFrom(
              backgroundColor: tokens.primary,
              foregroundColor: tokens.primary.computeLuminance() > 0.4
                  ? Colors.black
                  : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(tokens.buttonRadius),
              ),
            ),
            icon: const Icon(Icons.edit_note),
            tooltip: 'Write Entry',
            onPressed: () => _openEditor(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Aesthetic Inspiration Banner
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: tokens.screenPadding,
                vertical: 4,
              ),
              child: DayFlowCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: tokens.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('✨', style: TextStyle(fontSize: 18)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '"Small daily reflections become life\'s greatest wisdom."',
                            style: context
                                .getTextStyle(
                                  fontSize: 12,
                                  color: tokens.textPrimary,
                                )
                                .copyWith(fontStyle: FontStyle.italic),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${allEntries.length} entries preserved in your journal',
                            style: context.getTextStyle(
                              fontSize: 11,
                              color: tokens.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Search Bar
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: tokens.screenPadding,
                vertical: 4,
              ),
              child: DayFlowTextField(
                controller: _searchController,
                hintText: 'Search journal entries or reflections...',
                prefixIcon: Icon(Icons.search, color: tokens.textSecondary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        color: tokens.textSecondary,
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
              ),
            ),

            // Filter Chips (Tags & Moods)
            if (allTags.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(
                  horizontal: tokens.screenPadding,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    DayFlowChip(
                      label: 'All Tags',
                      isSelected: _selectedTag == null,
                      onTap: () => setState(() => _selectedTag = null),
                    ),
                    const SizedBox(width: 6),
                    ...allTags.map((tag) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: DayFlowChip(
                          label: '#$tag',
                          isSelected: _selectedTag == tag,
                          onTap: () => setState(() {
                            _selectedTag = _selectedTag == tag ? null : tag;
                          }),
                        ),
                      );
                    }),
                  ],
                ),
              ),

            // Entries List
            Expanded(
              child: filteredEntries.isEmpty
                  ? DayFlowEmptyState(
                      icon: Icons.menu_book,
                      title: _searchQuery.isNotEmpty
                          ? 'No matching entries'
                          : 'Your thoughts, preserved in DayFlow',
                      message: _searchQuery.isNotEmpty
                          ? 'Try adjusting your search criteria.'
                          : 'Record your daily reflections, creative ideas, milestones, and memories.',
                      actionLabel: 'Write First Entry',
                      onAction: () => _openEditor(),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.fromLTRB(
                        tokens.screenPadding,
                        6,
                        tokens.screenPadding,
                        80,
                      ),
                      itemCount: filteredEntries.length,
                      itemBuilder: (context, index) {
                        final entry = filteredEntries[index];
                        return _buildJournalCard(entry);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJournalCard(DiaryEntry entry) {
    final tokens = context.themeTokens;
    final dateStr = DateFormat('EEE, MMM d, y').format(entry.entryDate);
    final timeStr = DateFormat('h:mm a').format(entry.updatedAt);
    final moodEmoji = _getMoodEmoji(entry.mood);
    final moodColor = _getMoodColor(entry.mood, context);

    return Padding(
      padding: EdgeInsets.only(bottom: tokens.itemSpacing),
      child: Dismissible(
        key: Key('journal_${entry.id}'),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) => _confirmDeleteEntry(entry),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: tokens.error.withOpacity(0.85),
            borderRadius: BorderRadius.circular(tokens.cardRadius),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(Icons.delete_outline, color: Colors.white, size: 24),
              SizedBox(width: 6),
              Text(
                'Delete',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        child: DayFlowCard(
          padding: EdgeInsets.all(tokens.cardPadding),
          onTap: () => _openEditor(entry),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Date & Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: moodColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: moodColor.withOpacity(0.25), width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(moodEmoji, style: const TextStyle(fontSize: 12)),
                            const SizedBox(width: 4),
                            Text(
                              entry.mood,
                              style: context.getTextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: moodColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$dateStr • $timeStr',
                        style: context.getTextStyle(
                          fontSize: 11,
                          color: tokens.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(4),
                        icon: Icon(
                          entry.isFavorite ? Icons.star : Icons.star_border,
                          size: 20,
                          color: entry.isFavorite
                              ? tokens.warning
                              : tokens.textSecondary.withOpacity(0.6),
                        ),
                        onPressed: () {
                          ref
                              .read(diaryProvider.notifier)
                              .toggleFavorite(entry.id);
                        },
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(4),
                        icon: Icon(
                          Icons.delete_outline,
                          size: 19,
                          color: tokens.textSecondary.withOpacity(0.6),
                        ),
                        tooltip: 'Delete Entry',
                        onPressed: () => _confirmDeleteEntry(entry),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Title
              Text(
                entry.title,
                style: context.getTextStyle(
                  fontSize: 16,
                  fontWeight: tokens.headingWeight,
                  color: tokens.textPrimary,
                ),
              ),

              // Content snippet
              if (entry.content.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  entry.content,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: context.getTextStyle(
                    fontSize: 13,
                    color: tokens.textSecondary,
                    height: 1.55,
                  ),
                ),
              ],

              // Attached Images
              if (entry.imagePaths.isNotEmpty) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 64,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: entry.imagePaths.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 6),
                    itemBuilder: (ctx, idx) {
                      final f = File(entry.imagePaths[idx]);
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: f.existsSync()
                            ? Image.file(
                                f,
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 64,
                                height: 64,
                                color: tokens.surface,
                                child: Icon(Icons.image,
                                    size: 20, color: tokens.textSecondary),
                              ),
                      );
                    },
                  ),
                ),
              ],

              const SizedBox(height: 10),

              // Footer: Word count & Tags
              Row(
                children: [
                  Icon(Icons.text_snippet_outlined,
                      size: 13, color: tokens.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '${entry.wordCount} words • ${entry.estimatedReadMinutes}m read',
                    style: context.getTextStyle(
                      fontSize: 11,
                      color: tokens.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  if (entry.tags.isNotEmpty)
                    Wrap(
                      spacing: 4,
                      children: entry.tags.take(3).map((t) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: tokens.surface,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                color: tokens.borderColor, width: 0.6),
                          ),
                          child: Text(
                            '#$t',
                            style: context.getTextStyle(
                              fontSize: 10,
                              color: tokens.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
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
