import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/dayflow_theme_context.dart';
import '../../../core/utils/url_launcher_helper.dart';
import '../../../models/study_note_model.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/dayflow_chip.dart';
import '../../../shared/widgets/dayflow_empty_state.dart';
import '../../../shared/widgets/dayflow_text_field.dart';
import 'note_form_dialog.dart';

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool _onlyPinned = false;
  bool _onlyWithLinks = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openNoteDialog([StudyNoteItem? note]) {
    showDialog(
      context: context,
      builder: (_) => NoteFormDialog(initialNote: note),
    );
  }

  void _confirmDeleteNote(StudyNoteItem note) {
    final tokens = context.themeTokens;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: tokens.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.cardRadius),
          side: BorderSide(color: tokens.borderColor),
        ),
        title: Text(
          'Delete Note?',
          style: ctx.getTextStyle(
            fontSize: 18,
            fontWeight: tokens.headingWeight,
            color: tokens.error,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${note.title}"? This cannot be undone.',
          style: ctx.getTextStyle(
            fontSize: 13,
            color: tokens.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel',
                style: ctx.getTextStyle(color: tokens.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              ref.read(notesProvider.notifier).deleteNote(note.id);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Note deleted successfully.'),
                  duration: Duration(seconds: 2),
                ),
              );
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
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.themeTokens;
    final allNotes = ref.watch(notesProvider);

    // Filter notes
    final filteredNotes = allNotes.where((note) {
      if (_onlyPinned && !note.isPinned) return false;
      if (_onlyWithLinks && note.links.isEmpty) return false;
      if (_selectedCategory != 'All' && note.category != _selectedCategory) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesTitle = note.title.toLowerCase().contains(q);
        final matchesContent = note.content.toLowerCase().contains(q);
        final matchesCategory = note.category.toLowerCase().contains(q);
        final matchesTags =
            note.tags.any((t) => t.toLowerCase().contains(q));
        final matchesLinks = note.links.any((l) =>
            l.url.toLowerCase().contains(q) ||
            l.label.toLowerCase().contains(q) ||
            l.category.toLowerCase().contains(q));

        return matchesTitle ||
            matchesContent ||
            matchesCategory ||
            matchesTags ||
            matchesLinks;
      }
      return true;
    }).toList();

    // Collect all unique categories
    final Set<String> categories = {'All'};
    for (final n in allNotes) {
      if (n.category.isNotEmpty) categories.add(n.category);
    }

    final totalLinksCount =
        allNotes.fold<int>(0, (sum, n) => sum + n.links.length);
    final pinnedCount = allNotes.where((n) => n.isPinned).length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Study Material & Notes',
              style: context.getTextStyle(
                fontSize: 20,
                fontWeight: tokens.headingWeight,
                color: tokens.textPrimary,
              ),
            ),
            Text(
              'Study links, documentation & knowledge hub',
              style: context.getTextStyle(
                fontSize: 11,
                color: tokens.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 26),
            tooltip: 'Add Note / Study Link',
            color: tokens.primary,
            onPressed: () => _openNoteDialog(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: tokens.primary,
        foregroundColor: tokens.primary.computeLuminance() > 0.4
            ? Colors.black
            : Colors.white,
        icon: const Icon(Icons.add, size: 22),
        label: const Text('Add Note', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _openNoteDialog(),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            tokens.screenPadding,
            tokens.screenPadding,
            tokens.screenPadding,
            90,
          ),
          children: [
            // Top Overview Metric Cards
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    label: 'Study Notes',
                    value: '${allNotes.length}',
                    icon: Icons.menu_book_rounded,
                    color: tokens.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricTile(
                    label: 'Saved Links',
                    value: '$totalLinksCount',
                    icon: Icons.link_rounded,
                    color: tokens.secondary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricTile(
                    label: 'Pinned',
                    value: '$pinnedCount',
                    icon: Icons.push_pin_rounded,
                    color: tokens.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Search Bar
            DayFlowTextField(
              controller: _searchController,
              hintText: 'Search notes, links, subjects, topics...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
            ),
            const SizedBox(height: 12),

            // Filter Chips Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  // Pinned filter pill
                  DayFlowChip(
                    label: '⭐ Pinned',
                    isSelected: _onlyPinned,
                    onTap: () => setState(() => _onlyPinned = !_onlyPinned),
                  ),
                  const SizedBox(width: 8),
                  // With links only pill
                  DayFlowChip(
                    label: '🔗 With Links',
                    isSelected: _onlyWithLinks,
                    onTap: () =>
                        setState(() => _onlyWithLinks = !_onlyWithLinks),
                  ),
                  const SizedBox(width: 8),
                  ...categories.map((c) {
                    final isSel = _selectedCategory == c;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: DayFlowChip(
                        label: c,
                        isSelected: isSel,
                        onTap: () => setState(() => _selectedCategory = c),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Notes List or Empty State
            if (filteredNotes.isEmpty)
              DayFlowEmptyState(
                icon: Icons.menu_book_outlined,
                title: _searchQuery.isNotEmpty
                    ? 'No matching notes found'
                    : 'No study notes yet',
                message: _searchQuery.isNotEmpty
                    ? 'Try searching with a different subject, link, or keyword.'
                    : 'Save study material, YouTube lectures, PDF cheat sheets, and documentation links with clear explanations.',
                actionLabel: 'Create First Study Note',
                onAction: () => _openNoteDialog(),
              )
            else
              ...filteredNotes.map((note) => _buildNoteCard(note)),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final tokens = context.themeTokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: tokens.cardColor,
        borderRadius: BorderRadius.circular(tokens.cardRadius),
        border: Border.all(color: tokens.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.getTextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: tokens.textPrimary,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.getTextStyle(
                    fontSize: 10,
                    color: tokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(StudyNoteItem note) {
    final tokens = context.themeTokens;
    final dateStr = DateFormat('MMM d, y • h:mm a').format(note.updatedAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: tokens.cardColor,
        borderRadius: BorderRadius.circular(tokens.cardRadius),
        border: Border.all(
          color: note.isPinned ? tokens.primary : tokens.borderColor,
          width: note.isPinned ? 1.8 : tokens.borderWidth,
        ),
        boxShadow: note.isPinned
            ? [
                BoxShadow(
                  color: tokens.primary.withOpacity(0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                )
              ]
            : null,
      ),
      child: Padding(
        padding: EdgeInsets.all(tokens.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Category chip, Date, Pin toggle, Menu
            Row(
              children: [
                // Category Chip
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: tokens.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    note.category,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: tokens.primary,
                    ),
                  ),
                ),
                if (note.isPinned) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: tokens.warning.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.push_pin, size: 10, color: tokens.warning),
                        const SizedBox(width: 2),
                        Text(
                          'Pinned',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: tokens.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  dateStr,
                  style: TextStyle(fontSize: 10, color: tokens.textSecondary),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(
                    note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                    size: 18,
                    color: note.isPinned ? tokens.primary : tokens.textSecondary,
                  ),
                  tooltip: note.isPinned ? 'Unpin note' : 'Pin note',
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    ref.read(notesProvider.notifier).togglePin(note.id);
                  },
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, size: 18, color: tokens.textSecondary),
                  color: tokens.cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: tokens.borderColor),
                  ),
                  onSelected: (val) {
                    if (val == 'edit') {
                      _openNoteDialog(note);
                    } else if (val == 'delete') {
                      _confirmDeleteNote(note);
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 16, color: tokens.textPrimary),
                          const SizedBox(width: 8),
                          Text('Edit Note', style: TextStyle(color: tokens.textPrimary)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 16, color: tokens.error),
                          const SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: tokens.error)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Note Title
            Text(
              note.title,
              style: context.getTextStyle(
                fontSize: 17,
                fontWeight: tokens.headingWeight,
                color: tokens.textPrimary,
              ),
            ),

            // Note Content
            if (note.content.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                note.content,
                style: context.getTextStyle(
                  fontSize: 13,
                  color: tokens.textSecondary,
                ),
              ),
            ],

            // Study Links List
            if (note.links.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: tokens.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: tokens.borderColor.withOpacity(0.6)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
                      child: Row(
                        children: [
                          Icon(Icons.link_rounded, size: 14, color: tokens.primary),
                          const SizedBox(width: 6),
                          Text(
                            'Study Resources & Links (${note.links.length})',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: tokens.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    ...note.links.map((link) => _buildLinkTile(link)),
                  ],
                ),
              ),
            ],

            // Tags
            if (note.tags.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: note.tags.map((t) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: tokens.surface,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: tokens.borderColor),
                    ),
                    child: Text(
                      '#$t',
                      style: TextStyle(
                        fontSize: 10,
                        color: tokens.textSecondary,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLinkTile(StudyNoteLink link) {
    final tokens = context.themeTokens;

    IconData linkIcon;
    switch (link.category.toLowerCase()) {
      case 'video':
        linkIcon = Icons.play_circle_outline_rounded;
        break;
      case 'docs':
        linkIcon = Icons.article_outlined;
        break;
      case 'github':
        linkIcon = Icons.code_rounded;
        break;
      case 'pdf':
        linkIcon = Icons.picture_as_pdf_outlined;
        break;
      case 'practice':
        linkIcon = Icons.fitness_center_rounded;
        break;
      default:
        linkIcon = Icons.language_rounded;
    }

    return InkWell(
      onTap: () => UrlLauncherHelper.openUrl(context, link.url),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                color: tokens.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(linkIcon, size: 16, color: tokens.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Purpose / "Ye kis chij ke liye hai"
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          link.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: tokens.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: tokens.surface,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: tokens.borderColor),
                        ),
                        child: Text(
                          link.category,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: tokens.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  // Raw URL
                  Text(
                    link.url,
                    style: TextStyle(
                      fontSize: 11,
                      color: tokens.primary,
                      decoration: TextDecoration.underline,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Quick Action Buttons (Open & Copy)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  tooltip: 'Copy Link',
                  visualDensity: VisualDensity.compact,
                  onPressed: () =>
                      UrlLauncherHelper.copyToClipboard(context, link.url),
                ),
                IconButton(
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  tooltip: 'Open in Browser',
                  color: tokens.primary,
                  visualDensity: VisualDensity.compact,
                  onPressed: () =>
                      UrlLauncherHelper.openUrl(context, link.url),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
