import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/app_config.dart';
import '../../core/models/application.dart';
import '../../core/models/service.dart';
import '../../core/providers.dart';
import '../../shared/widgets/async_view.dart';
import '../../shared/widgets/confirm.dart';
import '../detail_providers.dart';
import 'config_form.dart';

/// Edit the build/runtime configuration of an existing application.
/// Persisted via `PATCH /applications/{uuid}`.
class AppSettingsScreen extends ConsumerStatefulWidget {
  const AppSettingsScreen({super.key, required this.uuid});

  final String uuid;

  @override
  ConsumerState<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends ConsumerState<AppSettingsScreen> {
  final _formKey = GlobalKey<ConfigFormState>();
  AppConfig _config = const AppConfig();
  bool _loaded = false;
  bool _saving = false;

  void _loadFrom(Application app) {
    if (_loaded) return;
    _config = AppConfig.fromApplicationJson(app.raw);
    _loaded = true;
  }

  Future<void> _refreshApp() async {
    ref.invalidate(applicationProvider(widget.uuid));
    await ref.read(applicationProvider(widget.uuid).future);
  }

  @override
  Widget build(BuildContext context) {
    final appAsync = ref.watch(applicationProvider(widget.uuid));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuration'),
        actions: [
          IconButton(
            onPressed: _loaded ? _save : null,
            icon: const Icon(Icons.save_alt),
            tooltip: 'Save configuration',
          ),
        ],
      ),
      body: AsyncView<Application>(
        value: appAsync,
        onRefresh: _refreshApp,
        builder: (context, app) {
          _loadFrom(app);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              ConfigForm(
                key: _formKey,
                initial: _config,
                buildPack: app.buildPack,
                showAdvanced: true,
                onChanged: (c) => _config = c,
              ),
              const SizedBox(height: 8),
              if (_saving)
                const Center(child: CircularProgressIndicator())
              else
                FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  label: const Text('Save & apply'),
                ),
              const SizedBox(height: 8),
              const Text(
                'Saving configuration changes the app definition. '
                'Redeploy for most changes to take effect.',
                style: TextStyle(fontSize: 12, color: Colors.white54),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await showBusy(
      context,
      busyLabel: 'Saving configuration…',
      action: () async {
        await ref.read(apiProvider).patchApplication(widget.uuid, _config);
        ref.invalidate(applicationProvider(widget.uuid));
      },
      successMessage: 'Configuration saved. Redeploy to apply.',
    );
    if (mounted) setState(() => _saving = false);
  }
}

/// Edit a service's docker-compose and metadata via `PATCH /services/{uuid}`.
class ServiceSettingsScreen extends ConsumerStatefulWidget {
  const ServiceSettingsScreen({super.key, required this.uuid});

  final String uuid;

  @override
  ConsumerState<ServiceSettingsScreen> createState() =>
      _ServiceSettingsScreenState();
}

class _ServiceSettingsScreenState extends ConsumerState<ServiceSettingsScreen> {
  ServiceConfig _config = ServiceConfig.empty;
  bool _loaded = false;

  Future<void> _refreshService() async {
    ref.invalidate(serviceProvider(widget.uuid));
    await ref.read(serviceProvider(widget.uuid).future);
  }

  @override
  Widget build(BuildContext context) {
    final svcAsync = ref.watch(serviceProvider(widget.uuid));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Service configuration'),
        actions: [
          IconButton(
            onPressed: _save,
            icon: const Icon(Icons.save_alt),
            tooltip: 'Save configuration',
          ),
        ],
      ),
body: AsyncView<Service>(
        value: svcAsync,
        onRefresh: _refreshService,
        builder: (context, service) {
          if (!_loaded) {
            _config = ServiceConfig.fromJson(service.raw);
            _loaded = true;
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              ServiceConfigForm(
                initial: _config,
                onChanged: (c) => _config = c,
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text('Save & apply'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _save() async {
    await showBusy(
      context,
      busyLabel: 'Saving configuration…',
      action: () async {
        await ref.read(apiProvider).patchService(widget.uuid, _config);
        ref.invalidate(serviceProvider(widget.uuid));
      },
      successMessage: 'Service configuration saved.',
    );
  }
}