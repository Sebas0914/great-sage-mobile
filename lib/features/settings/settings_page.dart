import 'package:flutter/material.dart';

import '../../core/assistant/assistant_settings.dart';
import '../../core/assistant/assistant_settings_repository.dart';
import '../../core/storage/shared_preferences_storage.dart';
import '../../core/overlay/android_overlay_service.dart';
import '../raphael/raphael_runtime.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final baseUrlController = TextEditingController();
  final apiKeyController = TextEditingController();
  final modelController = TextEditingController();

  AssistantSettingsRepository? repository;
  AssistantProviderType provider = AssistantProviderType.localDemo;
  bool loading = true;
  bool saving = false;
  bool overlayActive = false;
  bool obscureApiKey = true;
  String? status;

  final overlay = const AndroidOverlayService();
  final raphael = RaphaelRuntime.instance;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    baseUrlController.dispose();
    apiKeyController.dispose();
    modelController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final storage = await SharedPreferencesStorage.create();
      final repo = AssistantSettingsRepository(storage);
      final settings = await repo.load();
      final active = await overlay.hasPermission();
      if (!mounted) return;

      setState(() {
        repository = repo;
        provider = settings.provider;
        baseUrlController.text = settings.apiBaseUrl;
        apiKeyController.text = settings.apiKey;
        modelController.text = settings.model;
        overlayActive = active;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        loading = false;
        status = 'No se pudo cargar la configuración.';
      });
    }
  }

  Future<void> _save() async {
    final repo = repository;
    if (repo == null || saving) return;

    setState(() {
      saving = true;
      status = null;
    });

    try {
      await repo.save(
        AssistantSettings(
          provider: provider,
          apiBaseUrl: baseUrlController.text,
          apiKey: apiKeyController.text,
          model: modelController.text,
        ),
      );
      if (!mounted) return;
      setState(() {
        saving = false;
        status = 'Configuración guardada.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        saving = false;
        status = 'No se pudo guardar la configuración.';
      });
    }
  }

  Future<void> _toggleOverlay() async {
    final supported = await overlay.isSupported();
    if (!supported || !mounted) {
      if (mounted) {
        setState(() => status = 'El overlay no está disponible en este dispositivo.');
      }
      return;
    }

    if (overlayActive) {
      try {
        await raphael.setFloating(false);
        if (mounted) {
          setState(() {
            overlayActive = false;
            status = 'Raphael flotante desactivado.';
          });
        }
      } catch (_) {
        if (mounted) setState(() => status = 'No se pudo desactivar Raphael.');
      }
      return;
    }

    if (await overlay.hasPermission()) {
      try {
        await raphael.setFloating(true);
        if (mounted) {
          setState(() {
            overlayActive = true;
            status = 'Raphael flotante activado.';
          });
        }
      } catch (_) {
        if (mounted) setState(() => status = 'No se pudo activar Raphael.');
      }
      return;
    }

    final openedSettings = await overlay.requestPermission();
    if (mounted) {
      setState(() => status = openedSettings
          ? 'Concede el permiso de superposición y vuelve a la app para activarlo.'
          : 'No se pudo abrir el permiso de superposición.');
    }
  }

  Future<void> _clear() async {
    final repo = repository;
    if (repo == null || saving) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restablecer configuración'),
        content: const Text(
          'Se borrará la configuración local del proveedor de IA.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restablecer'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await repo.clear();
    setState(() {
      provider = AssistantProviderType.localDemo;
      baseUrlController.clear();
      apiKeyController.clear();
      modelController.clear();
      status = 'Configuración restablecida.';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        appBar: AppBar(title: Text('Configuración')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Raphael flotante',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(overlayActive ? 'Raphael está activo' : 'Raphael está desactivado'),
            subtitle: const Text('Mostrar a Raphael sobre otras aplicaciones'),
            value: overlayActive,
            onChanged: saving ? null : (_) => _toggleOverlay(),
          ),
          const SizedBox(height: 28),
          Text(
            'Proveedor de IA',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<AssistantProviderType>(
            initialValue: provider,
            decoration: const InputDecoration(
              labelText: 'Proveedor',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: AssistantProviderType.localDemo,
                child: Text('Demo local'),
              ),
              DropdownMenuItem(
                value: AssistantProviderType.openAiCompatible,
                child: Text('Compatible con OpenAI'),
              ),
            ],
            onChanged: saving
                ? null
                : (value) {
                    if (value != null) setState(() => provider = value);
                  },
          ),
          const SizedBox(height: 24),
          if (provider == AssistantProviderType.openAiCompatible) ...[
            TextField(
              controller: baseUrlController,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'URL base',
                hintText: 'https://servidor.example/v1',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: modelController,
              decoration: const InputDecoration(
                labelText: 'Modelo',
                hintText: 'Nombre del modelo',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: apiKeyController,
              obscureText: obscureApiKey,
              decoration: InputDecoration(
                labelText: 'API key',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: obscureApiKey ? 'Mostrar clave' : 'Ocultar clave',
                  onPressed: () => setState(() => obscureApiKey = !obscureApiKey),
                  icon: Icon(obscureApiKey ? Icons.visibility : Icons.visibility_off),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'La clave se guarda en el almacenamiento seguro del dispositivo.',
            ),
          ],
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: saving ? null : _save,
            icon: saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(saving ? 'Guardando…' : 'Guardar configuración'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: saving ? null : _clear,
            child: const Text('Restablecer'),
          ),
          if (status != null) ...[
            const SizedBox(height: 16),
            Text(
              status!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}
