import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/models/app_config.dart';

/// Reusable, build-pack aware configuration editor for an application.
///
/// Used in three places:
///  * `_RepoCreateSheet` (create-time, before the first deploy)
///  * the application settings screen (edit-time, PATCH)
///  * optionally the service settings screen (compose fields only)
///
/// It owns its own controllers and exposes the collected values through
/// [onChanged] / [value] so a parent can read them on submit.
class ConfigForm extends StatefulWidget {
  const ConfigForm({
    super.key,
    required this.initial,
    this.buildPack,
    this.showBasics = true,
    this.showBuild = true,
    this.showPorts = true,
    this.showDocker = true,
    this.showAdvanced = false,
    this.onChanged,
  });

  final AppConfig initial;

  /// When provided, Dockerfile/Compose fields are gated on this build pack.
  final String? buildPack;

  final bool showBasics;
  final bool showBuild;
  final bool showPorts;
  final bool showDocker;

  /// Collapsed section for limits/labels — off by default to reduce noise.
  final bool showAdvanced;

  final ValueChanged<AppConfig>? onChanged;

  @override
  State<ConfigForm> createState() => ConfigFormState();
}

class ConfigFormState extends State<ConfigForm> {
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _domains;
  late final TextEditingController _baseDirectory;
  late final TextEditingController _publishDirectory;
  late final TextEditingController _installCommand;
  late final TextEditingController _startCommand;
  late final TextEditingController _buildCommand;
  late final TextEditingController _portsExposes;
  late final TextEditingController _portsMappings;
  late final TextEditingController _healthPath;
  late final TextEditingController _healthPort;
  late final TextEditingController _healthHost;
  late final TextEditingController _healthInterval;
  late final TextEditingController _healthTimeout;
  late final TextEditingController _healthRetries;
  late final TextEditingController _healthStartPeriod;
  late final TextEditingController _dockerfile;
  late final TextEditingController _composeLocation;
  late final TextEditingController _composeRaw;
  late final TextEditingController _composeDomains;
  late final TextEditingController _customRunOptions;
  late final TextEditingController _limitsMemory;
  late final TextEditingController _limitsCpus;

  late bool _healthEnabled;
  late bool _isStatic;
  late String _healthMethod;
  bool _advancedOpen = false;

  @override
  void initState() {
    super.initState();
    final c = widget.initial;
    _name = TextEditingController(text: c.name ?? '');
    _description = TextEditingController(text: c.description ?? '');
    _domains = TextEditingController(text: c.domains ?? '');
    _baseDirectory = TextEditingController(text: c.baseDirectory ?? '');
    _publishDirectory = TextEditingController(text: c.publishDirectory ?? '');
    _installCommand = TextEditingController(text: c.installCommand ?? '');
    _startCommand = TextEditingController(text: c.startCommand ?? '');
    _buildCommand = TextEditingController(text: c.buildCommand ?? '');
    _portsExposes = TextEditingController(text: c.portsExposes ?? '');
    _portsMappings = TextEditingController(text: c.portsMappings ?? '');
    _healthPath = TextEditingController(text: c.healthCheckPath ?? '');
    _healthPort = TextEditingController(text: c.healthCheckPort ?? '');
    _healthHost = TextEditingController(text: c.healthCheckHost ?? '');
    _healthInterval = TextEditingController(text: c.healthCheckInterval ?? '');
    _healthTimeout = TextEditingController(text: c.healthCheckTimeout ?? '');
    _healthRetries = TextEditingController(text: c.healthCheckRetries ?? '');
    _healthStartPeriod =
        TextEditingController(text: c.healthCheckStartPeriod ?? '');
    _dockerfile = TextEditingController(text: c.dockerfile ?? '');
    _composeLocation =
        TextEditingController(text: c.dockerComposeLocation ?? '');
    _composeRaw = TextEditingController(text: c.dockerComposeRaw ?? '');
    _composeDomains =
        TextEditingController(text: c.dockerComposeDomains ?? '');
    _customRunOptions =
        TextEditingController(text: c.customDockerRunOptions ?? '');
    _limitsMemory = TextEditingController(text: c.limitsMemory ?? '');
    _limitsCpus = TextEditingController(text: c.limitsCpus ?? '');
    _healthEnabled = c.healthCheckEnabled ?? false;
    _isStatic = c.isStatic ?? false;
    _healthMethod = kHealthCheckMethods.contains(c.healthCheckMethod)
        ? c.healthCheckMethod!
        : 'GET';
    for (final ctl in _all) {
      ctl.addListener(_notify);
    }
  }

