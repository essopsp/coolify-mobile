import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/coolify_instance.dart';

class InstancesState {
  const InstancesState({this.instances = const [], this.activeId});

  final List<CoolifyInstance> instances;
  final String? activeId;

  CoolifyInstance? get active {
    final id = activeId;
    if (id == null) return null;
    for (final i in instances) {
      if (i.id == id) return i;
    }
    return null;
  }

  bool get hasActive => active != null;

  factory InstancesState.initial() => const InstancesState();
}

class InstanceStore {
  InstanceStore(this._storage);

  final FlutterSecureStorage _storage;

  static const _instancesKey = 'coolify.instances';
  static const _activeKey = 'coolify.active';

  Future<InstancesState> load() async {
    final raw = await _storage.read(key: _instancesKey);
    final activeId = await _storage.read(key: _activeKey);
    if (raw == null || raw.isEmpty) {
      return const InstancesState();
    }
    try {
      final list = (jsonDecode(raw) as List)
          .map((e) => CoolifyInstance.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      return InstancesState(instances: list, activeId: activeId);
    } catch (_) {
      return const InstancesState();
    }
  }

  Future<void> save(InstancesState state) async {
    await _storage.write(
      key: _instancesKey,
      value: jsonEncode(state.instances.map((i) => i.toJson()).toList()),
    );
    if (state.activeId != null) {
      await _storage.write(key: _activeKey, value: state.activeId!);
    } else {
      await _storage.delete(key: _activeKey);
    }
  }
}