import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/gemini_service.dart';
import '../theme/app_colors.dart';

class LiveThoughtPanel extends StatefulWidget {
  final String thoughtText;
  final String titleLabel;
  final String thinkingLabel;

  const LiveThoughtPanel({
    super.key,
    required this.thoughtText,
    required this.titleLabel,
    required this.thinkingLabel,
  });

  @override
  State<LiveThoughtPanel> createState() => _LiveThoughtPanelState();
}

class _LiveThoughtPanelState extends State<LiveThoughtPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _cursorController;
  late final Animation<double> _cursorOpacity;
  final ScrollController _thoughtScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _cursorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 680),
    )..repeat(reverse: true);
    _cursorOpacity = CurvedAnimation(
      parent: _cursorController,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _thoughtScrollController.dispose();
    _cursorController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant LiveThoughtPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.thoughtText != widget.thoughtText) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_thoughtScrollController.hasClients) return;
        _thoughtScrollController.animateTo(
          _thoughtScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasText = widget.thoughtText.trim().isNotEmpty;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 460),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 18),
            child: child,
          ),
        );
      },
      child: AnimatedSize(
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.offWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.subtleAsh, width: 1),
          ),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PanelHeader(title: widget.titleLabel),
              const SizedBox(height: 14),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: hasText
                    ? ConstrainedBox(
                        key: const ValueKey('thought-text'),
                        constraints: const BoxConstraints(maxHeight: 260),
                        child: SingleChildScrollView(
                          controller: _thoughtScrollController,
                          physics: const BouncingScrollPhysics(),
                          child: _MarkdownThoughtText(
                            markdown: widget.thoughtText,
                            cursorOpacity: _cursorOpacity,
                          ),
                        ),
                      )
                    : _ThinkingPlaceholder(
                        key: const ValueKey('placeholder'),
                        label: widget.thinkingLabel,
                        cursorOpacity: _cursorOpacity,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FluidAnalysisRail extends StatefulWidget {
  const FluidAnalysisRail({super.key});

  @override
  State<FluidAnalysisRail> createState() => _FluidAnalysisRailState();
}

class _FluidAnalysisRailState extends State<FluidAnalysisRail>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1450),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 168,
      height: 12,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final value = Curves.easeInOutCubic.transform(_controller.value);
          final alignment = Alignment(-1 + (value * 2), 0);

          return Container(
            decoration: BoxDecoration(
              color: AppColors.offWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.subtleAsh, width: 1),
            ),
            padding: const EdgeInsets.all(3),
            child: Align(
              alignment: alignment,
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.styrianForest,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class AnalysisPhaseIndicator extends StatelessWidget {
  final AnalysisPhase phase;
  final String draftingLabel;
  final String verifyingLabel;

  const AnalysisPhaseIndicator({
    super.key,
    required this.phase,
    required this.draftingLabel,
    required this.verifyingLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isVerifying = phase == AnalysisPhase.verifying;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.subtleAsh, width: 1),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _PhaseCell(
              label: draftingLabel,
              index: '01',
              isActive: !isVerifying,
              isComplete: isVerifying,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _PhaseCell(
              label: verifyingLabel,
              index: '02',
              isActive: isVerifying,
              isComplete: false,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhaseCell extends StatelessWidget {
  final String label;
  final String index;
  final bool isActive;
  final bool isComplete;

  const _PhaseCell({
    required this.label,
    required this.index,
    required this.isActive,
    required this.isComplete,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = isActive
        ? AppColors.pureWhite
        : AppColors.deepSpaceBlack.withValues(alpha: isComplete ? 0.78 : 0.46);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      height: 44,
      decoration: BoxDecoration(
        color: isActive ? AppColors.styrianForest : AppColors.offWhite,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Text(
            index,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: foreground,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: foreground,
                height: 1.1,
                letterSpacing: 0,
              ),
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
          if (isComplete)
            Icon(Icons.check, size: 15, color: foreground)
          else if (isActive)
            const _ActivePhasePulse(),
        ],
      ),
    );
  }
}

class _ActivePhasePulse extends StatefulWidget {
  const _ActivePhasePulse();

  @override
  State<_ActivePhasePulse> createState() => _ActivePhasePulseState();
}

class _ActivePhasePulseState extends State<_ActivePhasePulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final activeDot = (_controller.value * 3).floor().clamp(0, 2);

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final isActive = index == activeDot;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: EdgeInsets.only(left: index == 0 ? 0 : 3),
              width: isActive ? 8 : 5,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.pureWhite.withValues(
                  alpha: isActive ? 1 : 0.5,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        );
      },
    );
  }
}

class _PanelHeader extends StatelessWidget {
  final String title;

