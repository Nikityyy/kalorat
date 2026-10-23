import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// How the card for a story looks.
enum ShareCardStyle {
  /// The photo fills the card, the numbers lie over its lower part.
  photo,

  /// The photo above, the numbers under it on a light page.
  light,

  /// The photo above, the numbers under it on a dark page.
  dark,
}

/// What the card says about a meal; the amounts are what was eaten.
class ShareCardData {
  final String name;
  final double calories;
  final double protein;
  final double carbs;
  final double fats;
  final String language;

  /// The localized words on the card.
  final String kcalLabel;
  final String proteinLabel;
  final String carbsLabel;
  final String fatsLabel;

  const ShareCardData({
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.language,
    required this.kcalLabel,
    required this.proteinLabel,
    required this.carbsLabel,
    required this.fatsLabel,
  });

  /// A whole number from 10 up, one decimal below, in the language's style.
  String amount(double value) =>
      NumberFormat(value >= 10 ? '0' : '0.#', language).format(value);

  String get caloriesText => NumberFormat('0', language).format(calories);
}

/// A meal as a picture for stories: 9:16, drawn at [size] and meant to be
/// captured at 3x (1080 x 1920). Only the name, four numbers and the
/// wordmark, small and centered at the bottom, above Instagram's reply bar.
/// The calories are the one number that leads, the macros stay quiet. The
/// colors are the card's own, so it looks the same in either app theme.
class MealShareCard extends StatelessWidget {
  static const size = Size(360, 640);

  /// Stays clear of the story's reply bar.
  static const _bottomSafe = 92.0;
  static const _side = 32.0;

  final ShareCardData data;
  final ShareCardStyle style;

  /// The wordmark [style] shows. A picture of the card is only complete once
  /// this is decoded, so the share screen decodes it first.
  static ImageProvider wordmarkFor(ShareCardStyle style) =>
      _CardInk.of(style).wordmarkImage;

  /// Null for a meal without a photo: the card gets a plain forest cover.
  final ImageProvider? photo;

  const MealShareCard({
    super.key,
    required this.data,
    required this.style,
    this.photo,
  });

  @override
  Widget build(BuildContext context) {
    // The card is a picture: it must not follow the user's text size.
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(textScaler: TextScaler.noScaling),
      child: SizedBox.fromSize(
        size: size,
        child: DefaultTextStyle(
          style: const TextStyle(decoration: TextDecoration.none),
          child: style == ShareCardStyle.photo
              ? _buildPhoto()
              : _buildSplit(_CardInk.of(style)),
        ),
      ),
    );
  }

  Widget _cover() => photo == null
      ? _ForestCover(name: data.name)
      : Image(
          image: photo!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, _, _) => _ForestCover(name: data.name),
        );

  Widget _buildPhoto() {
    return Stack(
      fit: StackFit.expand,
      children: [
        _cover(),
        // Only the lower part darkens, under the numbers, smoothly.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0, 0.5, 0.74, 1],
              colors: [
                Color(0x00000000),
                Color(0x00000000),
                Color(0x8C000000),
                Color(0xD6000000),
              ],
            ),
          ),
        ),
        Positioned(
          left: _side,
          right: _side,
          bottom: _bottomSafe,
          child: _Details(data: data, ink: _CardInk.onPhoto),
        ),
      ],
    );
  }

  Widget _buildSplit(_CardInk ink) {
    return ColoredBox(
      color: ink.page,
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(28),
              ),
              child: SizedBox.expand(child: _cover()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(_side, 28, _side, _bottomSafe),
            child: _Details(data: data, ink: ink),
          ),
        ],
      ),
    );
  }
}

/// The colors of the text on the card.
class _CardInk {
  final Color page;
  final Color text;
  final Color muted;
  final Color rule;

  /// 'assets/...' wordmark, tinted [wordmarkTint] when it has one.
  final String wordmark;
  final Color? wordmarkTint;

  const _CardInk({
    required this.page,
    required this.text,
    required this.muted,
    required this.rule,
    required this.wordmark,
    this.wordmarkTint,
  });

  /// Drawn at 10 logical px high: 96 px is plenty at 3x and keeps the 6000 px
  /// wide file from being decoded in full.
  ImageProvider get wordmarkImage =>
      ResizeImage(AssetImage(wordmark), height: 96);

  static _CardInk of(ShareCardStyle style) => switch (style) {
    ShareCardStyle.photo => onPhoto,
    ShareCardStyle.light => light,
    ShareCardStyle.dark => dark,
  };

