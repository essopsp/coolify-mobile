# Coolify Mobile

A Flutter client for managing [Coolify](https://coolify.io) instances — open-source, self-hosted PaaS — from your Android device.

Manage multiple Coolify instances and their resources from a single dashboard: applications, deployments, databases, services, servers, projects, tags, scheduled tasks, backups, and audit logs. Tokens are stored in encrypted platform secure storage (never on disk in plaintext).

## Features

- **Multi-instance** — save several Coolify connections, switch between them from the dashboard drawer
- **Dashboard** — resource counts, live open deployments, per-status breakdown
- **Applications** — deploy (quick / force rebuild), cancel, start / stop / restart, environment variables (names only), live container logs, scheduled tasks, PR previews
- **Deployments** — live deployment feed with per-deployment status and failure reasoning
- **Databases** — start / stop / restart, env keys, logs, backup schedules (add / run / delete) with execution history
- **Services** — container stack overview, per-service app / database components, env keys, logs
- **Servers** — reachability, resource inventory, hosted domains, proxy validation / restart, Docker cleanup
- **Projects & Environments** — browse resources grouped by project and environment
- **Tags** — tag metadata and the resources attached to each tag
- **Settings & Audit** — team info, live audit event feed

> Note: certain endpoints (logs, scheduled task bodies, backup execution messages) require a Coolify API token with the `read:sensitive` ability.

## Requirements

- Flutter 3.47+ (Dart 3.13+)
- Android SDK 24+ (Android 7.0+)
- A Coolify instance with the **API enabled** (`https://your-instance` → Settings → API). Self-hosted instances must enable API access and allow your IP.

## Getting started

```bash
flutter pub get
flutter run
```

### Creating a Coolify API token

1. Log in to your Coolify instance
2. Go to **Settings → API Tokens**
3. Create a token (grant `read`, `write`, and `read:sensitive` if you want logs / task bodies)
4. In the app, add an instance with your instance URL and the token

## Building a release APK

```bash
flutter build apk --release
# output: build/app/outputs/flutter-apk/app-release.apk
```

The Flutter template builds release APKs with the **debug signing key** by default. For distribution, configure your own signing key in `android/app/build.gradle.kts` — see the [Flutter signing docs](https://docs.flutter.dev/deployment/android#signing-the-app).

## Architecture

```
lib/
├── core/
│   ├── api/            # Dio API client, Coolify REST facade, exceptions
│   ├── models/         # Tolerant JSON models (applications, deployments, ...)
│   ├── utils/          # JSON coercion helpers, status parsing
│   ├── stores/         # Secure instance storage (flutter_secure_storage)
│   ├── providers/      # Riverpod providers (instances, active instance, audit)
│   ├── router.dart     # go_router routes
│   └── theme.dart
├── features/
│   ├── instances/      # Connection management
│   ├── dashboard/      # Overview + open deployments
│   ├── resources/      # Resource list, cards, deployment dialog
│   ├── applications/   # Detail screen: overview/env/logs/tasks tabs
│   ├── deployments/    # Live deployments + deployment detail
│   ├── databases/      # Detail screen incl. backup schedules
│   ├── services/       # Multi-container stacks
│   ├── servers/        # Server inventory & maintenance
│   ├── projects/       # Projects & environments
│   ├── tags/           # Tag browsing
│   └── settings/       # Team info & audit log
└── widgets/            # Shared async view / status chip / confirmation
```

- **State**: `flutter_riverpod` (Riverpod 3)
- **Networking**: `dio`, base URL `{instance}/api/v1`, Bearer token auth
- **Storage**: `flutter_secure_storage` — instance URLs and tokens never touch plaintext disk
- **Models**: hand-written, tolerant JSON parsers (unknown/extra keys are ignored), so the app survives Coolify's frequent API shape changes

## Testing

```bash
flutter test
flutter analyze
```

## Contributing

Contributions are welcome. Open an issue or a PR:

1. Fork the repo
2. Create a feature branch (`git checkout -b feat/your-feature`)
3. Make your changes — keep `flutter analyze` clean and tests green
4. Open a pull request

## Disclaimer

This is an independent, community client and is not affiliated with or endorsed by Coolify.

## License

MIT — see [LICENSE](LICENSE).