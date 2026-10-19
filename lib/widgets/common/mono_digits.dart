import 'package:flutter/widgets.dart';

import '../../theme/app_typography.dart';

final _number = RegExp(r'[−+\-]?\d[\d.,:–]*\d|[−+\-]?\d');

/// Text whose numbers are set in JetBrains Mono and the words in [style]:
/// the brand sets every figure in the data face, also inside a sentence.
class MonoDigits extends StatelessWidget {
  final String text;
  final TextStyle style;
  final TextStyle? numberStyle;
  final int? maxLines;
  final TextAlign? textAlign;

  const MonoDigits(
    this.text, {
    super.key,
    required this.style,
    this.numberStyle,
    this.maxLines,
    this.textAlign,
  });

  static List<InlineSpan> spans(
    String text,
    TextStyle style, [
    TextStyle? numberStyle,
  ]) {
    final mono =
        numberStyle ??
        AppTypography.number(
          size: style.fontSize ?? 17,
          color: style.color,
          weight:
              style.fontWeight == FontWeight.w400 || style.fontWeight == null
              ? FontWeight.w500
              : style.fontWeight!,
        );
    final out = <InlineSpan>[];
    var last = 0;
    for (final m in _number.allMatches(text)) {
      if (m.start > last) {
        out.add(TextSpan(text: text.substring(last, m.start)));
      }
      out.add(TextSpan(text: m.group(0), style: mono));
      last = m.end;
    }
    if (last < text.length) out.add(TextSpan(text: text.substring(last)));
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(children: spans(text, style, numberStyle)),
      style: style,
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
      textAlign: textAlign,
    );
  }
}