  List<TextEditingController> get _all => [
        _name,
        _description,
        _domains,
        _baseDirectory,
        _publishDirectory,
        _installCommand,
        _startCommand,
        _buildCommand,
        _portsExposes,
        _portsMappings,
        _healthPath,
        _healthPort,
        _healthHost,
        _healthInterval,
        _healthTimeout,
        _healthRetries,
        _healthStartPeriod,
        _dockerfile,
        _composeLocation,
        _composeRaw,
        _composeDomains,
        _customRunOptions,
        _limitsMemory,
        _limitsCpus,
      ];

  @override
  void dispose() {
    for (final ctl in _all) {
      ctl.dispose();
    }
    super.dispose();
  }

  void _notify() {
    widget.onChanged?.call(collect());
  }

  /// Collects the current values.
  AppConfig collect() => AppConfig(
        name: _name.text,
        description: _description.text,
        domains: _domains.text,
        baseDirectory: _baseDirectory.text,
        publishDirectory: _publishDirectory.text,
        installCommand: _installCommand.text,
        startCommand: _startCommand.text,
        buildCommand: _buildCommand.text,
        portsExposes: _portsExposes.text,
        portsMappings: _portsMappings.text,
        healthCheckEnabled: _healthEnabled,
        healthCheckPath: _healthPath.text,
        healthCheckPort: _healthPort.text,
        healthCheckHost: _healthHost.text,
        healthCheckMethod: _healthMethod,
        healthCheckInterval: _healthInterval.text,
        healthCheckTimeout: _healthTimeout.text,
        healthCheckRetries: _healthRetries.text,
        healthCheckStartPeriod: _healthStartPeriod.text,
        dockerfile: _dockerfile.text,
        dockerComposeLocation: _composeLocation.text,
        dockerComposeRaw: _composeRaw.text,
        dockerComposeDomains: _composeDomains.text,
        customDockerRunOptions: _customRunOptions.text,
        isStatic: _isStatic,
        limitsMemory: _limitsMemory.text,
        limitsCpus: _limitsCpus.text,
      );

  bool get _isDockerfilePack => widget.buildPack == 'dockerfile';
  bool get _isComposePack => widget.buildPack == 'dockercompose';

