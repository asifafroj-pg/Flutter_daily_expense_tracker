# Overview

## What this app is

This project is a Flutter application built for a product team that needs a maintainable, modular, production-ready foundation. The structure is generic enough to serve many app domains: commerce, logistics, finance, productivity, bookings, or service management.

| Thing | Value |
|-------|-------|
| Product name | Use your app name here |
| Owner | Product team / company |
| Primary audience | End users or internal teams |
| Backend | REST API, GraphQL, or app-specific service |
| Platform | Flutter — Android first, iOS and Web possible |
| Repo | Your project repo |

## The wider system (context)

The app is usually one part of a wider product ecosystem. It may talk to a backend, an admin panel, or an internal service. The important principle: the app should remain a client that gets the truth from the server and presents it clearly to users.

The client should not hold the system of record for business rules; the backend should stay authoritative for permissions, validation, identities, and business logic.

## Branding

Use your brand tokens here, for example:

| Token | Example value | Use |
|-------|---------------|-----|
| Primary | `#1E88E5` | Main actions, links, accents |
| Secondary | `#F59E0B` | Highlights and support states |
| Success | `#10B981` | Valid states and positive actions |
| Background | `#FAFAFA` | App background |
| Text primary | `#111827` | Main text |
| Text secondary | `#6B7280` | Secondary text |

Customize these values for your product. Design tokens live in [`ui-design.md`](ui-design.md).

## Domain glossary

| Term | Meaning |
|------|---------|
| **User** | Individual using the app |
| **Session** | Authenticated state for a user |
| **Entity** | Core business object used across the app |
| **Feature** | A business capability or user journey |
| **Screen** | A page or route in the app |
| **Use case** | One business action or read operation |
| **Module** | A grouped feature, such as auth, orders, profile |

## The API in one paragraph

The backend contract is defined by the API layer and should be versioned and documented. Authentication is usually bearer-token based. Errors should return a consistent shape, such as `{ success: false, code, message, details?, requestId }`.

## Scope

**In scope:** authentication, profile, product/business flows, data entry, dashboards, notifications, settings, integrations.

**Out of scope:** internal admin tooling or backend infrastructure that belongs to another system.

## Non-goals / decisions already made

- No state-management debates: BLoC/Cubit is the default pattern.
- No bespoke networking: Dio or a single client wrapper is preferred.
- Real-time is default for live views; offline is opt-in per feature.
- No secrets in the repo, ever.

## Read next

- How we structure code → [`architecture.md`](architecture.md)
- Where files go → [`project-structure.md`](project-structure.md)
- How to start coding → [`development.md`](development.md)
