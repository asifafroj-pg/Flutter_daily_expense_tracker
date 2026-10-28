# Overview — Parafleet

## What this app is

**Parafleet** is the mobile companion for **Paragon Vendor Fleet Management**,
built for **vendors** in the Paragon Group transport network. Vendors use it to
run their side of the fleet operation: trips and deliveries, vehicles and
drivers, documents, tenders & quotations, rates, bills, claims, performance and
their account.

| Thing | Value |
|-------|-------|
| Product (short name) | **Parafleet** |
| Product (full name) | **Paragon Vendor Fleet Management** |
| Owner | **Paragon Group** ("A Concern of Paragon Group") |
| Primary audience | **Vendors only** — one tenant type. Within a vendor, users may carry roles (e.g. admin/user) and granular permissions. |
| Backend | **TMS API** (Transport Management System), Bearer-token auth |
| Platform | Flutter — Android primary; iOS/Web later |
| Repo | `pg_vendor` |

## The wider system (context)

The same TMS backend serves three clients:

1. **Paragon admin web** — internal operations (planning, dispatch, billing).
2. **Paragon mobile** — internal users.
3. **Parafleet (this app)** — vendors.

This app is the **vendor client only**. It does not implement internal Paragon
flows and does not serve other audiences (there is no rider/hub mode). Within a
vendor, individual users may have different roles and permissions, so the UI
gates actions by the authenticated user's permissions — but the audience is
always a vendor.

Everything the vendor sees is scoped by the API by the authenticated vendor +
the user's permissions. **The server is the source of truth** for roles and
permissions; the app may only *hide* what the vendor cannot do — never rely on
client-side gating for security.

## Branding

| Token | Value | Use |
|-------|-------|-----|
| Navy | `#0F1B33` | Headlines, app bars, dark surfaces |
| Blue | `#1E88E5` | Primary accent, links, actions |
| Orange | `#F5A623` | Secondary accent (highlight/sparingly) |
| Green | `#10B981` | Success / online status |
| Background | `#FAFAFA` | App background (matches the icon) |
| Full name | `Paragon Vendor Fleet Management` | Splash, About, store listing |
| Short name | `Parafleet` | Launcher label, app bar, in-app preview |

Assets: `assets/icons/icon.png` (brand lockup). Design tokens live in
[`ui-design.md`](ui-design.md).

## Domain glossary

| Term | Meaning |
|------|---------|
| **Vendor** | A transport company contracted by Paragon. The tenant of this app. |
| **Vehicle** | A truck/vehicle owned or managed by the vendor; has registration & type. |
| **Driver** | A person who operates a vehicle; has licence details. |
| **Requisition** | An internal Paragon request for transport (pickup → delivery, quantity, unit). |
| **Tender** | A published request the vendor bids on. |
| **Quotation** | The vendor's priced bid on a tender. |
| **Vendor selection** | Paragon's decision picking a quotation. |
| **Work order / Dispatch** | The authoritative instruction to move goods, with ERP sync. |
| **Trip** | The actual execution: reporting, loading, delivery, completion. |
| **Rate** | Agreed price/basis (e.g. `PER_TRIP`) for a lane or tender. |
| **Bill** | The vendor's invoice to Paragon, generated from completed trips. |
| **Claim** | A charge the vendor raises (e.g. detention, damage). |
| **Gate** | Depot/gate check-in & check-out events. |
| **Weighbridge** | Weight capture (loaded/tare/net). |
| **BRTA** | Bangladesh Road Transport Authority (vehicle regulatory data). |

## The API in one paragraph

Base URL is configured per environment (see [`api-integration.md`](api-integration.md)).
All endpoints are versioned under `/api/v1`. Auth is a **Bearer token**. Errors
return a consistent envelope: `{ success: false, code, message, details?,
requestId }`. The generated OpenAPI spec lives at the repo root in
`response.md` (relocate to `docs/api/openapi.md` when convenient) and is the
authoritative contract — **never hand-write an endpoint that contradicts it.**

## Scope

**In scope (this app):** vendor account & users/roles, fleet (vehicles,
drivers, documents), operations participation (tenders, quotations, rates),
execution (assignments, trips, delivery, gate/weighbridge where vendor-facing),
finance (bills, claims), performance, notifications, profile.

**Out of scope (this app):** Paragon-internal admin flows (planning, dispatch
approval, ERP integration management) — those live in the admin web.

## Non-goals / decisions already made

- **No state-management debates.** BLoC/Cubit is chosen. See
  [`architecture.md`](architecture.md).
- **No bespoke networking.** Dio + a single `DioClient` with interceptors.
- **Real-time is the default.** Live state via push + polling/streams +
  optimistic updates. **Offline is opt-in per feature**, not a global
  requirement — this app is used on the road and in depots and must stay current.
- **No secrets in the repo**, ever.

## Read next

- How we structure code → [`architecture.md`](architecture.md)
- Where files go → [`project-structure.md`](project-structure.md)
- How to start coding → [`development.md`](development.md)
