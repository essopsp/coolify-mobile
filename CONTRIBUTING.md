# Contributing to Coolify Mobile

Thanks for your interest! This project is open and community-driven.

## Getting started

1. Fork the repository
2. Clone your fork: `git clone git@github.com:<you>/coolify_app.git`
3. Install Flutter 3.47+ (see [README](README.md#requirements))
4. `flutter pub get`
5. Validate the baseline: `flutter analyze && flutter test`

## Development workflow

- Create a branch from `main`: `git checkout -b feat/your-feature` (or `fix/...`, `docs/...`)
- Make focused changes — one logical change per PR
- Keep `flutter analyze` at **zero issues** and add tests for new behavior
- Run `flutter test` before opening the PR
- Rebase onto latest `main` before finishing

## Testing Coolify API changes

The app talks to the Coolify REST API (`{instance}/api/v1`). Model parsing is deliberately tolerant: unknown or missing JSON keys must never crash a screen. When you change a model, add a `fromJson` test with the real-world response shape.

## Pull request checklist

- [ ] `flutter analyze` clean
- [ ] `flutter test` green
- [ ] No secrets, tokens, or personal instance URLs in code, tests, or commits
- [ ] If models changed, tolerant JSON parsing preserved + tests updated

### Security — please read

This is a **public** repository. Never commit:

- Coolify API tokens (even expired ones)
- Real instance URLs, IPs, or hostnames
- `.env`-style files, keystores, or private keys

Anything matching these will be treated as a security issue and blocked.

## Issues

Bug reports are great — include the Coolify version, app version, and the exact screen/action that failed. Feature requests are welcome as discussion.

## License

By contributing you agree that your contributions are licensed under the [MIT License](LICENSE).