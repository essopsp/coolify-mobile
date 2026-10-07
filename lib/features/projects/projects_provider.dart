import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/resource.dart';
import '../../core/models/tag.dart';
import '../../core/providers.dart';

final projectsProvider = FutureProvider<List<Project>>((ref) {
  return ref.watch(apiProvider).projects();
});

/// Single-project fetcher keyed by uuid.
final projectProvider = FutureProvider.family<Project, String>((ref, uuid) {
  return ref.watch(apiProvider).project(uuid);
});

final projectResourcesProvider =
    FutureProvider.family<List<Resource>, ({String project, String? environment})>(
      (ref, args) async {
        return ref.watch(apiProvider).resources(
          projectUuid: args.project,
          environmentUuid: args.environment,
        );
      },
    );

final tagsProvider = FutureProvider<List<Tag>>((ref) {
  return ref.watch(apiProvider).tags();
});

final resourceTagsProvider =
    FutureProvider.family<List<Tag>, ({String resource, String uuid})>(
      (ref, args) =>
          ref.watch(apiProvider).resourceTags(args.resource, args.uuid),
    );