# Git Workflow

Trunk-based with short-lived branches. `main` is always releasable.

## Branches

| Branch | From | Purpose |
|--------|------|---------|
| `main` | — | Releasable. Protected; no direct pushes. |
| `feat/<ticket>-<slug>` | `main` | New feature (`feat/PAF-123-trip-list`) |
| `fix/<ticket>-<slug>` | `main` | Bug fix |
| `chore/<slug>` | `main` | Tooling, deps, docs |
| `release/<version>` | `main` | Optional hardening before a tagged release |

Rules: rebase on `main` before opening a PR; keep branches small (days, not
weeks); delete after merge.

## Commits — Conventional Commits

`<type>(<scope>): <summary>`

Types: `feat`, `fix`, `refactor`, `perf`, `test`, `docs`, `build`, `ci`, `chore`,
`style`. Scope = feature/folder (`trips`, `auth`, `core`, `docs`).

```
feat(trips): add live status polling to trip list
fix(auth): clear cache before rendering post-login screen
docs(architecture): standardise on BLoC
```

- Imperative mood, ≤ 72 chars, no trailing period.
- One logical change per commit. Reference the ticket in the body, not the
  subject.
- Never commit commented-out code, secrets, or `.env`/keystore files.

## Pull requests

Small, focused, self-reviewed first. The PR **must** include:

- **What & why** — the problem and the approach.
- **How to verify** — steps/screens for a reviewer (and the test that proves it).
- **Screenshots/recording** for any UI change.
- **Checklist** (auto-filled from [`definition-of-done.md`](definition-of-done.md)).
- **Risk** — migrations, permission changes, anything touching money/auth.

Merge only when: CI is green, ≥ 1 approval, no unresolved comments, branch
rebased. Prefer **squash merge** for a clean `main` history.

## Review guidelines

Reviewers check, in order:

1. **Correctness** — does it do what it says, incl. error/empty/offline paths?
2. **Architecture** — layers respected, no dependency-rule violations, DI via
   `sl<>`, bloc scoped correctly.
3. **Security** — no secrets/bodies logged, permissions respected, PII handled.
4. **Tests** — meaningful coverage of the risky paths, not just happy path.
5. **Naming & style** — follows the handbook; format/analyze clean.
6. **Scope** — nothing unrelated riding along.

## Versioning & releases

- `version: <major>.<minor>.<patch>+<build>` in `pubspec.yaml`
  (Flutter uses `versionName`/`versionCode` from it).
- SemVer: breaking UX/API contract → major; feature → minor; fix → patch.
  **Build number always increments** per store upload.
- Tag releases `v<version>` on `main`.
- Keep a `CHANGELOG.md` (Added / Changed / Fixed / Security) updated per
  user-facing change.

### Release checklist

1. `main` green; version + build number bumped.
2. `flutter analyze` clean, all tests pass, integration gate green.
3. Build prod flavor with obfuscation + symbols (see
   [`security.md`](security.md) §9).
4. Smoke-test the release artifact on a real device (login, one core journey).
5. Verify `API_BASE_URL` = prod and cleartext is disabled.
6. Tag, write release notes from the changelog, upload, archive symbols.

## Docs are part of the change

If you change a pattern (folder layout, state approach, an endpoint contract),
update the relevant doc under `docs/` **in the same PR**. The handbook must never
drift from the code.
