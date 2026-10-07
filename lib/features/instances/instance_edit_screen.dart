import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/api/coolify_api.dart';
import '../../core/models/coolify_instance.dart';
import '../../core/providers.dart';

class InstanceEditScreen extends ConsumerStatefulWidget {
  const InstanceEditScreen({super.key, this.editId});

  final String? editId;

  @override
  ConsumerState<InstanceEditScreen> createState() => _InstanceEditScreenState();
}

class _InstanceEditScreenState extends ConsumerState<InstanceEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _url;
  late final TextEditingController _token;

  bool _validating = false;
  String? _probeResult;

  bool get _isEdit => widget.editId != null;

  @override
  void initState() {
    super.initState();
    final editing = widget.editId == null
        ? null
        : _findInstance(widget.editId!);
    _name = TextEditingController(text: editing?.name ?? '');
    _url = TextEditingController(text: editing?.url ?? '');
    _token = TextEditingController(text: editing?.token ?? '');
  }

  CoolifyInstance? _findInstance(String id) {
    final list = ref.read(instancesProvider).value?.instances ?? const [];
    for (final i in list) {
      if (i.id == id) return i;
    }
    return null;
  }

  @override
  void dispose() {
    _name.dispose();
    _url.dispose();
    _token.dispose();
    super.dispose();
  }

  Future<void> _test() async {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;
    setState(() {
      _validating = true;
      _probeResult = null;
    });
    try {
      final instance = _buildInstance();
      final (team, version) = await CoolifyApi.forInstance(instance).validateConnection(instance);
      setState(() {
        _probeResult = 'Connected to "$team" · Coolify v$version';
      });
    } on ApiException catch (e) {
      setState(() => _probeResult = e.message);
    } catch (e) {
      setState(() => _probeResult = e.toString());
    } finally {
      setState(() => _validating = false);
    }
  }

  CoolifyInstance _buildInstance() {
    final id = widget.editId ?? _randomId();
    return CoolifyInstance(
      id: id,
      name: _name.text.trim().isEmpty ? _hostOnly() : _name.text.trim(),
      url: _url.text.trim(),
      token: _token.text.trim(),
    );
  }

  String _hostOnly() {
    final u = _url.text.trim();
    return u.replaceAll(RegExp(r'^https?://'), '').replaceAll(RegExp(r'/.*$'), '');
  }

  Future<void> _save() async {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;
    setState(() => _validating = true);
    final instance = _buildInstance();
    try {
      // Validate before persisting.
      await CoolifyApi.forInstance(instance).validateConnection(instance);
      final notifier = ref.read(instancesProvider.notifier);
      if (_isEdit) {
        await notifier.updateInstance(instance);
      } else {
        await notifier.addInstance(instance);
      }
      if (mounted) {
        context.go('/');
      }
    } on ApiException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _validating = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit connection' : 'Add Coolify instance'),
        actions: [
          TextButton(onPressed: _validating ? null : _test, child: const Text('Test')),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. Production',
                prefixIcon: Icon(Icons.label_outline),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _url,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Instance URL',
                hintText: 'https://app.coolify.io or https://coolify.example.com',
                prefixIcon: Icon(Icons.link),
              ),
              validator: (v) {
                final s = (v ?? '').trim();
                if (!s.startsWith('http://') && !s.startsWith('https://')) {
                  return 'Must start with http:// or https://';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _token,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(
                labelText: 'API token',
                hintText: 'Bearer token from Coolify → Security → API tokens',
                prefixIcon: Icon(Icons.key),
              ),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Token is required' : null,
            ),
            const SizedBox(height: 20),
            if (_probeResult != null || _validating) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (_probeResult?.startsWith('Connected') ?? false)
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    if (_validating)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Icon(
                        (_probeResult?.startsWith('Connected') ?? false)
                            ? Icons.check_circle
                            : Icons.error_outline,
                        size: 18,
                      ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_probeResult ?? 'Testing…')),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            const Card(
              child: Padding(
                padding: EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Notes',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    SizedBox(height: 4),
                    Text(
                      '• For Coolify Cloud use https://app.coolify.io\n'
                      '• For self-hosted, enable API access under '
                      'Settings → Advanced → API access.\n'
                      '• Tokens are stored encrypted on this device only.',
                      style: TextStyle(fontSize: 12, color: Colors.white60),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _validating ? null : _save,
              icon: Icon(_isEdit ? Icons.save_outlined : Icons.cloud_done_outlined),
              label: Text(_isEdit ? 'Save changes' : 'Connect'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
String _randomId() {
  final b = Random.secure();
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  return List.generate(16, (_) => chars[b.nextInt(chars.length)]).join();
}