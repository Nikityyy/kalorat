import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_colors.dart';
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
    final language = provider.language;

    if (user == null)
      return const Center(
        child: CircularProgressIndicator(color: AppColors.shamrock),
      );

    return Scaffold(
      backgroundColor: AppColors.lavenderBlush,
      appBar: AppBar(
        title: Text(
          language == 'de' ? 'Einstellungen' : 'Settings',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSection(language == 'de' ? 'Profil' : 'Profile', [
            _buildTextField(
              language == 'de' ? 'Name' : 'Name',
              _nameController,
            ),
            _buildTextField(
              language == 'de' ? 'Größe (cm)' : 'Height (cm)',
              _heightController,
              keyboardType: TextInputType.number,
            ),
            _buildTextField(
              language == 'de' ? 'Gewicht (kg)' : 'Weight (kg)',
              _weightController,
              keyboardType: TextInputType.number,
            ),
          ]),
          const SizedBox(height: 24),
          _buildSection(language == 'de' ? 'Sprache' : 'Language', [
            _buildLanguageSelector(provider, language),
          ]),
          const SizedBox(height: 24),
          _buildSection('API Key', [
            _buildTextField(
              'Gemini API Key',
              _apiKeyController,
              obscureText: true,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                language == 'de'
                    ? 'API-Key von ai.dev eintragen oder ändern.'
                    : 'Enter or change your API key from ai.dev.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.carbonBlack.withValues(alpha: 0.6),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 24),
          _buildSection(
            language == 'de' ? 'Benachrichtigungen' : 'Notifications',
            [
              SwitchListTile(
                title: Text(
                  language == 'de' ? 'Mahlzeit-Erinnerungen' : 'Meal reminders',
                  style: const TextStyle(color: AppColors.carbonBlack),
                ),
                value: user.mealRemindersEnabled,
                activeColor: AppColors.shamrock,
                onChanged: (v) => provider.updateUser(mealRemindersEnabled: v),
              ),
              SwitchListTile(
                title: Text(
                  language == 'de'
                      ? 'Gewichts-Erinnerungen'
                      : 'Weight reminders',
                  style: const TextStyle(color: AppColors.carbonBlack),
                ),
                value: user.weightRemindersEnabled,
                activeColor: AppColors.shamrock,
                onChanged: (v) =>
                    provider.updateUser(weightRemindersEnabled: v),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(language == 'de' ? 'Daten' : 'Data', [
            ListTile(
              leading: const Icon(Icons.upload, color: AppColors.shamrock),
              title: Text(
                language == 'de' ? 'Daten exportieren' : 'Export data',
                style: const TextStyle(color: AppColors.carbonBlack),
              ),
              onTap: () async {
                final path = await provider.exportData();
                if (path != null && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        language == 'de'
                            ? 'Exportiert: $path'
                            : 'Exported: $path',
                      ),
                      backgroundColor: AppColors.emerald,
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.download, color: AppColors.shamrock),
              title: Text(
                language == 'de' ? 'Daten importieren' : 'Import data',
                style: const TextStyle(color: AppColors.carbonBlack),
              ),
              onTap: () async {
                final success = await provider.importData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? (language == 'de'
                                  ? 'Import erfolgreich'
                                  : 'Import successful')
                            : (language == 'de'
                                  ? 'Import fehlgeschlagen'
                                  : 'Import failed'),
                      ),
                      backgroundColor: success
                          ? AppColors.emerald
                          : AppColors.error,
                    ),
                  );
                }
              },
            ),
          ]),
          const SizedBox(height: 32),
          PrimaryButton(
            text: language == 'de' ? 'Änderungen speichern' : 'Save changes',
            onPressed: _saveChanges,
          ),
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
            color: AppColors.carbonBlack,
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          backgroundColor: AppColors.celadon.withValues(
            alpha: 0.3,
          ), // Slightly lighter for input sections
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
          labelStyle: TextStyle(
            color: AppColors.carbonBlack.withValues(alpha: 0.6),
          ),
          border: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.celadon),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.shamrock),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSelector(AppProvider provider, String language) {
    return Column(
      children: [
        RadioListTile<String>(
          title: const Text('Deutsch'),
          value: 'de',
          groupValue: language,
          activeColor: AppColors.shamrock,
          onChanged: (v) => provider.updateUser(language: v),
        ),
        RadioListTile<String>(
          title: const Text('English'),
          value: 'en',
          groupValue: language,
          activeColor: AppColors.shamrock,
          onChanged: (v) => provider.updateUser(language: v),
        ),
      ],
    );
  }

  void _saveChanges() async {
    final provider = context.read<AppProvider>();
    await provider.updateUser(
      name: _nameController.text.trim(),
      height: double.tryParse(_heightController.text) ?? provider.user!.height,
      weight: double.tryParse(_weightController.text) ?? provider.user!.weight,
      apiKey: _apiKeyController.text.trim(),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.language == 'de' ? 'Gespeichert!' : 'Saved!'),
          backgroundColor: AppColors.emerald,
        ),
      );
      Navigator.pop(context);
    }
  }
}
