import 'dart:io';
import '../utils/platform_utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../extensions/l10n_extension.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../services/auth_service.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
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
    // Access provider safely in initState
    final user = context.read<AppProvider>().user;

    _nameController = TextEditingController(text: user?.name ?? '');
    _heightController = TextEditingController(
      text: user?.height.toString() ?? '',
    );
    _weightController = TextEditingController(
      text: user?.weight.toString() ?? '',
    );
    _apiKeyController = TextEditingController(
      text: context.read<AppProvider>().apiKey,
    );
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

  Future<void> _saveChanges() async {
    final provider = context.read<AppProvider>();
    final user = provider.user;
    if (user == null) return;

    final name = _nameController.text.trim();
    final height =
        double.tryParse(_heightController.text.trim()) ?? user.height;
    final weight =
        double.tryParse(_weightController.text.trim()) ?? user.weight;
    final apiKey = _apiKeyController.text.trim();

    await provider.updateUser(
      name: name,
      height: height,
      weight: weight,
      apiKey: apiKey,
      birthdate: _selectedBirthdate,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.settingsSaved),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user = provider.user;
    final l10n = context.l10n;

    if (user == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

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
            const SizedBox(height: 24),
            _buildActivityLevelSelector(provider, user),
          ]),
          if (PlatformUtils.isWeb) ...[
            const SizedBox(height: 24),
            _buildHealthSection(provider, user),
          ] else ...[
            const SizedBox(height: 24),
            _buildHealthSection(provider, user),
          ],
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
            SwitchListTile(
              title: const Text(
                'Präzisions-Modus (Gramm)',
                style: TextStyle(color: AppColors.slate),
              ),
              subtitle: const Text(
                'Analyse zeigt Gramm statt Portionen',
                style: TextStyle(fontSize: 12),
              ),
              value: user.useGramsByDefault,
              activeThumbColor: AppColors.primary,
              onChanged: (v) => provider.updateUser(useGramsByDefault: v),
            ),
          ]),
          const SizedBox(height: 24),
          _buildHealthSection(provider, user),
          const SizedBox(height: 24),
          _buildLegalSection(provider, l10n),
          const SizedBox(height: 24),
          _buildAccountSection(provider, user),
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
                  await SharePlus.instance.share(
                    ShareParams(files: [XFile(path)], text: 'Kalorat Backup'),
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
                if (context.mounted) {
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

  Widget _buildActivityLevelSelector(AppProvider provider, UserModel user) {
    final l10n = context.l10n;
    final levels = [
      l10n.sedentary,
      l10n.lightlyActive,
      l10n.moderatelyActive,
      l10n.activeLevel,
      l10n.veryActive,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            l10n.activityLevel,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.slate.withValues(alpha: 0.6),
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.pebble.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.pebble),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: user.activityLevelIndex,
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down, color: AppColors.slate),
                dropdownColor: AppColors.limestone,
                borderRadius: BorderRadius.circular(12),
                items: List.generate(levels.length, (index) {
                  return DropdownMenuItem(
                    value: index,
                    child: Text(levels[index], style: AppTypography.bodyMedium),
                  );
                }),
                onChanged: (value) {
                  if (value != null) {
                    provider.updateUser(activityLevel: value);
                  }
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
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
        style: const TextStyle(color: AppColors.slate),
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
          groupValue: user.genderIndex,
          onChanged: (val) {
            if (val != null) {
              provider.updateUser(gender: val);
            }
          },
          child: Column(
            children: List.generate(genders.length, (index) {
              return RadioListTile<int>(
                title: Text(
                  genders[index],
                  style: const TextStyle(color: AppColors.slate),
                ),
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
          groupValue: user.goalIndex,
          onChanged: (val) {
            if (val != null) {
              provider.updateUser(goal: val);
            }
          },
          child: Column(
            children: List.generate(goals.length, (index) {
              return RadioListTile<int>(
                title: Text(
                  goals[index],
                  style: const TextStyle(color: AppColors.slate),
                ),
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

  Widget _buildHealthSection(AppProvider provider, UserModel user) {
    final l10n = context.l10n;
    final healthAppName = PlatformUtils.healthAppName;

    // On web, show grayed-out section with "only available in app" message
    if (PlatformUtils.isWeb) {
      return _buildSection(l10n.healthIntegration, [
        Opacity(
          opacity: 0.5,
          child: ListTile(
            leading: Icon(
              Icons.favorite_border,
              color: AppColors.slate.withValues(alpha: 0.5),
            ),
            title: Text(
              l10n.syncWith(healthAppName),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.slate.withValues(alpha: 0.7),
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.pebble.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppTheme.borderRadius / 2),
                border: Border.all(
                  color: AppColors.slate.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                l10n.featureOnlyInApp,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.slate.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ]);
    }

    // Native platform: show full health integration options
    return _buildSection(l10n.healthIntegration, [
      SwitchListTile(
        title: Text(
          l10n.syncWith(healthAppName),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.slate,
          ),
        ),
        subtitle: Text(
          user.healthSyncEnabled ? l10n.connected : l10n.disconnected,
          style: TextStyle(
            fontSize: 12,
            color: user.healthSyncEnabled
                ? AppColors.success
                : AppColors.slate.withValues(alpha: 0.6),
          ),
        ),
        value: user.healthSyncEnabled,
        activeThumbColor: AppColors.primary,
        onChanged: (val) async {
          if (val) {
            // Try to connect
            final success = await provider.healthService.requestPermissions();
            if (success) {
              provider.updateUser(healthSyncEnabled: true);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.healthConnected),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            } else {
              // Failed
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.healthConnectionFailed),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            }
          } else {
            // Disconnect
            provider.updateUser(healthSyncEnabled: false);
          }
        },
      ),
      if (user.healthSyncEnabled) ...[
        const Divider(height: 1, indent: 16, endIndent: 16),
        SwitchListTile(
          title: Text(
            l10n.syncMeals,
            style: const TextStyle(fontSize: 14, color: AppColors.slate),
          ),
          value: user.syncMealsToHealth,
          activeThumbColor: AppColors.primary,
          onChanged: (val) => provider.updateUser(syncMealsToHealth: val),
        ),
        SwitchListTile(
          title: Text(
            l10n.syncWeight,
            style: const TextStyle(fontSize: 14, color: AppColors.slate),
          ),
          value: user.syncWeightToHealth,
          activeThumbColor: AppColors.primary,
          onChanged: (val) => provider.updateUser(syncWeightToHealth: val),
        ),
      ],
    ]);
  }

  Widget _buildAccountSection(AppProvider provider, UserModel user) {
    final l10n = context.l10n;
    final authService = AuthService();
    final isGuest = user.isGuest;

    return _buildSection(l10n.account, [
      // Show current account status
      ListTile(
        leading: Icon(
          isGuest ? Icons.person_outline : Icons.person,
          color: AppColors.primary,
        ),
        title: Text(
          isGuest ? l10n.guestMode : (user.email ?? l10n.account),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.slate,
          ),
        ),
        subtitle: isGuest
            ? Text(
                l10n.accountSection,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.slate.withValues(alpha: 0.6),
                ),
              )
            : null,
      ),
      const Divider(height: 1, indent: 16, endIndent: 16),

      if (isGuest) ...[
        // Guest: Show login option
        ListTile(
          leading: const Icon(Icons.login, color: AppColors.primary),
          title: Text(
            l10n.loginToSync,
            style: const TextStyle(color: AppColors.slate),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () async {
            try {
              final (response, photoUrl) = await authService.signInWithGoogle();
              if (response.user != null && mounted) {
                await provider.updateUser(
                  supabaseUserId: response.user!.id,
                  email: response.user!.email,
                  isGuest: false,
                  photoUrl: photoUrl,
                );
                await provider.syncService.mergeLocalToCloud();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.syncComplete),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString()),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            }
          },
        ),
      ] else ...[
        // Logged in: Show account options
        ListTile(
          leading: const Icon(Icons.sync, color: AppColors.primary),
          title: Text(
            l10n.syncComplete,
            style: const TextStyle(color: AppColors.slate),
          ),
          subtitle: user.lastSyncTimestamp != null
              ? Text(
                  DateFormat.yMd(
                    provider.language,
                  ).add_Hm().format(user.lastSyncTimestamp!),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.slate.withValues(alpha: 0.6),
                  ),
                )
              : null,
          onTap: () async {
            await provider.syncService.syncToCloud();
            await provider.updateUser(lastSyncTimestamp: DateTime.now());
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.syncComplete),
                  backgroundColor: AppColors.success,
                ),
              );
            }
          },
        ),
        ListTile(
          leading: const Icon(Icons.download, color: AppColors.primary),
          title: Text(
            l10n.requestData,
            style: const TextStyle(color: AppColors.slate),
          ),
          onTap: () async {
            try {
              final jsonString = await provider.syncService.exportUserData();

              // Write to temp file for sharing
              final directory = await getTemporaryDirectory();
              final fileName =
                  'kalorat_user_data_${DateTime.now().toIso8601String().replaceAll(':', '-')}.json';
              final file = File('${directory.path}/$fileName');
              await file.writeAsString(jsonString);

              if (mounted) {
                await SharePlus.instance.share(
                  ShareParams(
                    files: [XFile(file.path)],
                    text: 'Kalorat User Data',
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      l10n.error,
                    ), // Use generic error or specific message
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            }
          },
        ),
        ListTile(
          leading: const Icon(Icons.logout, color: AppColors.slate),
          title: Text(
            l10n.logOut,
            style: const TextStyle(color: AppColors.slate),
          ),
          onTap: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(l10n.logOut),
                content: Text(l10n.logOutConfirm),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(l10n.cancel),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(
                      l10n.logOut,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            );

            if (confirm == true && mounted) {
              // Sign out from Auth Service
              await authService.signOut();

              // Update Provider State to Guest
              await provider.updateUser(
                supabaseUserId: null,
                email: null,
                isGuest: true,
                photoUrl: null,
              );

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.loggedOut),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            }
          },
        ),
        ListTile(
          leading: const Icon(Icons.delete_forever, color: AppColors.error),
          title: Text(
            l10n.deleteAccount,
            style: const TextStyle(color: AppColors.slate),
          ),
          onTap: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(l10n.deleteAccount),
                content: Text(
                  l10n.deleteAccountConfirm,
                ), // Ensure this string exists or use a hardcoded warning
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(l10n.cancel),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(
                      l10n.deleteAccount,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            );

            if (confirm == true && mounted) {
              await authService.deleteAccount();
              // Update Provider State to Guest
              await provider.updateUser(
                supabaseUserId: null,
                email: null,
                isGuest: true,
                photoUrl: null,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.accountDeleted),
                    backgroundColor: AppColors.success,
                  ),
                );
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            }
          },
        ),
      ],
    ]);
  }

  Widget _buildLegalSection(AppProvider provider, dynamic l10n) {
    return _buildSection(l10n.legal, [
      ListTile(
        leading: const Icon(
          Icons.privacy_tip_outlined,
          color: AppColors.primary,
        ),
        title: Text(
          l10n.privacyPolicy,
          style: const TextStyle(color: AppColors.slate),
        ),
        trailing: const Icon(Icons.open_in_new, size: 16),
        onTap: () {
          // Placeholder for actual URL
          // In a real app, this would use url_launcher
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(l10n.privacyPolicy),
              content: const Text(
                "Privacy Policy placeholder. Your data is stored locally and optionally synced to Supabase (if logged in). Meal photos are processed by Google's Gemini API.",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK"),
                ),
              ],
            ),
          );
        },
      ),
      const Divider(height: 1, indent: 16, endIndent: 16),
      ListTile(
        leading: const Icon(
          Icons.description_outlined,
          color: AppColors.primary,
        ),
        title: Text(
          l10n.termsOfService,
          style: const TextStyle(color: AppColors.slate),
        ),
        trailing: const Icon(Icons.open_in_new, size: 16),
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(l10n.termsOfService),
              content: const Text("Terms of Service placeholder."),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK"),
                ),
              ],
            ),
          );
        },
      ),
    ]);
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
}