  static const onPhoto = _CardInk(
    page: Colors.transparent,
    text: Colors.white,
    muted: Color(0xDBFFFFFF),
    rule: Color(0x47FFFFFF),
    wordmark: 'assets/kalorat-textlogo.webp',
    wordmarkTint: Colors.white,
  );

  static const light = _CardInk(
    page: AppColors.pureWhite,
    text: AppColors.deepSpaceBlack,
    muted: Color(0xFF687069),
    rule: AppColors.subtleAsh,
    wordmark: 'assets/kalorat-textlogo.webp',
  );

  static const dark = _CardInk(
    page: AppColors.deepSpaceBlack,
    text: AppColors.darkText,
    muted: Color(0xFF8E948F),
    rule: AppColors.darkChrome,
    wordmark: 'assets/kalorat-textlogo-dark.webp',
  );
}

/// The name, then calories (the one number that leads) and the three
/// macros in one quiet row, then the wordmark; all centered. Close together
/// inside the group, a longer rest before the wordmark.
class _Details extends StatelessWidget {
  final ShareCardData data;
  final _CardInk ink;

  const _Details({required this.data, required this.ink});

  @override
  Widget build(BuildContext context) {
    final stats = [
      (data.caloriesText, data.kcalLabel, true),
      (data.amount(data.protein), data.proteinLabel, false),
      (data.amount(data.carbs), data.carbsLabel, false),
      (data.amount(data.fats), data.fatsLabel, false),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          data.name,
          maxLines: 2,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: AppTypography.outfit,
            fontSize: 19,
            fontWeight: FontWeight.w600,
            color: ink.text,
            letterSpacing: -0.35,
            height: 1.15,
            decoration: TextDecoration.none,
          ),
        ),
        const SizedBox(height: 14),
        // Long numbers or words shrink the row a little instead of
        // overflowing.
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < stats.length; i++) ...[
                if (i > 0)
                  Container(
                    width: 1,
                    height: 26,
                    margin: const EdgeInsets.symmetric(horizontal: 13),
                    color: ink.rule,
                  ),
                _Stat(
                  value: stats[i].$1,
                  label: stats[i].$2,
                  lead: stats[i].$3,
                  ink: ink,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 26),
        Image(
          image: ink.wordmarkImage,
          height: 10,
          color: ink.wordmarkTint,
          colorBlendMode: BlendMode.srcIn,
          filterQuality: FilterQuality.high,
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;

  /// The number that leads: larger and bolder, in the text color.
  final bool lead;
  final _CardInk ink;

  const _Stat({
    required this.value,
    required this.label,
    required this.lead,
    required this.ink,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text.rich(
          TextSpan(
            text: value,
            style: TextStyle(
              fontFamily: AppTypography.mono,
              fontSize: lead ? 23 : 14,
              fontWeight: lead ? FontWeight.w700 : FontWeight.w500,
              color: lead ? ink.text : ink.text.withValues(alpha: 0.92),
              letterSpacing: lead ? -0.8 : 0,
              height: 1.05,
              decoration: TextDecoration.none,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            children: [
              // Grams in a quiet unit; the calories have their label below.
              if (!lead) ...[
                const WidgetSpan(child: SizedBox(width: 2)),
                TextSpan(
                  text: 'g',
                  style: TextStyle(
                    fontFamily: AppTypography.mono,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w400,
                    color: ink.muted,
                  ),
                ),
              ],
            ],
          ),
          maxLines: 1,
        ),
        SizedBox(height: lead ? 5 : 4),
        Text(
          label,
          maxLines: 1,
          style: TextStyle(
            fontFamily: AppTypography.outfit,
            fontSize: 9.5,
            fontWeight: FontWeight.w400,
            color: ink.muted,
            letterSpacing: 0.3,
            height: 1.1,
            decoration: TextDecoration.none,
          ),
        ),
      ],
    );
  }
}

/// The cover of a meal without a photo: forest green with the first letter
/// of its name, large and faint.
class _ForestCover extends StatelessWidget {
  final String name;

  const _ForestCover({required this.name});

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF14704A), Color(0xFF0A3B26)],
        ),
      ),
      child: Align(
        alignment: const Alignment(0, -0.35),
        child: trimmed.isEmpty
            ? null
            : Text(
                trimmed.characters.first.toUpperCase(),
                style: const TextStyle(
                  fontFamily: AppTypography.outfit,
                  fontSize: 200,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  color: Color(0x1FFFFFFF),
                  decoration: TextDecoration.none,
                ),
              ),
      ),
    );
  }
}
