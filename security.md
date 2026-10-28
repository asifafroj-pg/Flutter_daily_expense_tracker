# Security

Parafleet handles a vendor's commercial data: rates, bills, claims, contacts and
vehicles. Treat all of it as sensitive. **The server is the source of truth for
authentication and authorisation — the app only reflects it.**

## Contents

1. [Secrets & configuration](#1-secrets--configuration)
2. [Authentication & session](#2-authentication--session)
3. [Token storage](#3-token-storage)
4. [Network security](#4-network-security)
5. [Authorisation & permissions](#5-authorisation--permissions)
6. [Data privacy & PII](#6-data-privacy--pii)
7. [Deep links & push](#7-deep-links--push)
8. [Dependencies & supply chain](#8-dependencies--supply-chain)
9. [Release hardening](#9-release-hardening)
10. [Incident response](#10-incident-response)

---

## 1. Secrets & configuration

- **Never commit secrets** (keys, tokens, passwords, signing material). Not in
  `config/*.json`, not in code, not in the README.
- Base URLs are config, not secrets, and come from `--dart-define` (see
  [`api-integration.md`](api-integration.md) §1).
- Signing keystores live outside the repo; reference them via env vars /
  `key.properties` that is git-ignored.
- `.gitignore` must exclude `*.keystore`, `*.jks`, `key.properties`, `config/*.local.json`,
  `.env*`.

## 2. Authentication & session

- Authenticate against the TMS API; store the returned token + refresh token in
  **secure storage only**.
- **Session restore validates with the server** (`/api/v1/me`). Never fabricate a
  user or permissions from local storage — a tampered local value must not grant
  access.
- On **401**: clear storage + in-memory auth state + cache, reset `AuthBloc`, and
  redirect to `/login`. Never keep a resident token after a failed validation.
- Logout clears **everything**: memory, secure storage, cache, FCM token. If the
  remote logout call fails, still clear locally.
- No "remember me" that stores the password. Ever.

## 3. Token storage

- Use `flutter_secure_storage` (Keystore/Keychain). Never `SharedPreferences`,
  never plain files.
- Never log the token or include it in crash reports/analytics.
- Ideally configure secure storage to require unlocked device (`firstUnlock`
  policy) for the token key.

## 4. Network security

- **HTTPS only** in staging/prod. Ship a network-security-config that **disallows
  cleartext** in release (`android:usesCleartextTraffic="false"`).
- **Never** disable certificate validation or add a trust-all `badCertificate`
  callback — not even "temporarily".
- **Never log request/response bodies** (passwords, OTPs, addresses, licence
  numbers). The logger interceptor logs method + path + status only, and is
  disabled in prod (`ENABLE_LOGGING=false`).
- Strip `Authorization` from any error/log output. Log the server `requestId`
  for tracing — it is not sensitive.
- Timeouts are enforced; a hung request must fail, not spin forever.

## 5. Authorisation & permissions

- **Client-side gating is cosmetic; the server enforces.** Hide actions the user
  cannot perform (permissions from the API `x-tms.permissions`), but never treat
  a hidden button as a security boundary.
- Absent/unknown permission ⇒ **deny** (forbidden). Never default to allowed.
- Guard **deep links and push targets** by permission — a push must not open a
  screen the user cannot access.
- Handle `403 FORBIDDEN` as a distinct, honest state ("You don't have access"),
  not a generic error.

## 6. Data privacy & PII

- Minimise: cache only what a screen needs, and **only** for offline-opted-in
  features. Default is no persistent cache.
- Clear all caches on login **and** logout, awaited before the first authenticated
  screen renders — no data leaks between sessions/users.
- Consider `FLAG_SECURE` / screenshot blocking on the most sensitive screens
  (e.g. documents with personal data) — confirm with product first.
- Redact PII in analytics/crash reporting (no names, phone numbers, plate
  numbers, addresses, tokens).

## 7. Deep links & push

- Validate every incoming deep link: is the user authenticated? permitted? does
  the target exist? Unknown/unauthorised targets fall back to a safe screen.
- Route targets are **`AppPages` constants**, opened only through
  **`NavigationService`**, and only after the auth/permission check (the router
  `redirect` enforces the auth gate — see [`navigation.md`](navigation.md)).
- Never trust data in a push payload as authoritative — refetch from the API.
- Don't echo unsanitised push content into UI or navigation without validation.

## 8. Dependencies & supply chain

- Keep dependencies minimal (fewer deps = fewer CVEs). Each new dep is reviewed.
- Run a vulnerability scan in CI (`dart pub outdated`, `osv-scanner`/`dart pub
  global run` equivalents, or `flutter pub deps` review) and act on advisories.
- Pin versions; review changelogs before major upgrades.
- Don't add a package that duplicates existing capability.

## 9. Release hardening

- Build release with **obfuscation + symbol files**:
  ```bash
  flutter build appbundle --release \
    --obfuscate --split-debug-info=build/symbols
  ```
  Store symbol files to de-obfuscate crashes — outside the repo.
- Android: enable R8/minify, keep rules only where required (serialization,
  secure storage). Remove `android:debuggable`.
- No `print`/`debugPrint` of sensitive data; use `AppLogger` gated by
  `AppConfig.enableLogging` and strip verbose logs in prod.
- Remove unused permissions from the manifest. Justify every permission.
- Don't ship the dev flavor's config; verify `API_BASE_URL` points to prod.
- Verify `android:usesCleartextTraffic="false"` and the release signing config.

## 10. Incident response

If a token or secret is suspected leaked:

1. Revoke the token/secret server-side **first**.
2. Force-logout affected users (bump a token version / invalidate sessions).
3. Remove the secret from history (rotate), then from the repo.
4. Add a guard (test/lint/CI check) that would have caught it.
