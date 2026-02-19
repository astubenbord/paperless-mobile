import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:paperless_mobile/core/database/hive/hive_config.dart';
import 'package:paperless_mobile/core/database/tables/global_settings.dart';
import 'package:paperless_mobile/core/util/message_helpers.dart';
import 'package:paperless_mobile/features/ai_chat/cubit/ai_chat_cubit.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';

class AiSettingsPage extends StatefulWidget {
  const AiSettingsPage({super.key});

  @override
  State<AiSettingsPage> createState() => _AiSettingsPageState();
}

class _AiSettingsPageState extends State<AiSettingsPage> {
  late final TextEditingController _urlController;
  late final TextEditingController _apiKeyController;
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    final settings =
        Hive.box<GlobalSettings>(HiveBoxes.globalSettings).getValue()!;
    _urlController = TextEditingController(text: settings.aiServerUrl);
    _apiKeyController = TextEditingController(text: settings.aiApiKey);
  }

  @override
  void dispose() {
    _urlController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  void _save() {
    final box = Hive.box<GlobalSettings>(HiveBoxes.globalSettings);
    final settings = box.getValue()!;
    settings.aiServerUrl = _urlController.text.trim();
    settings.aiApiKey = _apiKeyController.text.trim();
    box.setValue(settings);
    showSnackBar(context, 'Settings saved.');
  }

  Future<void> _testConnection() async {
    setState(() => _isTesting = true);
    final success = await AiChatCubit.testConnection(
      _urlController.text.trim(),
      _apiKeyController.text.trim(),
    );
    if (mounted) {
      setState(() => _isTesting = false);
      showSnackBar(
        context,
        success
            ? S.of(context)!.aiConnectionSuccess
            : S.of(context)!.aiConnectionFailed,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context)!.aiSettings),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Icon(
            Icons.auto_awesome,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            S.of(context)!.aiSettings,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Configure the connection to your Paperless-AI companion service.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _urlController,
            decoration: InputDecoration(
              labelText: S.of(context)!.aiServerUrl,
              hintText: 'https://paperless-ai.example.com',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.link),
            ),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _apiKeyController,
            decoration: InputDecoration(
              labelText: S.of(context)!.aiApiKey,
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.key),
            ),
            obscureText: true,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isTesting ? null : _testConnection,
                  icon: _isTesting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.wifi_tethering),
                  label: Text(S.of(context)!.aiConnectionTest),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  label: Text(S.of(context)!.saveChanges),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
