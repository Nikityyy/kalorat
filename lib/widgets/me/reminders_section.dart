import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_colors.dart';
import '../../extensions/l10n_extension.dart';

class RemindersSection extends StatelessWidget {
  const RemindersSection({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user = provider.user;
    final l10n = context.l10n;

    if (user == null) return const SizedBox.shrink();

    return Column(
      children: [
        SwitchListTile(
          title: Text(
            l10n.mealReminders,
            style: const TextStyle(color: AppColors.slate),
          ),
          value: user.mealRemindersEnabled,
          activeThumbColor: AppColors.primary,
          onChanged: (v) => provider.updateUser(mealRemindersEnabled: v),
        ),
        SwitchListTile(
          title: Text(
            l10n.weightReminders,
            style: const TextStyle(color: AppColors.slate),
          ),
          value: user.weightRemindersEnabled,
          activeThumbColor: AppColors.primary,
          onChanged: (v) => provider.updateUser(weightRemindersEnabled: v),
        ),
      ],
    );
  }
}
