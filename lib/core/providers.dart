import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'models/coolify_instance.dart';
import 'models/tag.dart';
import 'models/team.dart';
import 'api/api_client.dart';
import 'api/coolify_api.dart';
import 'storage/instance_store.dart';

final instanceStoreProvider = Provider<InstanceStore>((ref) {
  return InstanceStore(const FlutterSecureStorage());
});

/// Holds the saved Coolify connections + the active one.
class InstancesNotifier extends AsyncNotifier<InstancesState> {
  InstanceStore get _store => ref.read(instanceStoreProvider);

  @override
  Future<InstancesState> build() async {
    return _store.load();
  }

  Future<void> _persist(InstancesState next) async {
    state = AsyncData(next);
    await _store.save(next);
  }

  Future<void> addInstance(CoolifyInstance instance) async {
    final current = state.value ?? const InstancesState();
    final updated = InstancesState(
      instances: [...current.instances, instance],
      activeId: current.activeId ?? instance.id,
    );
    await _persist(updated);
  }

  Future<void> updateInstance(CoolifyInstance instance) async {
    final current = state.value ?? const InstancesState();
    final updated = InstancesState(
      instances: [
        for (final i in current.instances)
          if (i.id == instance.id) instance else i,
      ],
      activeId: current.activeId,
    );
    await _persist(updated);
  }

  Future<void> removeInstance(String id) async {
    final current = state.value ?? const InstancesState();
    final remaining = current.instances.where((i) => i.id != id).toList();
    var activeId = current.activeId;
    if (activeId == id) {
      activeId = remaining.isNotEmpty ? remaining.first.id : null;
    }
    await _persist(InstancesState(instances: remaining, activeId: activeId));
  }

  Future<void> setActive(String id) async {
    final current = state.value ?? const InstancesState();
    await _persist(InstancesState(instances: current.instances, activeId: id));
  }

  Future<void> reload() async {
    final next = await _store.load();
    state = AsyncData(next);
  }
}

final instancesProvider =
    AsyncNotifierProvider<InstancesNotifier, InstancesState>(
      InstancesNotifier.new,
    );

/// The API client bound to the active instance.
final apiClientProvider = Provider<ApiClient>((ref) {
  final active = ref.watch(
    instancesProvider.select((s) => s.value?.active),
  );
  if (active == null) return ApiClient.unauthenticated();
  return ApiClient(active);
});

/// Typed facade bound to [apiClientProvider]; rebuilt on instance switch.
final apiProvider = Provider<CoolifyApi>((ref) {
  return CoolifyApi(ref.watch(apiClientProvider));
});

final apiVersionProvider = FutureProvider<String>((ref) async {
  return ref.watch(apiProvider).version();
});

final currentTeamProvider = FutureProvider<Team?>((ref) async {
  try {
    return await ref.watch(apiProvider).team();
  } catch (_) {
    return null;
  }
});

final instancesListProvider = Provider<List<CoolifyInstance>>(
  (ref) => ref.watch(instancesProvider).value?.instances ?? const [],
);

final activeInstanceProvider = Provider<CoolifyInstance?>(
  (ref) => ref.watch(instancesProvider).value?.active,
);

final auditEventsProvider = FutureProvider<List<AuditEvent>>((ref) {
  return ref.watch(apiProvider).auditEvents();
});