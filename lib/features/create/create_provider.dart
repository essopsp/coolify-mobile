import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/github_app.dart';
import '../../core/providers.dart';

final githubAppsProvider = FutureProvider<List<GithubApp>>((ref) {
  return ref.watch(apiProvider).githubApps();
});

final githubReposProvider =
    FutureProvider.family<List<GithubRepository>, String>((ref, appUuid) {
  return ref.watch(apiProvider).githubRepositories(appUuid);
});

final githubBranchesProvider = FutureProvider.family<
    List<GithubBranch>,
    ({String appUuid, String owner, String repo})>((ref, args) {
  return ref
      .watch(apiProvider)
      .githubBranches(args.appUuid, args.owner, args.repo);
});