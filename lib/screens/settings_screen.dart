import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../extensions/l10n_extension.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/primary_button.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _nameController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _apiKeyController;
  DateTime? _selectedBirthdate;

  @override
  void initState() {
    super.initState();
    final user = context.read<AppProvider>().user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _heightController = TextEditingController(
      text: user?.height.toString() ?? '',
    );
    _weightController = TextEditingController(
      text: user?.weight.toString() ?? '',
    );
    _apiKeyController = TextEditingController(text: user?.geminiApiKey ?? '');
    _selectedBirthdate = user?.birthdate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user = provider.user;
    final l10n = context.l10n;

    if (user == null)
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );

    return Scaffold(
      backgroundColor: AppColors.limestone,
      appBar: AppBar(
        title: Text(
          l10n.settings,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSection(l10n.profile, [
            _buildTextField(l10n.name, _nameController),
            _buildTextField(
              l10n.heightCm,
              _heightController,
              keyboardType: TextInputType.number,
            ),
            _buildTextField(
              l10n.weightKg,
              _weightController,
              keyboardType: TextInputType.number,
            ),
            _buildBirthdatePicker(provider.language, user),
            _buildGenderSelector(provider, user),
            _buildGoalSelector(provider, user),
          ]),
          const SizedBox(height: 24),
          _buildSection(l10n.language, [
            _buildLanguageSelector(provider, provider.language),
          ]),
          const SizedBox(height: 24),
          _buildSection(l10n.apiKey, [
            _buildTextField(
              l10n.geminiApiKeyLabel,
              _apiKeyController,
              obscureText: true,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.apiKeyInfo,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.slate.withValues(alpha: 0.6),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 24),
          _buildSection(l10n.notifications, [
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
          ]),
          const SizedBox(height: 24),
          _buildSection(l10n.data, [
            ListTile(
              leading: const Icon(Icons.upload, color: AppColors.primary),
              title: Text(
                l10n.exportData,
                style: const TextStyle(color: AppColors.slate),
              ),
              onTap: () async {
                final path = await provider.exportData();
                if (path != null && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.exported(path)),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.download, color: AppColors.primary),
              title: Text(
                l10n.importData,
                style: const TextStyle(color: AppColors.slate),
              ),
              onTap: () async {
                final success = await provider.importData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success ? l10n.importSuccessful : l10n.importFailed,
                      ),
                      backgroundColor: success
                          ? AppColors.success
                          : AppColors.error,
                    ),
                  );
                }
              },
            ),
          ]),
          const SizedBox(height: 32),
          PrimaryButton(text: l10n.saveChanges, onPressed: _saveChanges),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.slate,
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          backgroundColor: AppColors.pebble.withValues(alpha: 0.3),
          padding: EdgeInsets.zero,
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
    bool obscureText = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: AppColors.slate.withValues(alpha: 0.6)),
          border: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.pebble),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.primary),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSelector(AppProvider provider, String language) {
    final l10n = context.l10n;
    return RadioGroup<String>(
      groupValue: language,
      onChanged: (v) => provider.updateUser(language: v),
      child: Column(
        children: [
          RadioListTile<String>(
            title: Text(l10n.german),
            value: 'de',
            activeColor: AppColors.primary,
          ),
          RadioListTile<String>(
            title: Text(l10n.english),
            value: 'en',
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildBirthdatePicker(String language, UserModel user) {
    final l10n = context.l10n;
    final birthdate = _selectedBirthdate ?? user.birthdate;
    final age = _calculateAge(birthdate);
    final formattedDate = _formatDate(birthdate, language);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      title: Text(
        l10n.birthdate,
        style: TextStyle(
          fontSize: 16,
          color: AppColors.slate.withValues(alpha: 0.6),
        ),
      ),
      subtitle: Text(
        formattedDate,
        style: const TextStyle(fontSize: 16, color: AppColors.slate),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            ),
            child: Text(
              l10n.ageYears(age),
              style: TextStyle(
                fontSize: 14,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.calendar_today, color: AppColors.primary),
        ],
      ),
      onTap: () => _showDatePicker(language),
    );
  }

  int _calculateAge(DateTime birthdate) {
    final now = DateTime.now();
    int age = now.year - birthdate.year;
    if (now.month < birthdate.month ||
        (now.month == birthdate.month && now.day < birthdate.day)) {
      age--;
    }
    return age;
  }

  Widget _buildGenderSelector(AppProvider provider, UserModel user) {
    final l10n = context.l10n;
    final genders = [l10n.male, l10n.female];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            l10n.genderLabel,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.slate.withValues(alpha: 0.6),
            ),
          ),
        ),
        RadioGroup<int>(
          groupValue: user.gender,
          onChanged: (val) {
            if (val != null) {
              provider.updateUser(gender: val);
            }
          },
          child: Column(
            children: List.generate(genders.length, (index) {
              return RadioListTile<int>(
                title: Text(genders[index]),
                value: index,
                activeColor: AppColors.primary,
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildGoalSelector(AppProvider provider, UserModel user) {
    final l10n = context.l10n;

    final goals = [l10n.loseWeight, l10n.maintainWeight, l10n.gainMuscle];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            l10n.goalLabel,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.slate.withValues(alpha: 0.6),
            ),
          ),
        ),
        RadioGroup<int>(
          groupValue: user.goal,
          onChanged: (val) {
            if (val != null) {
              provider.updateUser(goal: val);
            }
          },
          child: Column(
            children: List.generate(goals.length, (index) {
              return RadioListTile<int>(
                title: Text(goals[index]),
                value: index,
                activeColor: AppColors.primary,
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              );
            }),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date, String language) {
    return DateFormat.yMMMd(language).format(date);
  }

  Future<void> _showDatePicker(String language) async {
    final now = DateTime.now();
    final birthdate = _selectedBirthdate ?? now;

    final picked = await showDatePicker(
      context: context,
      initialDate: birthdate,
      firstDate: DateTime(1900),
      lastDate: now,
      locale: language == 'de' ? const Locale('de') : const Locale('en'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.pebble,
              surface: AppColors.limestone,
              onSurface: AppColors.slate,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedBirthdate = picked;
      });
    }
  }

  void _saveChanges() async {
    final provider = context.read<AppProvider>();
    final l10n = context.l10n;

    final oldWeight = provider.user?.weight;
    final newWeightStr = _weightController.text.trim();
    final newWeight = double.tryParse(newWeightStr);

    await provider.updateUser(
      name: _nameController.text.trim(),
      height: double.tryParse(_heightController.text) ?? provider.user!.height,
      weight: newWeight ?? provider.user!.weight,
      birthdate: _selectedBirthdate,
      apiKey: _apiKeyController.text.trim(),
    );

    // Auto-track weight if it changed
    if (oldWeight != null && newWeight != null && oldWeight != newWeight) {
      await provider.saveWeight(
        WeightModel(weight: newWeight, date: DateTime.now()),
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.saved), backgroundColor: AppColors.success),
      );
      Navigator.pop(context);
    }
  }
}
