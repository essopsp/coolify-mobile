import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/deployment.dart';
import '../../core/providers.dart';

final runningDeploymentsProvider = FutureProvider<List<Deployment>>((ref) {
  return ref.watch(apiProvider).runningDeployments();
});

final appDeploymentsProvider =
    FutureProvider.family<List<Deployment>, String>((ref, uuid) {
      return ref.watch(apiProvider).appDeployments(uuid);
    });