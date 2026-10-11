import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/dayflow_theme_context.dart';
import '../../core/theme/dayflow_theme_tokens.dart';

class DayFlowCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? borderRadius;
  final double? borderWidth;
  final CardVisualVariant? variantOverride;
  final bool clipContent;
  final bool enable3DTilt;

  const DayFlowCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius,
    this.borderWidth,
    this.variantOverride,
    this.clipContent = true,
    this.enable3DTilt = false,
  });

  @override
  State<DayFlowCard> createState() => _DayFlowCardState();
}

class _DayFlowCardState extends State<DayFlowCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _tiltController;
  late Animation<double> _tiltX;
  late Animation<double> _tiltY;
  double _currentX = 0.0;
  double _currentY = 0.0;

  @override
  void initState() {
    super.initState();
    _tiltController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _tiltX = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _tiltController, curve: Curves.easeOutCubic),
    );
    _tiltY = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _tiltController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _tiltController.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details, Size size) {
    if (!widget.enable3DTilt) return;
    final halfW = size.width / 2;
    final halfH = size.height / 2;
    final dx = (details.localPosition.dx - halfW) / halfW;
    final dy = (details.localPosition.dy - halfH) / halfH;
    setState(() {
      _currentX = (-dy * 0.06).clamp(-0.08, 0.08);
      _currentY = (dx * 0.06).clamp(-0.08, 0.08);
    });
  }

  void _onPanEnd() {
    if (!widget.enable3DTilt) return;
    _tiltX = Tween<double>(begin: _currentX, end: 0).animate(
      CurvedAnimation(parent: _tiltController, curve: Curves.easeOutCubic),
    );
    _tiltY = Tween<double>(begin: _currentY, end: 0).animate(
      CurvedAnimation(parent: _tiltController, curve: Curves.easeOutCubic),
    );
    _tiltController.forward(from: 0).then((_) {
      if (mounted) {
        setState(() {
          _currentX = 0;
          _currentY = 0;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.themeTokens;
    final variant = widget.variantOverride ?? tokens.cardStyle;
    final radius = widget.borderRadius ?? tokens.cardRadius;
    final effectivePadding = widget.padding ?? EdgeInsets.all(tokens.cardPadding);
    final effectiveBorderWidth = widget.borderWidth ?? tokens.borderWidth;
    final effectiveBorderColor = widget.borderColor ?? tokens.borderColor;

    final roundedBorder = BorderRadius.circular(radius);

    Widget cardBody;

    // 1. Neo-Brutalist Design System (2.5px solid border, hard offset shadow)
    if (variant == CardVisualVariant.brutalist || tokens.isBrutalist) {
      cardBody = Container(
        margin: widget.margin,
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? tokens.cardColor,
          borderRadius: roundedBorder,
          border: Border.all(
            color: tokens.borderColor,
            width: tokens.borderWidth > 1.5 ? tokens.borderWidth : 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: tokens.shadowColor,
              offset: tokens.brutalistShadowOffset,
              blurRadius: 0,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: roundedBorder,
          child: InkWell(
            borderRadius: roundedBorder,
            onTap: widget.onTap,
            child: Padding(
              padding: effectivePadding,
              child: widget.child,
            ),
          ),
        ),
      );
    }
    // 2. Glass Atelier Design System (Frosted translucent backdrop blur)
    else if (variant == CardVisualVariant.glass || tokens.isGlass) {
      cardBody = Container(
        margin: widget.margin,
        child: ClipRRect(
          borderRadius: roundedBorder,
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: tokens.glassBlur,
              sigmaY: tokens.glassBlur,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: (widget.backgroundColor ?? tokens.cardColor).withOpacity(
                  tokens.glassOpacity,
                ),
                borderRadius: roundedBorder,
                border: Border.all(
                  color: effectiveBorderColor.opacity > 0.5
                      ? effectiveBorderColor.withOpacity(0.35)
                      : effectiveBorderColor,
                  width: effectiveBorderWidth,
                ),
                boxShadow: tokens.shadowBlurRadius > 0
                    ? [
                        BoxShadow(
                          color: tokens.shadowColor,
                          blurRadius: tokens.shadowBlurRadius,
                          offset: tokens.shadowOffset,
                        )
                      ]
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: roundedBorder,
                  onTap: widget.onTap,
                  child: Padding(
                    padding: effectivePadding,
                    child: widget.child,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    // 3. Futuristic Spatial Design System (Dimensional specular glow border)
    else if (variant == CardVisualVariant.spatial || tokens.isSpatial) {
      cardBody = Container(
        margin: widget.margin,
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? tokens.cardColor,
          borderRadius: roundedBorder,
          border: Border.all(
            color: tokens.primary.withOpacity(0.4),
            width: effectiveBorderWidth,
          ),
          boxShadow: [
            BoxShadow(
              color: tokens.primary.withOpacity(0.18),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: roundedBorder,
          child: InkWell(
            borderRadius: roundedBorder,
            onTap: widget.onTap,
            child: Padding(
              padding: effectivePadding,
              child: widget.child,
            ),
          ),
        ),
      );
    }
    // 4. Paper Journal Design System (Warm notebook surface with subtle ruled border)
    else if (variant == CardVisualVariant.paper || tokens.isPaperJournal) {
      cardBody = Container(
        margin: widget.margin,
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? tokens.cardColor,
          borderRadius: roundedBorder,
          border: Border.all(
            color: effectiveBorderColor,
            width: effectiveBorderWidth,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0x12000000),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: roundedBorder,
          child: Stack(
            children: [
              // Subtle notebook left margin line
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 3.5,
                  color: tokens.primary.withOpacity(0.35),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: roundedBorder,
                  onTap: widget.onTap,
                  child: Padding(
                    padding: effectivePadding,
                    child: widget.child,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    // 5. Standard / Swiss Minimal / Nordic / Soft Neo / Vector Studio
    else {
      List<BoxShadow>? shadows;
      if (tokens.shadowBlurRadius > 0) {
        shadows = [
          BoxShadow(
            color: tokens.shadowColor,
            blurRadius: tokens.shadowBlurRadius,
            offset: tokens.shadowOffset,
          ),
        ];
      }

      Border? border;
      if (effectiveBorderWidth > 0) {
        border = Border.all(
          color: effectiveBorderColor,
          width: effectiveBorderWidth,
        );
      }

      cardBody = Container(
        margin: widget.margin,
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? tokens.cardColor,
          borderRadius: roundedBorder,
          border: border,
          boxShadow: shadows,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: roundedBorder,
          clipBehavior: widget.clipContent ? Clip.antiAlias : Clip.none,
          child: InkWell(
            borderRadius: roundedBorder,
            onTap: widget.onTap,
            child: Padding(
              padding: effectivePadding,
              child: widget.child,
            ),
          ),
        ),
      );
    }

    if (!widget.enable3DTilt && !tokens.isSpatial) {
      return cardBody;
    }

    // 3D Perspective Tilt wrapper
    return AnimatedBuilder(
      animation: _tiltController,
      builder: (context, child) {
        final rotX = _tiltController.isAnimating ? _tiltX.value : _currentX;
        final rotY = _tiltController.isAnimating ? _tiltY.value : _currentY;
        return GestureDetector(
          onPanUpdate: (d) => _onPanUpdate(d, MediaQuery.of(context).size),
          onPanEnd: (_) => _onPanEnd(),
          onPanCancel: () => _onPanEnd(),
          child: Transform(
            alignment: FractionalOffset.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateX(rotX)
              ..rotateY(rotY),
            child: cardBody,
          ),
        );
      },
    );
  }
}
