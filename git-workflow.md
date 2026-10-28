# Git Workflow

Trunk-based with short-lived branches. `main` is always releasable.

## Branches

| Branch | From | Purpose |
|--------|------|---------|
| `main` | — | Releasable. Protected; no direct pushes. |
| `feat/<ticket>-<slug>` | `main` | New feature |
| `fix/<ticket>-<slug>` | `main` | Bug fix |
| `chore/<slug>` | `main` | Tooling, deps, docs |
| `release/<version>` | `main` | Optional pre-release |

Rules: rebase on `main` before opening a PR; keep branches small; delete after merge.

## Commits — Conventional Commits

`<type>(<scope>): <summary>`

Types: `feat`, `fix`, `refactor`, `perf`, `test`, `docs`, `build`, `ci`, `chore`, `style`.

```bash
feat(auth): add login session restore
fix(ui): keep detail screen state after refresh
docs(architecture): standardise on BLoC
```

- Imperative mood, ≤ 72 chars, no trailing period.
- One logical change per commit.
- Never commit secrets or commented-out code.

## Pull requests

Small, focused, self-reviewed first. The PR should include:

- What & why
- How to verify
- Screenshots or recording for UI changes
- Checklist from the definition of done
- Risk / edge cases

Merge only when CI is green and review is complete.

## Review guidelines

1. Correctness
2. Architecture and layering
3. Security and privacy
4. Tests
5. Naming and style
6. Scope

## Versioning & releases

- `version: <major>.<minor>.<patch>+<build>` in `pubspec.yaml`
- SemVer: breaking change → major; feature → minor; fix → patch
- Tag releases `v<version>` on `main`
- Keep a changelog updated per user-facing change

## Docs are part of the change

If you change a pattern or API contract, update the relevant doc in the same PR.
