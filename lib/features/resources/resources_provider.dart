import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/application.dart';
import '../../core/models/resource.dart';
import '../../core/models/server.dart';
import '../../core/models/service.dart';
import '../../core/providers.dart';

final resourcesProvider = FutureProvider<List<Resource>>((ref) {
  return ref.watch(apiProvider).resources();
});

final applicationsProvider = FutureProvider<List<Application>>((ref) {
  return ref.watch(apiProvider).applications();
});

final serversProvider = FutureProvider<List<Server>>((ref) {
  return ref.watch(apiProvider).servers();
});

final servicesProvider = FutureProvider<List<Service>>((ref) {
  return ref.watch(apiProvider).services();
});