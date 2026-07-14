import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/common/primary_button.dart';

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

class _ContractStepState extends State<ContractStep> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  bool _signed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
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
    _controller.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          widget.onNext();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDe = widget.language == 'de';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
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
                  border: Border.all(color: AppColors.slate.withValues(alpha: 0.15), width: 1),
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
                              child: _signed
                                  ? AnimatedBuilder(
                                      animation: _opacity,
                                      builder: (context, child) {
                                        return Align(
                                          alignment: Alignment.centerLeft,
                                          child: ClipRect(
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              widthFactor: _opacity.value,
                                              child: SizedBox(
                                                width: 220,
                                                child: child,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.only(bottom: 4.0),
                                        child: Text(
                                          widget.name.isEmpty ? (isDe ? 'Ich' : 'Me') : widget.name,
                                          style: GoogleFonts.caveat(
                                            fontSize: 42,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                            height: 1.0,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.visible,
                                        ),
                                      ),
                                    )
                                  : Opacity(
                                      opacity: 0.0,
                                      child: Text(
                                        widget.name.isEmpty ? (isDe ? 'Ich' : 'Me') : widget.name,
                                        style: GoogleFonts.caveat(
                                          fontSize: 42,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                          height: 1.0,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.visible,
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
            PrimaryButton(
              text: isDe ? 'Ich verpflichte mich' : 'Commit to my goal',
              onPressed: _signContract,
            ),
          if (_signed)
            const SizedBox(height: 56), // Placeholder for button height
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
