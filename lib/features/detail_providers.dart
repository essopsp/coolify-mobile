import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/application.dart';
import '../../core/models/database.dart';
import '../../core/models/environment.dart';
import '../../core/models/server.dart';
import '../../core/models/service.dart';
import '../../core/models/tag.dart';
import '../../core/providers.dart';

// ── Applications ─────────────────────────────────────────────────────────────
final applicationProvider =
    FutureProvider.family<Application, String>((ref, uuid) {
      return ref.watch(apiProvider).application(uuid);
    });

final appEnvVarsProvider =
    FutureProvider.family<List<EnvVar>, String>((ref, uuid) {
      return ref.watch(apiProvider).envVars('application', uuid);
    });

final appLogsProvider =
    FutureProvider.autoDispose.family<String, ({String uuid, String? service})>(
      (ref, args) => ref
          .watch(apiProvider)
          .logs('application', args.uuid, serviceName: args.service),
    );

final appTasksProvider =
    FutureProvider.family<List<ScheduledTask>, String>((ref, uuid) {
      return ref.watch(apiProvider).tasks('application', uuid);
    });

final serviceTasksProvider =
    FutureProvider.family<List<ScheduledTask>, String>((ref, uuid) {
      return ref.watch(apiProvider).tasks('service', uuid);
    });

final appStoragesProvider =
    FutureProvider.family<List<Storage>, String>((ref, uuid) {
      return ref.watch(apiProvider).storages('application', uuid);
    });

final appRollbackImagesProvider =
    FutureProvider.family<List<String>, String>((ref, uuid) {
      return ref.watch(apiProvider).rollbackImages(uuid);
    });

// ── Databases ────────────────────────────────────────────────────────────────
final databaseProvider = FutureProvider.family<Database, String>((ref, uuid) {
  return ref.watch(apiProvider).database(uuid);
});

final dbEnvVarsProvider =
    FutureProvider.family<List<EnvVar>, String>((ref, uuid) {
      return ref.watch(apiProvider).envVars('database', uuid);
    });

final dbLogsProvider = FutureProvider.autoDispose.family<String, String>(
  (ref, uuid) => ref.watch(apiProvider).logs('database', uuid),
);

final dbBackupsProvider =
    FutureProvider.family<List<Backup>, String>((ref, uuid) {
      return ref.watch(apiProvider).databaseBackups(uuid);
    });

final dbBackupExecutionsProvider =
    FutureProvider.family<List<BackupExecution>, ({String db, String backup})>(
      (ref, args) => ref
          .watch(apiProvider)
          .backupExecutions(args.db, args.backup),
    );

// ── Services ─────────────────────────────────────────────────────────────────
final serviceProvider = FutureProvider.family<Service, String>((ref, uuid) {
  return ref.watch(apiProvider).service(uuid);
});

final serviceAppsProvider =
    FutureProvider.family<List<ServiceApp>, String>((ref, uuid) {
      return ref.watch(apiProvider).serviceApplications(uuid);
    });

final serviceDbsProvider =
    FutureProvider.family<List<ServiceDatabase>, String>((ref, uuid) {
      return ref.watch(apiProvider).serviceDatabases(uuid);
    });

final serviceLogsProvider =
    FutureProvider.autoDispose.family<String, ({String uuid, String app})>(
      (ref, args) =>
          ref.watch(apiProvider).serviceAppLogs(args.uuid, args.app),
    );

final serviceDbLogsProvider =
    FutureProvider.autoDispose.family<String, ({String uuid, String db})>(
      (ref, args) =>
          ref.watch(apiProvider).serviceDbLogs(args.uuid, args.db),
    );

// ── Servers ──────────────────────────────────────────────────────────────────
final serverProvider = FutureProvider.family<Server, String>((ref, uuid) {
  return ref.watch(apiProvider).server(uuid);
});

final serverResourcesProvider =
    FutureProvider.family<List<ServerResource>, String>((ref, uuid) {
      return ref.watch(apiProvider).serverResources(uuid);
    });

final serverDomainsProvider =
    FutureProvider.family<List<ServerDomain>, String>((ref, uuid) {
      return ref.watch(apiProvider).serverDomains(uuid);
    });

final serverCleanupProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, uuid) {
      return ref.watch(apiProvider).dockerCleanup(uuid);
    });