  @override
  Widget build(BuildContext context) {
    final pack = widget.buildPack;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showBasics) ...[
          _section('Basics'),
          _field(_name, 'Name'),
          _field(_description, 'Description'),
        ],
        if (widget.showBuild || pack != null) ...[
          _section('Domains'),
          _field(_domains, 'Domains (one per line)',
              hint: 'https://app.example.com\nhttps://www.example.com',
              maxLines: 3),
        ],
        if (widget.showBuild) ...[
          _section('Build'),
          _field(_baseDirectory, 'Base directory', hint: '/'),
          _field(_publishDirectory, 'Publish directory', hint: '/'),
          _field(_buildCommand, 'Build command'),
          _field(_installCommand, 'Install command'),
          _field(_startCommand, 'Start command'),
        ],
        if (widget.showPorts) ...[
          _section('Ports'),
          _field(_portsExposes, 'Exposed ports', hint: '3000'),
          _field(_portsMappings, 'Port mappings', hint: '127.0.0.1:8080:80'),
        ],
        if (widget.showPorts) ...[
          _section('Healthcheck'),
          SwitchListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: const Text('Enable healthcheck'),
            value: _healthEnabled,
            onChanged: (v) => setState(() {
              _healthEnabled = v;
              _notify();
            }),
          ),
          if (_healthEnabled) ...[
            _field(_healthPath, 'Path', hint: '/'),
            _field(_healthPort, 'Port'),
            _field(_healthHost, 'Host', hint: 'localhost'),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Method',
                  isDense: true,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isDense: true,
                    value: _healthMethod,
                    items: [
                      for (final m in kHealthCheckMethods)
                        DropdownMenuItem(value: m, child: Text(m)),
                    ],
                    onChanged: (v) => setState(() {
                      _healthMethod = v ?? 'GET';
                      _notify();
                    }),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(child: _field(_healthInterval, 'Interval (s)')),
                const SizedBox(width: 8),
                Expanded(child: _field(_healthTimeout, 'Timeout (s)')),
              ],
            ),
            Row(
              children: [
                Expanded(child: _field(_healthRetries, 'Retries')),
                const SizedBox(width: 8),
                Expanded(child: _field(_healthStartPeriod, 'Start period (s)')),
              ],
            ),
          ],
        ],
        if (widget.showDocker && (pack == null || _isDockerfilePack)) ...[
          _section('Dockerfile'),
          _field(_dockerfile, 'Dockerfile location', hint: '/Dockerfile'),
        ],
        if (widget.showDocker && (pack == null || _isComposePack)) ...[
          _section('Docker Compose'),
          _field(_composeLocation, 'Compose location', hint: '/docker-compose.yml'),
          _field(_composeRaw, 'Compose content (YAML)',
              hint: 'services:\n  app:\n    image: …', maxLines: 10, mono: true),
          _field(_composeDomains, 'Compose domains (one per line)', maxLines: 3),
        ],
        if (widget.showDocker && pack != null && !_isDockerfilePack && !_isComposePack) ...[
          _section('Docker'),
          _field(_customRunOptions, 'Custom docker run options'),
        ],
        if (widget.showAdvanced) ...[
          const SizedBox(height: 8),
          _advancedToggle(),
          if (_advancedOpen) ...[
            _field(_customRunOptions, 'Custom docker run options'),
            Row(
              children: [
                Expanded(child: _field(_limitsMemory, 'Memory limit')),
                const SizedBox(width: 8),
                Expanded(child: _field(_limitsCpus, 'CPU limit')),
              ],
            ),
            SwitchListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: const Text('Static site (SPA)'),
              value: _isStatic,
              onChanged: (v) => setState(() {
                _isStatic = v;
                _notify();
              }),
            ),
          ],
        ],
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _advancedToggle() => OutlinedButton.icon(
        onPressed: () => setState(() => _advancedOpen = !_advancedOpen),
        icon: Icon(_advancedOpen ? Icons.expand_less : Icons.expand_more),
        label: const Text('Advanced'),
      );

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
        child: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            letterSpacing: 0.3,
          ),
        ),
      );

  Widget _field(
    TextEditingController c,
    String label, {
    String? hint,
    int maxLines = 1,
    bool mono = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        maxLines: maxLines,
        minLines: maxLines > 1 ? maxLines : null,
        keyboardType: mono ? TextInputType.multiline : TextInputType.text,
        inputFormatters: mono
            ? [FilteringTextInputFormatter.deny(RegExp(r'[\r\n]'))]
            : null,
        style: mono
            ? const TextStyle(fontFamily: 'monospace', fontSize: 12)
            : null,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          isDense: true,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

/// Compact form for editing a service's docker-compose and metadata.
class ServiceConfigForm extends StatefulWidget {
  const ServiceConfigForm({
    super.key,
    required this.initial,
    this.onChanged,
  });

  final ServiceConfig initial;
  final ValueChanged<ServiceConfig>? onChanged;

  @override
  State<ServiceConfigForm> createState() => ServiceConfigFormState();
}

class ServiceConfigFormState extends State<ServiceConfigForm> {
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _compose;
  late bool _connectNetwork;

  @override
  void initState() {
    super.initState();
    final c = widget.initial;
    _name = TextEditingController(text: c.name ?? '');
    _description = TextEditingController(text: c.description ?? '');
    _compose = TextEditingController(text: c.dockerComposeRaw ?? '');
    _connectNetwork = c.connectToDockerNetwork ?? false;
    for (final ctl in [_name, _description, _compose]) {
      ctl.addListener(_notify);
    }
  }

  void _notify() => widget.onChanged?.call(collect());

  ServiceConfig collect() => ServiceConfig(
        name: _name.text,
        description: _description.text,
        dockerComposeRaw: _compose.text,
        connectToDockerNetwork: _connectNetwork,
      );

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _compose.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _field(_name, 'Name'),
        _field(_description, 'Description'),
        _field(_compose, 'docker-compose.yml',
            hint: 'services:\n  app:\n    image: …', maxLines: 16, mono: true),
        SwitchListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: const Text('Connect to Docker network'),
          value: _connectNetwork,
          onChanged: (v) => setState(() {
            _connectNetwork = v;
            _notify();
          }),
        ),
      ],
    );
  }

  Widget _field(TextEditingController c, String label,
      {String? hint, int maxLines = 1, bool mono = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        maxLines: maxLines,
        minLines: maxLines > 1 ? maxLines : null,
        keyboardType: mono ? TextInputType.multiline : TextInputType.text,
        style:
            mono ? const TextStyle(fontFamily: 'monospace', fontSize: 12) : null,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          isDense: true,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}