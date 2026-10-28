# Security

This product handles user data and auth state. Treat all data as sensitive and keep the server as the system of record for authentication and authorization.

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

---

## 1. Secrets & configuration

- Never commit secrets (keys, tokens, passwords, signing material).
- Keep config in environment files or secure configuration objects.
- Signing keys live outside the repo.

## 2. Authentication & session

- Authenticate using a server-driven login flow.
- Store session state securely and validate with the backend on restore.
- On `401`, clear storage, reset auth state, and redirect to login.
- No “remember me” that stores the raw password.

## 3. Token storage

- Use `flutter_secure_storage` or equivalent secure storage.
- Never log tokens or include them in crash reports.

## 4. Network security

- Use HTTPS in production.
- Disable cleartext traffic in release builds.
- Never disable certificate validation or add trust-all exceptions.
- Never log request or response bodies.

## 5. Authorisation & permissions

- The server enforces permissions; the client only hides unauthorized actions.
- Unknown or missing permissions should default to deny, not allow.
- Guard deep links and push targets by auth and permission.

## 6. Data privacy & PII

- Minimise what you cache.
- Clear caches on logout and session changes.
- Redact PII in analytics and crash reports.

## 7. Deep links & push

- Validate all incoming deep links.
- Ensure the user is authenticated and permitted before opening a target.
- Do not trust payloads blindly; refetch when needed.

## 8. Dependencies & supply chain

- Keep dependencies minimal.
- Run a vulnerability scan in CI.
- Pin versions and review changelogs for major upgrades.

## 9. Release hardening

- Build release with obfuscation + symbol files.
- Remove unused permissions.
- Verify config points to the correct environment.
- Don’t enable debug-only logging in production.
