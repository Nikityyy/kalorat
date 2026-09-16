import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/inputs/action_button.dart';

class ContractStep extends StatefulWidget {
  final String language;
  final String name;
  final VoidCallback onNext;

  const ContractStep({
    super.key,
    required this.language,
    required this.name,
    required this.onNext,
  });

  @override
  State<ContractStep> createState() => _ContractStepState();
}

class _ContractStepState extends State<ContractStep>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _revealProgress;
  late Animation<double> _opacity;
  bool _signed = false;

  @override
  void initState() {
    super.initState();
    final nameText = widget.name.isEmpty
        ? (widget.language == 'de' ? 'Ich' : 'Me')
        : widget.name;
    final charCount = nameText.runes.length.clamp(1, 32);
    // A signature should feel handwritten, not like a loading screen. Keep a
    // short base stroke and add only a small amount for longer names.
    final durationMs = (680 + (charCount * 90)).clamp(850, 2200).toInt();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: durationMs),
    );
    _revealProgress = CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);

    // Start immediately; waiting here used to add up to 1.5 seconds before
    // the animation even began on a cold web font cache.
    GoogleFonts.pendingFonts([
      GoogleFonts.caveat(fontSize: 42, fontWeight: FontWeight.bold),
    ]);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _signContract() {
    setState(() {
      _signed = true;
    });
    _controller.forward(from: 0).then((_) {
      Future.delayed(const Duration(milliseconds: 360), () {
        if (mounted) widget.onNext();
      });
    });
  }

  Widget _signatureText(bool isDe) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: Text(
          widget.name.isEmpty ? (isDe ? 'Ich' : 'Me') : widget.name,
          style: GoogleFonts.caveat(
            fontSize: 42,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
            height: 1.0,
          ),
          maxLines: 1,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDe = widget.language == 'de';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          const Icon(Icons.gavel, size: 48, color: AppColors.primary),
          const SizedBox(height: 24),
          Text(
            isDe ? 'Der Vertrag' : 'The Contract',
            style: AppTypography.displayMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.glacialWhite,
                  border: Border.all(
                    color: AppColors.slate.withValues(alpha: 0.15),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.slate.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      isDe
                          ? 'Hiermit verpflichte ich mich, meine Nahrungsaufnahme jeden Tag zu verfolgen, egal was passiert.\n\nIch werde keine Ausreden zulassen.'
                          : 'I hereby commit to tracking my intake today, no matter what.\n\nI will not let excuses get in the way of my progress.',
                      style: const TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 15,
                        height: 1.6,
                        color: AppColors.slate,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    Align(
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: 220,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 220,
                              height: 50,
                              child: Center(
                                child: _signed
                                    ? AnimatedBuilder(
                                        animation: _controller,
                                        builder: (context, child) {
                                          return Opacity(
                                            opacity: _opacity.value,
                                            child: ClipRect(
                                              clipper: _SignatureClipper(
                                                _revealProgress.value,
                                              ),
                                              child: child,
                                            ),
                                          );
                                        },
                                        child: _signatureText(isDe),
                                      )
                                    : Opacity(
                                        opacity: 0.0,
                                        child: _signatureText(isDe),
                                      ),
                              ),
                            ),
                            Container(
                              width: 220,
                              height: 1.5,
                              color: AppColors.slate.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isDe ? 'UNTERSCHRIFT' : 'SIGNATURE',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'JetBrains Mono',
                                fontSize: 11,
                                color: AppColors.slate.withValues(alpha: 0.5),
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Spacer(),
          if (!_signed)
            ActionButton(
              text: isDe ? 'Ich verpflichte mich' : 'Commit to my goal',
              onPressed: _signContract,
            ),
          if (_signed) const SizedBox(height: 64),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SignatureClipper extends CustomClipper<Rect> {
  final double progress;

  _SignatureClipper(this.progress);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, -20, size.width * progress, size.height + 40);
  }

  @override
  bool shouldReclip(_SignatureClipper oldClipper) =>
      oldClipper.progress != progress;
}
