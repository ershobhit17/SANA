import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/dayflow_theme_context.dart';
import '../../../core/theme/dayflow_theme_notifier.dart';
import '../../../core/theme/dayflow_theme_presets.dart';
import '../../../core/theme/dayflow_theme_tokens.dart';
import '../../../shared/widgets/dayflow_button.dart';
import '../../../shared/widgets/dayflow_chip.dart';
import '../../../shared/widgets/dayflow_text_field.dart';

class ThemeStudioScreen extends ConsumerStatefulWidget {
  const ThemeStudioScreen({super.key});

  @override
  ConsumerState<ThemeStudioScreen> createState() => _ThemeStudioScreenState();
}

class _ThemeStudioScreenState extends ConsumerState<ThemeStudioScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late DayFlowThemeTokens _editableTheme;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _editableTheme = ref.read(activeThemeTokensProvider);
  }

  void _applyAndSave() {
    ref.read(themeNotifierProvider.notifier).updateCurrentTheme(_editableTheme);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Theme "${_editableTheme.name}" applied across SANA!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _saveAsCustom() {
    final nameController =
        TextEditingController(text: '${_editableTheme.name} Custom');
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
          'Save as Custom Theme',
          style: ctx.getTextStyle(
            fontSize: 18,
            fontWeight: tokens.headingWeight,
            color: tokens.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Give your personalized theme a distinctive name:',
              style: ctx.getTextStyle(
                fontSize: 13,
                color: tokens.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            DayFlowTextField(
              controller: nameController,
              hintText: 'My Theme Name',
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel',
                style: ctx.getTextStyle(color: tokens.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty) {
                ref.read(themeNotifierProvider.notifier).createCustomTheme(
                      name: newName,
                      basedOn: _editableTheme,
                    );
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Custom theme "$newName" saved!'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            child: Text(
              'Save Theme',
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

  void _exportTheme() {
    final jsonStr = ref
        .read(themeNotifierProvider.notifier)
        .exportThemeToJson(_editableTheme);
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
          'Export Theme JSON',
          style: ctx.getTextStyle(
            fontSize: 18,
            fontWeight: tokens.headingWeight,
            color: tokens.textPrimary,
          ),
        ),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: SelectableText(
              jsonStr,
              style: ctx.getTextStyle(
                fontSize: 12,
                color: tokens.textSecondary,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Close',
                style: ctx.getTextStyle(color: tokens.primary)),
          ),
        ],
      ),
    );
  }

  void _importTheme() {
    final jsonController = TextEditingController();
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
          'Import Theme Configuration',
          style: ctx.getTextStyle(
            fontSize: 18,
            fontWeight: tokens.headingWeight,
            color: tokens.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Paste your SANA theme JSON configuration below:',
              style: ctx.getTextStyle(
                fontSize: 13,
                color: tokens.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            DayFlowTextField(
              controller: jsonController,
              hintText: '{"id":"custom...", ...}',
              maxLines: 5,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel',
                style: ctx.getTextStyle(color: tokens.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              final ok = ref
                  .read(themeNotifierProvider.notifier)
                  .importThemeFromJson(jsonController.text.trim());
              Navigator.of(ctx).pop();
              if (ok) {
                setState(() {
                  _editableTheme = ref.read(activeThemeTokensProvider);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Theme imported successfully!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Invalid theme JSON format.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: Text(
              'Import',
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

  @override
  Widget build(BuildContext context) {
    final tokens = context.themeTokens;
    final themeState = ref.watch(themeNotifierProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'Theme Studio',
          style: context.getTextStyle(
            fontSize: 20,
            fontWeight: tokens.headingWeight,
            color: tokens.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload_outlined),
            tooltip: 'Import Theme JSON',
            onPressed: _importTheme,
          ),
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Export Theme JSON',
            onPressed: _exportTheme,
          ),
          IconButton(
            icon: const Icon(Icons.restart_alt),
            tooltip: 'Reset to Default',
            onPressed: () {
              ref.read(themeNotifierProvider.notifier).resetToDefault();
              setState(() {
                _editableTheme = DayFlowThemePresets.obsidianAmoled;
              });
            },
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: tokens.surface,
          border: Border(top: BorderSide(color: tokens.borderColor)),
        ),
        child: Row(
          children: [
            Expanded(
              child: DayFlowButton(
                label: 'Save as Custom',
                icon: Icons.bookmark_add_outlined,
                variant: DayFlowButtonVariant.outline,
                onPressed: _saveAsCustom,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DayFlowButton(
                label: 'Apply Theme',
                icon: Icons.check,
                variant: DayFlowButtonVariant.primary,
                onPressed: _applyAndSave,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Interactive Live Preview Card
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: tokens.screenPadding,
                vertical: 6,
              ),
              child: _buildLivePreviewCard(_editableTheme),
            ),

            // Tab Bar for Controls
            TabBar(
              controller: _tabController,
              labelColor: tokens.primary,
              unselectedLabelColor: tokens.textSecondary,
              indicatorColor: tokens.primary,
              tabs: const [
                Tab(text: 'Presets'),
                Tab(text: 'Colors'),
                Tab(text: 'Style'),
                Tab(text: 'Typography'),
              ],
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPresetsTab(themeState),
                  _buildColorsTab(),
                  _buildStyleTab(),
                  _buildTypographyTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLivePreviewCard(DayFlowThemeTokens t) {
    return Container(
      padding: EdgeInsets.all(t.cardPadding),
      decoration: BoxDecoration(
        color: t.cardColor,
        borderRadius: BorderRadius.circular(t.cardRadius),
        border: t.borderWidth > 0
            ? Border.all(
                color: t.borderColor,
                width: t.isBrutalist ? 2.5 : t.borderWidth,
              )
            : null,
        boxShadow: t.isBrutalist
            ? [
                BoxShadow(
                  color: Colors.black,
                  offset: t.brutalistShadowOffset,
                  blurRadius: 0,
                )
              ]
            : t.shadowBlurRadius > 0
                ? [
                    BoxShadow(
                      color: t.shadowColor,
                      blurRadius: t.shadowBlurRadius,
                      offset: t.shadowOffset,
                    )
                  ]
                : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: t.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    t.name,
                    style: TextStyle(
                      fontFamily: t.fontFamily,
                      fontSize: 16 * t.fontScale,
                      fontWeight: t.headingWeight,
                      color: t.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: t.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Live Preview',
                  style: TextStyle(
                    fontFamily: t.fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: t.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            t.description,
            style: TextStyle(
              fontFamily: t.fontFamily,
              fontSize: 12 * t.fontScale,
              color: t.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: t.primary,
                  borderRadius: BorderRadius.circular(t.buttonRadius),
                ),
                child: Text(
                  'Primary Button',
                  style: TextStyle(
                    fontFamily: t.fontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: t.primary.computeLuminance() > 0.4
                        ? Colors.black
                        : Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: t.secondary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(t.buttonRadius),
                  border: Border.all(color: t.secondary.withOpacity(0.4)),
                ),
                child: Text(
                  'Secondary',
                  style: TextStyle(
                    fontFamily: t.fontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: t.secondary,
                  ),
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  _colorDot(t.primary),
                  _colorDot(t.secondary),
                  _colorDot(t.accent),
                  _colorDot(t.success),
                  _colorDot(t.error),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _colorDot(Color c) {
    return Container(
      width: 12,
      height: 12,
      margin: const EdgeInsets.only(left: 4),
      decoration: BoxDecoration(
        color: c,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24, width: 1),
      ),
    );
  }

  Widget _buildPresetsTab(ThemeState state) {
    final tokens = context.themeTokens;
    final allPresets = DayFlowThemePresets.allBuiltInPresets;
    final customThemes = state.customThemes;

    return ListView(
      padding: EdgeInsets.all(tokens.screenPadding),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '10 Distinct UI Design Systems',
                  style: context.getTextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: tokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'True distinct visual identities, layout rules & motion',
                  style: context.getTextStyle(
                    fontSize: 12,
                    color: tokens.textSecondary,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: tokens.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: tokens.primary.withOpacity(0.3)),
              ),
              child: Text(
                '10 Styles',
                style: context.getTextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: tokens.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // The 10 Official UI Systems
        ...allPresets.asMap().entries.map((entry) {
          final index = entry.key;
          final p = entry.value;
          final isSelected = _editableTheme.id == p.id;
          return _buildDesignSystemGalleryCard(p, index + 1, isSelected);
        }),

        if (customThemes.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'Your Custom Themes',
            style: context.getTextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: tokens.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          ...customThemes.map((c) {
            final isSelected = _editableTheme.id == c.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: isSelected ? tokens.primary : tokens.borderColor,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                tileColor: tokens.cardColor,
                title: Text(
                  c.name,
                  style: context.getTextStyle(
                    fontWeight: FontWeight.bold,
                    color: tokens.textPrimary,
                  ),
                ),
                subtitle: Text(
                  c.description,
                  style: context.getTextStyle(
                    fontSize: 12,
                    color: tokens.textSecondary,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.copy, size: 18),
                      tooltip: 'Duplicate',
                      onPressed: () {
                        ref
                            .read(themeNotifierProvider.notifier)
                            .duplicateTheme(c);
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline,
                          size: 18, color: tokens.error),
                      tooltip: 'Delete',
                      onPressed: () {
                        ref
                            .read(themeNotifierProvider.notifier)
                            .deleteCustomTheme(c.id);
                      },
                    ),
                  ],
                ),
                onTap: () {
                  setState(() => _editableTheme = c);
                },
              ),
            );
          }),
        ],
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildDesignSystemGalleryCard(
      DayFlowThemeTokens p, int styleNum, bool isSelected) {
    final tokens = context.themeTokens;
    final styleNumStr = styleNum.toString().padLeft(2, '0');

    String modeLabel;
    if (p.isAmoled) {
      modeLabel = 'AMOLED';
    } else if (p.isDark) {
      modeLabel = 'Dark Mode';
    } else {
      modeLabel = 'Light Mode';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: tokens.cardColor,
        borderRadius: BorderRadius.circular(tokens.cardRadius),
        border: Border.all(
          color: isSelected ? tokens.primary : tokens.borderColor,
          width: isSelected ? 2.2 : tokens.borderWidth,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: tokens.primary.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header banner
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? tokens.primary
                            : tokens.surface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: isSelected
                                ? tokens.primary
                                : tokens.borderColor),
                      ),
                      child: Text(
                        'UI Style $styleNumStr',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? (tokens.primary.computeLuminance() > 0.4
                                  ? Colors.black
                                  : Colors.white)
                              : tokens.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      p.name,
                      style: TextStyle(
                        fontFamily: p.fontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: tokens.textPrimary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: tokens.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: tokens.borderColor),
                  ),
                  child: Text(
                    modeLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: tokens.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              p.description,
              style: context.getTextStyle(
                fontSize: 12,
                color: tokens.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Live Component Miniature Preview Box
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: p.background,
              borderRadius: BorderRadius.circular(p.cardRadius.clamp(6.0, 16.0)),
              border: Border.all(
                color: p.borderColor,
                width: p.isBrutalist ? 2.0 : p.borderWidth,
              ),
              boxShadow: p.isBrutalist
                  ? [
                      BoxShadow(
                        color: p.shadowColor,
                        offset: const Offset(3, 3),
                        blurRadius: 0,
                      )
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Inner mini card in that theme's style
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: p.cardColor,
                    borderRadius: BorderRadius.circular(p.cardRadius * 0.75),
                    border: Border.all(
                      color: p.isSpatial
                          ? p.primary.withOpacity(0.5)
                          : p.borderColor,
                      width: p.isBrutalist ? 2.0 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: p.primary.withOpacity(0.18),
                          borderRadius:
                              BorderRadius.circular(p.buttonRadius * 0.7),
                        ),
                        child: Icon(Icons.check_circle_outline,
                            size: 16, color: p.primary),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sample Task Card',
                              style: TextStyle(
                                fontFamily: p.fontFamily,
                                fontSize: 12,
                                fontWeight: p.headingWeight,
                                color: p.textPrimary,
                              ),
                            ),
                            Text(
                              'Font: ${p.fontFamily}',
                              style: TextStyle(
                                fontFamily: p.fontFamily,
                                fontSize: 10,
                                color: p.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: p.primary,
                          borderRadius:
                              BorderRadius.circular(p.buttonRadius * 0.7),
                          border: p.isBrutalist
                              ? Border.all(color: Colors.black, width: 1.5)
                              : null,
                        ),
                        child: Text(
                          'Action',
                          style: TextStyle(
                            fontFamily: p.fontFamily,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: p.primary.computeLuminance() > 0.4
                                ? Colors.black
                                : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Color palette row
                Row(
                  children: [
                    Text(
                      'Palette: ',
                      style: TextStyle(
                        fontFamily: p.fontFamily,
                        fontSize: 10,
                        color: p.textSecondary,
                      ),
                    ),
                    _colorDot(p.primary),
                    _colorDot(p.secondary),
                    _colorDot(p.accent),
                    _colorDot(p.background),
                    _colorDot(p.surface),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: p.surface,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: p.borderColor),
                      ),
                      child: Text(
                        p.designStyle.name,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: p.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Actions Row (Apply & Customize)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Row(
              children: [
                Expanded(
                  child: DayFlowButton(
                    label: isSelected ? 'Applied' : 'Apply Theme',
                    icon: isSelected ? Icons.check_circle : Icons.done,
                    variant: isSelected
                        ? DayFlowButtonVariant.secondary
                        : DayFlowButtonVariant.primary,
                    height: 38,
                    onPressed: () {
                      setState(() => _editableTheme = p);
                      ref
                          .read(themeNotifierProvider.notifier)
                          .updateCurrentTheme(p);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Theme "${p.name}" applied!'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                DayFlowButton(
                  label: 'Customize',
                  icon: Icons.tune,
                  variant: DayFlowButtonVariant.outline,
                  height: 38,
                  onPressed: () {
                    setState(() => _editableTheme = p);
                    _tabController.animateTo(1); // Jump to Colors tab
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openFullColorPickerDialog({
    required String title,
    required Color initialColor,
    required ValueChanged<Color> onSelected,
  }) async {
    final tokens = context.themeTokens;
    Color currentColor = initialColor;
    HSVColor hsv = HSVColor.fromColor(initialColor);
    final hexController = TextEditingController(
      text: initialColor.value
          .toRadixString(16)
          .padLeft(8, '0')
          .substring(2)
          .toUpperCase(),
    );

    final vibrantSwatches = [
      const Color(0xFFFFE600), // Electric Yellow
      const Color(0xFFFFB703), // Punch Amber
      const Color(0xFFFB8500), // Vibrant Tangerine
      const Color(0xFFFF007F), // Hot Neon Pink
      const Color(0xFFE11D48), // Ruby Rose
      const Color(0xFF8338EC), // Electric Purple
      const Color(0xFF6366F1), // Royal Indigo
      const Color(0xFF3A86FF), // Cyber Blue
      const Color(0xFF00F0FF), // Neon Cyan
      const Color(0xFF10B981), // Emerald
      const Color(0xFF00F0A8), // Mint Spark
      const Color(0xFF14B8A6), // Teal
    ];

    final darkAmoledSwatches = [
      const Color(0xFF000000), // Pure AMOLED Black
      const Color(0xFF0B0B0E), // Onyx
      const Color(0xFF0F172A), // Dark Slate
      const Color(0xFF121214), // Obsidian
      const Color(0xFF18181B), // Zinc Dark
      const Color(0xFF1A1D24), // Carbon
      const Color(0xFF0A1128), // Deep Midnight Navy
      const Color(0xFF06281D), // Deep Pine Forest
      const Color(0xFF1C0B14), // Deep Wine
      const Color(0xFF241505), // Dark Espresso
      const Color(0xFF262626), // Neutral Charcoal
      const Color(0xFF334155), // Steel Gray
    ];

    final pastelSoftSwatches = [
      const Color(0xFFFFFFFF), // Pure White
      const Color(0xFFF8FAFC), // Crisp Light
      const Color(0xFFF1F5F9), // Soft Cloud
      const Color(0xFFE2E8F0), // Platinum
      const Color(0xFFDDD6FE), // Lavender Mist
      const Color(0xFFFCE7F3), // Petal Pink
      const Color(0xFFFFEDD5), // Peach Whisper
      const Color(0xFFFEF3C7), // Warm Butter
      const Color(0xFFD1FAE5), // Mint Frost
      const Color(0xFFE0F2FE), // Sky Breeze
      const Color(0xFFF5F3EF), // Nordic Oatmeal
      const Color(0xFFFBF7EE), // Parchment
    ];

    final borderAccentSwatches = [
      const Color(0xFFFFE600), // Brutalist Yellow
      const Color(0xFFFF3366), // Signal Red
      const Color(0xFF000000), // Solid Black Border
      const Color(0xFFFFFFFF), // Solid White Border
      const Color(0xFF6366F1), // Indigo Border
      const Color(0xFF00F0FF), // Cyber Cyan Border
      const Color(0xFF10B981), // Emerald Border
      const Color(0xFF94A3B8), // Muted Slate Border
      const Color(0xFFCBD5E1), // Light Silver Border
      const Color(0xFF374151), // Dark Gray Border
      const Color(0xFFF97316), // Orange Border
      const Color(0xFFA855F7), // Purple Border
    ];

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            void updateFromColor(Color newColor) {
              setDialogState(() {
                currentColor = newColor;
                hsv = HSVColor.fromColor(newColor);
                hexController.text = newColor.value
                    .toRadixString(16)
                    .padLeft(8, '0')
                    .substring(2)
                    .toUpperCase();
              });
            }

            void updateFromHsv(HSVColor newHsv) {
              setDialogState(() {
                hsv = newHsv;
                currentColor = newHsv.toColor();
                hexController.text = currentColor.value
                    .toRadixString(16)
                    .padLeft(8, '0')
                    .substring(2)
                    .toUpperCase();
              });
            }

            void applyHex(String val) {
              String hex = val.trim().replaceAll('#', '');
              if (hex.length == 6) {
                final intVal = int.tryParse('FF$hex', radix: 16);
                if (intVal != null) {
                  updateFromColor(Color(intVal));
                }
              } else if (hex.length == 8) {
                final intVal = int.tryParse(hex, radix: 16);
                if (intVal != null) {
                  updateFromColor(Color(intVal));
                }
              }
            }

            return Dialog(
              backgroundColor: tokens.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(tokens.cardRadius),
                side: BorderSide(color: tokens.borderColor, width: 1.5),
              ),
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: ctx.getTextStyle(
                              fontSize: 18,
                              fontWeight: tokens.headingWeight,
                              color: tokens.textPrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          color: tokens.textSecondary,
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Live Preview Comparison Box
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: tokens.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: tokens.borderColor),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Current',
                                  style: ctx.getTextStyle(
                                    fontSize: 11,
                                    color: tokens.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: initialColor,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.white24),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '#${initialColor.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: initialColor.computeLuminance() > 0.4
                                          ? Colors.black
                                          : Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Icon(Icons.arrow_forward_rounded, size: 20),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Selected (Live)',
                                  style: ctx.getTextStyle(
                                    fontSize: 11,
                                    color: tokens.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: currentColor,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: tokens.primary,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: currentColor.withOpacity(0.35),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '#${currentColor.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: currentColor.computeLuminance() > 0.4
                                          ? Colors.black
                                          : Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 1. Hue Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Hue Spectrum (0° - 360°)',
                          style: ctx.getTextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: tokens.textPrimary,
                          ),
                        ),
                        Text(
                          '${hsv.hue.round()}°',
                          style: ctx.getTextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: tokens.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 14,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: const LinearGradient(
                          colors: [
                            Colors.red,
                            Colors.yellow,
                            Colors.green,
                            Colors.cyan,
                            Colors.blue,
                            Color(0xFFFF00FF), // Magenta
                            Colors.red,
                          ],
                        ),
                      ),
                    ),
                    SliderTheme(
                      data: SliderTheme.of(dialogCtx).copyWith(
                        trackHeight: 2,
                        thumbColor: currentColor,
                        activeTrackColor: Colors.transparent,
                        inactiveTrackColor: Colors.transparent,
                      ),
                      child: Slider(
                        value: hsv.hue,
                        min: 0.0,
                        max: 360.0,
                        onChanged: (val) =>
                            updateFromHsv(hsv.withHue(val)),
                      ),
                    ),

                    // 2. Saturation Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Color Saturation / Vibrancy',
                          style: ctx.getTextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: tokens.textPrimary,
                          ),
                        ),
                        Text(
                          '${(hsv.saturation * 100).round()}%',
                          style: ctx.getTextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: tokens.primary,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: hsv.saturation,
                      min: 0.0,
                      max: 1.0,
                      activeColor: tokens.primary,
                      onChanged: (val) =>
                          updateFromHsv(hsv.withSaturation(val)),
                    ),

                    // 3. Brightness / Value Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Lightness / Darkness',
                          style: ctx.getTextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: tokens.textPrimary,
                          ),
                        ),
                        Text(
                          '${(hsv.value * 100).round()}%',
                          style: ctx.getTextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: tokens.primary,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: hsv.value,
                      min: 0.0,
                      max: 1.0,
                      activeColor: tokens.primary,
                      onChanged: (val) => updateFromHsv(hsv.withValue(val)),
                    ),
                    const SizedBox(height: 8),

                    // 4. Hex Input Row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                          decoration: BoxDecoration(
                            color: tokens.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: tokens.borderColor),
                          ),
                          child: Text(
                            'HEX #',
                            style: ctx.getTextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: tokens.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: hexController,
                            style: ctx.getTextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: tokens.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: 'RRGGBB',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              fillColor: tokens.surface,
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: tokens.borderColor),
                              ),
                            ),
                            onSubmitted: applyHex,
                          ),
                        ),
                        const SizedBox(width: 8),
                        DayFlowButton(
                          label: 'Set',
                          icon: Icons.check,
                          height: 42,
                          onPressed: () => applyHex(hexController.text),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Curated Swatch Grids
                    _buildModalSwatchCategory(
                      ctx,
                      title: '⚡ Vibrant & Neo-Brutal Accents',
                      swatches: vibrantSwatches,
                      current: currentColor,
                      onSelect: updateFromColor,
                    ),
                    const SizedBox(height: 12),
                    _buildModalSwatchCategory(
                      ctx,
                      title: '🖤 Dark & AMOLED Tones',
                      swatches: darkAmoledSwatches,
                      current: currentColor,
                      onSelect: updateFromColor,
                    ),
                    const SizedBox(height: 12),
                    _buildModalSwatchCategory(
                      ctx,
                      title: '🌸 Aesthetic & Soft Pastels',
                      swatches: pastelSoftSwatches,
                      current: currentColor,
                      onSelect: updateFromColor,
                    ),
                    const SizedBox(height: 12),
                    _buildModalSwatchCategory(
                      ctx,
                      title: '🔲 High-Contrast & Border Favorites',
                      swatches: borderAccentSwatches,
                      current: currentColor,
                      onSelect: updateFromColor,
                    ),
                    const SizedBox(height: 20),

                    // Dialog Actions
                    Row(
                      children: [
                        Expanded(
                          child: DayFlowButton(
                            label: 'Cancel',
                            variant: DayFlowButtonVariant.secondary,
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DayFlowButton(
                            label: 'Apply Color',
                            icon: Icons.done_all_rounded,
                            variant: DayFlowButtonVariant.primary,
                            onPressed: () {
                              onSelected(currentColor);
                              Navigator.of(ctx).pop();
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModalSwatchCategory(
    BuildContext ctx, {
    required String title,
    required List<Color> swatches,
    required Color current,
    required ValueChanged<Color> onSelect,
  }) {
    final tokens = ctx.themeTokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: ctx.getTextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: tokens.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: swatches.map((c) {
            final isSel = current.value == c.value;
            return InkWell(
              onTap: () => onSelect(c),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: c,
                  borderRadius: BorderRadius.circular(6),
                  border: isSel
                      ? Border.all(color: tokens.primary, width: 2.5)
                      : Border.all(color: Colors.white24, width: 1),
                ),
                child: isSel
                    ? Icon(
                        Icons.check,
                        size: 14,
                        color: c.computeLuminance() > 0.4
                            ? Colors.black
                            : Colors.white,
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildColorsTab() {
    final tokens = context.themeTokens;
    final primaryPalette = [
      const Color(0xFFFFE600), // Neo Yellow
      const Color(0xFF10B981), // Emerald
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF2563EB), // Blue
      const Color(0xFFE11D48), // Rose
      const Color(0xFFF59E0B), // Amber
      const Color(0xFF8B5CF6), // Violet
      const Color(0xFF00F0FF), // Cyan
    ];

    final borderPalette = [
      const Color(0xFFFFE600), // Electric Yellow
      const Color(0xFF000000), // Solid Black
      const Color(0xFFFFFFFF), // Solid White
      const Color(0xFF6366F1), // Indigo
      const Color(0xFFE11D48), // Rose
      const Color(0xFF10B981), // Emerald
      const Color(0xFF94A3B8), // Slate
      const Color(0xFF334155), // Dark Gray
    ];

    final cardPalette = [
      const Color(0xFF121214), // Obsidian Card
      const Color(0xFF1E293B), // Dark Slate Card
      const Color(0xFFFFFFFF), // Crisp White Card
      const Color(0xFFFBF7EE), // Parchment Card
      const Color(0xFFF5F3EF), // Nordic Oatmeal Card
      const Color(0xFF1A1A24), // Cyber Dark Card
      const Color(0xFFFEFCE8), // Light Butter Card
      const Color(0xFF0A1128), // Deep Navy Card
    ];

    return ListView(
      padding: EdgeInsets.all(tokens.screenPadding),
      children: [
        // 1. Primary Brand Color
        _buildColorPickerSection(
          title: 'Primary Brand Color',
          currentColor: _editableTheme.primary,
          palette: primaryPalette,
          onSelected: (c) {
            final updated = _editableTheme.copyWith(primary: c);
            setState(() => _editableTheme = updated);
            ref.read(themeNotifierProvider.notifier).updateCurrentTheme(updated);
          },
        ),
        const SizedBox(height: 18),

        // 2. Secondary Accent Color
        _buildColorPickerSection(
          title: 'Secondary Accent Color',
          currentColor: _editableTheme.secondary,
          palette: primaryPalette,
          onSelected: (c) {
            final updated = _editableTheme.copyWith(secondary: c);
            setState(() => _editableTheme = updated);
            ref.read(themeNotifierProvider.notifier).updateCurrentTheme(updated);
          },
        ),
        const SizedBox(height: 18),

        // 3. Border & Stroke Color (Requested by user!)
        _buildColorPickerSection(
          title: 'Border & Stroke Color (Customizable)',
          currentColor: _editableTheme.borderColor,
          palette: borderPalette,
          onSelected: (c) {
            final updated = _editableTheme.copyWith(borderColor: c);
            setState(() => _editableTheme = updated);
            ref.read(themeNotifierProvider.notifier).updateCurrentTheme(updated);
          },
        ),
        const SizedBox(height: 18),

        // 4. Card Background Color
        _buildColorPickerSection(
          title: 'Card / Surface Container Color',
          currentColor: _editableTheme.cardColor,
          palette: cardPalette,
          onSelected: (c) {
            final updated = _editableTheme.copyWith(cardColor: c);
            setState(() => _editableTheme = updated);
            ref.read(themeNotifierProvider.notifier).updateCurrentTheme(updated);
          },
        ),
        const SizedBox(height: 18),

        // 5. App Canvas / Background Color
        _buildColorPickerSection(
          title: 'Canvas & Background Mode',
          currentColor: _editableTheme.background,
          palette: const [
            Color(0xFF000000), // AMOLED Black
            Color(0xFF0F172A), // Dark Slate
            Color(0xFF0B0F19), // Midnight
            Color(0xFFF8FAFC), // Crisp Light
            Color(0xFFFBF7EE), // Parchment
            Color(0xFFF5F3EF), // Nordic Oatmeal
            Color(0xFFFDF4F5), // Soft Blush
            Color(0xFFFEFCE8), // Light Yellow
          ],
          onSelected: (bg) {
            final isDark = bg.computeLuminance() < 0.2;
            final isAmoled = bg.value == 0xFF000000;
            final updated = _editableTheme.copyWith(
              background: bg,
              cardColor: isDark
                  ? (isAmoled ? const Color(0xFF121212) : const Color(0xFF1E293B))
                  : Colors.white,
              surface: isDark
                  ? const Color(0xFF0F172A)
                  : const Color(0xFFF1F5F9),
              textPrimary: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
              textSecondary: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              isDark: isDark,
              isAmoled: isAmoled,
            );
            setState(() => _editableTheme = updated);
            ref.read(themeNotifierProvider.notifier).updateCurrentTheme(updated);
          },
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildColorPickerSection({
    required String title,
    required Color currentColor,
    required List<Color> palette,
    required ValueChanged<Color> onSelected,
  }) {
    final tokens = context.themeTokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: context.getTextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: tokens.textPrimary,
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: currentColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: currentColor.withOpacity(0.4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '#${currentColor.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
                  style: context.getTextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: tokens.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Quick Swatches Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: palette.map((c) {
            final isSel = currentColor.value == c.value;
            return InkWell(
              onTap: () => onSelected(c),
              customBorder: const CircleBorder(),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: isSel
                      ? Border.all(color: tokens.primary, width: 3)
                      : Border.all(color: tokens.borderColor, width: 1),
                ),
                child: isSel
                    ? Icon(
                        Icons.check,
                        size: 15,
                        color: c.computeLuminance() > 0.4
                            ? Colors.black
                            : Colors.white,
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),

        // Open Full Spectrum & HEX Palette Picker Button
        DayFlowButton(
          label: 'Custom Spectrum & HEX Picker 🎨',
          icon: Icons.palette_rounded,
          variant: DayFlowButtonVariant.outline,
          height: 34,
          onPressed: () => _openFullColorPickerDialog(
            title: title,
            initialColor: currentColor,
            onSelected: onSelected,
          ),
        ),
      ],
    );
  }

  Widget _buildStyleTab() {
    final tokens = context.themeTokens;

    return ListView(
      padding: EdgeInsets.all(tokens.screenPadding),
      children: [
        // Card Visual Style
        Text(
          'Card Visual Variant',
          style: context.getTextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: tokens.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: CardVisualVariant.values.map((v) {
            final isSel = _editableTheme.cardStyle == v;
            return DayFlowChip(
              label: v.name.toUpperCase(),
              isSelected: isSel,
              onTap: () {
                final updated = _editableTheme.copyWith(cardStyle: v);
                setState(() => _editableTheme = updated);
                ref.read(themeNotifierProvider.notifier).updateCurrentTheme(updated);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 18),

        // Corner Radius Slider
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Corner Radius',
              style: context.getTextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: tokens.textPrimary,
              ),
            ),
            Text(
              '${_editableTheme.cardRadius.round()}px',
              style: context.getTextStyle(
                color: tokens.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Slider(
          value: _editableTheme.cardRadius,
          min: 0,
          max: 32,
          divisions: 16,
          activeColor: tokens.primary,
          onChanged: (val) {
            final updated = _editableTheme.copyWith(
              cardRadius: val,
              buttonRadius: val * 0.8,
            );
            setState(() => _editableTheme = updated);
            ref.read(themeNotifierProvider.notifier).updateCurrentTheme(updated);
          },
        ),
        const SizedBox(height: 14),

        // Border Thickness Slider
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Border Thickness',
              style: context.getTextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: tokens.textPrimary,
              ),
            ),
            Text(
              '${_editableTheme.borderWidth.toStringAsFixed(1)}px',
              style: context.getTextStyle(
                color: tokens.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Slider(
          value: _editableTheme.borderWidth,
          min: 0.0,
          max: 4.0,
          divisions: 8,
          activeColor: tokens.primary,
          onChanged: (val) {
            final updated = _editableTheme.copyWith(borderWidth: val);
            setState(() => _editableTheme = updated);
            ref.read(themeNotifierProvider.notifier).updateCurrentTheme(updated);
          },
        ),
        const SizedBox(height: 14),

        // Density Selector
        Text(
          'Layout Density',
          style: context.getTextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: tokens.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: ThemeDensity.values.map((d) {
            final isSel = _editableTheme.density == d;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: DayFlowChip(
                  label: d.name.toUpperCase(),
                  isSelected: isSel,
                  onTap: () {
                    final updated = _editableTheme.copyWith(density: d);
                    setState(() => _editableTheme = updated);
                    ref.read(themeNotifierProvider.notifier).updateCurrentTheme(updated);
                  },
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildTypographyTab() {
    final tokens = context.themeTokens;
    final fonts = [
      'Inter',
      'Outfit',
      'Space Grotesk',
      'Playfair Display',
      'JetBrains Mono',
      'Poppins',
      'Merriweather',
      'Roboto',
    ];

    return ListView(
      padding: EdgeInsets.all(tokens.screenPadding),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Font Family (Tap to apply live)',
              style: context.getTextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: tokens.textPrimary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: tokens.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _editableTheme.fontFamily,
                style: context.getTextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: tokens.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...fonts.map((f) {
          final isSel = _editableTheme.fontFamily == f;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(tokens.buttonRadius),
                side: BorderSide(
                  color: isSel ? tokens.primary : tokens.borderColor,
                  width: isSel ? 2 : 1,
                ),
              ),
              tileColor: isSel
                  ? tokens.primary.withOpacity(0.08)
                  : tokens.cardColor,
              title: Text(
                f,
                style: DayFlowThemeContextExtension.getGoogleFontStyle(
                  f,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: tokens.textPrimary,
                ),
              ),
              subtitle: Text(
                'The quick brown fox jumps over the lazy dog',
                style: DayFlowThemeContextExtension.getGoogleFontStyle(
                  f,
                  fontSize: 12,
                  color: tokens.textSecondary,
                ),
              ),
              trailing: isSel
                  ? Icon(Icons.check_circle, color: tokens.primary, size: 22)
                  : null,
              onTap: () {
                final updated = _editableTheme.copyWith(fontFamily: f);
                setState(() => _editableTheme = updated);
                // Immediately apply font across entire app
                ref.read(themeNotifierProvider.notifier).updateCurrentTheme(updated);
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: tokens.cardColor,
                    content: Text(
                      'Font "$f" applied live!',
                      style: DayFlowThemeContextExtension.getGoogleFontStyle(
                        f,
                        color: tokens.textPrimary,
                      ),
                    ),
                    duration: const Duration(milliseconds: 1200),
                  ),
                );
              },
            ),
          );
        }),
        const SizedBox(height: 18),

        // Font Scale Slider
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Font Size Scale',
              style: context.getTextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: tokens.textPrimary,
              ),
            ),
            Text(
              '${(_editableTheme.fontScale * 100).round()}%',
              style: context.getTextStyle(
                color: tokens.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Slider(
          value: _editableTheme.fontScale,
          min: 0.85,
          max: 1.25,
          divisions: 8,
          activeColor: tokens.primary,
          onChanged: (val) {
            final updated = _editableTheme.copyWith(fontScale: val);
            setState(() => _editableTheme = updated);
            ref.read(themeNotifierProvider.notifier).updateCurrentTheme(updated);
          },
        ),
        const SizedBox(height: 30),
      ],
    );
  }
}
