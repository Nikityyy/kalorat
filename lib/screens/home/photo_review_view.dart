import 'package:flutter/material.dart';
import '../../extensions/l10n_extension.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_typography.dart';
import '../../widgets/inputs/action_button.dart';

/// The taken photos in a grid, with the choices to discard, add more or start
/// the analysis.
class PhotoReviewView extends StatelessWidget {
  final List<String> photos;
  final bool isAnalyzing;
  final ImageProvider Function(String photo) imageFor;
  final void Function(int index) onOpen;
  final Future<void> Function(int index) onRemove;
  final VoidCallback onDiscard;
  final VoidCallback onAddPhoto;
  final VoidCallback onAnalyze;

  const PhotoReviewView({
    super.key,
    required this.photos,
    required this.isAnalyzing,
    required this.imageFor,
    required this.onOpen,
    required this.onRemove,
    required this.onDiscard,
    required this.onAddPhoto,
    required this.onAnalyze,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      color: AppColors.glacialWhite,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Text(
            l10n.reviewPhotos,
            style: AppTypography.displayMedium.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: photos.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    Positioned.fill(
                      child: GestureDetector(
                        onTap: () => onOpen(index),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              AppTheme.borderRadius,
                            ),
                            border: Border.all(
                              color: AppColors.borderGrey,
                              width: 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              AppTheme.borderRadius,
                            ),
                            child: Image(
                              image: imageFor(photos[index]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Semantics(
                        button: true,
                        label: context.l10n.delete,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () async {
                            await onRemove(index);
                          },
                          child: Container(
                            // 16px icon in a 44px touch target
                            padding: const EdgeInsets.all(14),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.glacialWhite,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppTheme.borderRadius),
              ),
              border: Border(
                top: BorderSide(color: AppColors.borderGrey, width: 1),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onDiscard,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppColors.pebble),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppTheme.borderRadius,
                              ),
                            ),
                          ),
                          child: Text(
                            l10n.discard,
                            style: TextStyle(color: AppColors.slate),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onAddPhoto,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: AppColors.styrianForest,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppTheme.borderRadius,
                              ),
                            ),
                          ),
                          child: Text(
                            l10n.addPhoto,
                            style: TextStyle(
                              color: AppColors.styrianForest,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ActionButton(
                    text: l10n.startAnalysis,
                    isLoading: isAnalyzing,
                    onPressed: onAnalyze,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