  const _PanelHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.styrianForest,
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Icon(Icons.auto_awesome, size: 12, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Text(
          title.toUpperCase(),
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.styrianForest,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _ThinkingPlaceholder extends StatelessWidget {
  final String label;
  final Animation<double> cursorOpacity;

  const _ThinkingPlaceholder({
    super.key,
    required this.label,
    required this.cursorOpacity,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.deepSpaceBlack.withValues(alpha: 0.58),
            height: 1.5,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(width: 6),
        _Cursor(opacity: cursorOpacity),
      ],
    );
  }
}

class _MarkdownThoughtText extends StatelessWidget {
  final String markdown;
  final Animation<double> cursorOpacity;

  const _MarkdownThoughtText({
    required this.markdown,
    required this.cursorOpacity,
  });

  @override
  Widget build(BuildContext context) {
    final blocks = _buildBlocks(markdown);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...blocks,
        const SizedBox(height: 2),
        _Cursor(opacity: cursorOpacity),
      ],
    );
  }

  List<Widget> _buildBlocks(String source) {
    final normalized = source.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final lines = normalized.split('\n');
    final widgets = <Widget>[];
    final paragraph = StringBuffer();

    void flushParagraph() {
      final text = paragraph.toString().trim();
      if (text.isEmpty) return;
      widgets.add(_MarkdownParagraph(text: text));
      paragraph.clear();
    }

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) {
        flushParagraph();
        continue;
      }

      final headingMatch = RegExp(r'^(#{1,3})\s+(.+)$').firstMatch(line);
      final bulletMatch = RegExp(r'^[-*]\s+(.+)$').firstMatch(line);

      if (headingMatch != null) {
        flushParagraph();
        widgets.add(_MarkdownHeading(text: headingMatch.group(2)!.trim()));
      } else if (bulletMatch != null) {
        flushParagraph();
        widgets.add(_MarkdownBullet(text: bulletMatch.group(1)!.trim()));
      } else {
        if (paragraph.isNotEmpty) paragraph.write(' ');
        paragraph.write(line);
      }
    }

    flushParagraph();
    if (widgets.isEmpty) {
      widgets.add(_MarkdownParagraph(text: source.trim()));
    }

    return widgets;
  }
}

class _MarkdownHeading extends StatelessWidget {
  final String text;

  const _MarkdownHeading({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          children: _inlineSpans(text, _headingStyle),
          style: _headingStyle,
        ),
      ),
    );
  }
}

class _MarkdownParagraph extends StatelessWidget {
  final String text;

  const _MarkdownParagraph({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: RichText(
        text: TextSpan(
          children: _inlineSpans(text, _bodyStyle),
          style: _bodyStyle,
        ),
      ),
    );
  }
}

class _MarkdownBullet extends StatelessWidget {
  final String text;

  const _MarkdownBullet({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 5,
            height: 5,
            margin: const EdgeInsets.only(top: 8, right: 10),
            decoration: BoxDecoration(
              color: AppColors.styrianForest,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: _inlineSpans(text, _bodyStyle),
                style: _bodyStyle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Cursor extends StatelessWidget {
  final Animation<double> opacity;

  const _Cursor({required this.opacity});

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: opacity,
      child: Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(
          color: AppColors.styrianForest,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}

final TextStyle _bodyStyle = GoogleFonts.outfit(
  fontSize: 14,
  fontWeight: FontWeight.w400,
  color: AppColors.deepSpaceBlack.withValues(alpha: 0.74),
  height: 1.55,
  letterSpacing: 0,
);

final TextStyle _headingStyle = GoogleFonts.outfit(
  fontSize: 15,
  fontWeight: FontWeight.w700,
  color: AppColors.deepSpaceBlack,
  height: 1.35,
  letterSpacing: 0,
);

List<InlineSpan> _inlineSpans(String source, TextStyle baseStyle) {
  final spans = <InlineSpan>[];
  final pattern = RegExp(r'(\*\*[^*]+\*\*|__[^_]+__|\*[^*]+\*)');
  int currentIndex = 0;

  for (final match in pattern.allMatches(source)) {
    if (match.start > currentIndex) {
      spans.add(TextSpan(text: source.substring(currentIndex, match.start)));
    }

    final token = match.group(0)!;
    final isBold = token.startsWith('**') || token.startsWith('__');
    final trim = isBold ? 2 : 1;
    final inner = token.substring(trim, token.length - trim);

    spans.add(
      TextSpan(
        text: inner,
        style: baseStyle.copyWith(
          fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          fontStyle: isBold ? FontStyle.normal : FontStyle.italic,
          color: isBold
              ? AppColors.deepSpaceBlack
              : AppColors.deepSpaceBlack.withValues(alpha: 0.7),
        ),
      ),
    );
    currentIndex = match.end;
  }

  if (currentIndex < source.length) {
    spans.add(TextSpan(text: source.substring(currentIndex)));
  }

  return spans;
}
