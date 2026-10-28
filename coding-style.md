# Coding Style & Best Practices

The small daily decisions that compound into a maintainable codebase. Applies to
**every** Dart file. Naming and layering are also summarised in
[`architecture.md`](architecture.md); this doc is the detailed standard.

## Contents

1. [Naming](#1-naming)
2. [Immutability](#2-immutability)
3. [`const` usage](#3-const-usage)
4. [Comments](#4-comments)
5. [Linting & formatting](#5-linting--formatting)
6. [Domain purity & equality](#6-domain-purity--equality)
7. [`safeParse` — the only JSON parser](#7-safeparse--the-only-json-parser)
8. [Entities vs Models](#8-entities-vs-models)
9. [Error handling — Failures & Exceptions](#9-error-handling--failures--exceptions)
10. [Logger interceptor — never log bodies](#10-logger-interceptor--never-log-bodies)
11. [Trailing commas & file length](#11-trailing-commas--file-length)

---

## 1. Naming

| Type | Convention | Example |
|------|-----------|---------|
| File / folder | `snake_case` | `trip_repository_impl.dart` |
| Class / enum / mixin | `PascalCase` | `TripRepositoryImpl` |
| Variable / function | `camelCase` | `fetchTrips` |
| Constant | `lowerCamelCase` | `defaultPageSize` |
| Enum value | `lowerCamelCase` | `TripStatus.inProgress` |
| Bloc | `<Subject>Bloc` | `TripListBloc` |
| Cubit | `<Subject>Cubit` | `TripFilterCubit` |
| Event | `<Verb><Subject>Event` | `LoadTripsEvent` |
| State | `<Subject><Phase>` | `TripLoaded`, `TripError` |
| Use case | `<Verb><Subject>UseCase` | `GetTripsUseCase` |
| Repository impl | `<Subject>RepositoryImpl` | `TripRepositoryImpl` |
| Repository contract | `<Subject>Repository` | `TripRepository` |
| DTO model | `<Subject>Model` | `TripModel` |
| Entity | `<Subject>Entity` | `TripEntity` |
| Route registry | `AppPages` | — |

Feature folders are `snake_case`; plural for collections (`trips`, `vehicles`),
singular for single-resource (`auth`, `profile`).

## 2. Immutability

Widgets, entities and states are immutable.

- **Widgets**: mark `const` wherever the compiler allows.
- **Entities**: `final` fields only, `extends Equatable`, changes via `copyWith`.
- **States**: `const` constructor + `copyWith`. The `error` field is intentionally
  **not preserved** across `copyWith` (forces explicit set/clear; prevents stale
  error banners).

```dart
class TripEntity extends Equatable {
  final String id;
  final TripStatus status;
  final int quantity;

  const TripEntity({required this.id, required this.status, required this.quantity});

  TripEntity copyWith({String? id, TripStatus? status, int? quantity}) => TripEntity(
        id: id ?? this.id,
        status: status ?? this.status,
        quantity: quantity ?? this.quantity,
      );

  @override
  List<Object?> get props => [id, status, quantity];
}
```

## 3. `const` usage

- Mark a widget constructor `const` if all fields are `final` and set via the
  constructor.
- Prefer `const` subtrees: `const SizedBox(height: 8)` over `SizedBox(height: 8)`.
- Prefer `const []` / `const {}` for literal collections so the parent stays
  `const`.

## 4. Comments

- `///` doc comments on **every public API** — what it does, parameters, return.
- `//` only for non-obvious implementation detail — never restate the code.

```dart
/// Loads a page of trips, caches the result, and falls back to stale cache on
/// network error.
///
/// [page] is 1-indexed. [refresh] bypasses cache and forces a remote fetch.
Future<Either<Failure, List<TripEntity>>> getTrips({int page = 1, bool refresh = false}) async {
  if (refresh) await _local.delete(_cacheKey(page)); // explicit fresh fetch
  // ...
}
```

## 5. Linting & formatting

`analysis_options.yaml`:

```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    public_member_api_docs: true
    prefer_const_constructors: true
    prefer_const_literals_to_create_immutables: true
    avoid_dynamic_calls: true
    require_trailing_commas: true
    always_declare_return_types: true
```

Gates: `dart format --set-exit-if-changed .` and **`flutter analyze` → 0 issues**
(not merely 0 errors).

## 6. Domain purity & equality

- `domain/` imports only `dart:*`, `equatable`, `dartz` — **no** Flutter, Dio,
  Hive, bloc, get_it.
- Every entity extends `Equatable` and lists fields in `props`.
- **Never** put a raw `Map<String, dynamic>` in `props` — maps compare by
  reference and break equality.

## 7. `safeParse` — the only JSON parser

One shared helper at `app/core/utils/data_parser.dart` — never copy-pasted.

```dart
T? safeParse<T>(dynamic value, String fieldName, {T? defaultValue}) {
  if (value == null) return defaultValue;
  if (value is T) return value;
  if (T == String) return value.toString() as T;
  if (T == int) {
    if (value is int) return value as T;
    if (value is double) return value.toInt() as T;
    if (value is String) return int.tryParse(value) as T? ?? defaultValue;
  }
  if (T == double) {
    if (value is double) return value as T;
    if (value is int) return value.toDouble() as T;
    if (value is String) return double.tryParse(value) as T? ?? defaultValue;
  }
  if (T == bool) {
    if (value is bool) return value as T;
    if (value is String) return (value == 'true' || value == '1') as T;
    if (value is int) return (value != 0) as T;
  }
  return defaultValue;
}

// Tiny convenience aliases, same file
int? n(dynamic v, [int? d]) => safeParse<int>(v, '', defaultValue: d);
double? d(dynamic v, [double? d]) => safeParse<double>(v, '', defaultValue: d);
String? s(dynamic v, [String? d]) => safeParse<String>(v, '', defaultValue: d);
bool? b(dynamic v, [bool? d]) => safeParse<bool>(v, '', defaultValue: d);
```

Usage:

```dart
factory TripModel.fromJson(Map<String, dynamic> json) => TripModel(
      id: safeParse<String>(json['id'], 'id') ?? '',
      quantity: safeParse<int>(json['quantity'], 'quantity') ?? 0,
      rate: safeParse<double>(json['rate'], 'rate') ?? 0,
      notes: safeParse<String>(json['notes'], 'notes'),
    );
```

**Never** `(x as T)` after an emptiness check — wrong types throw at runtime.
The TMS API also returns numbers as strings; `safeParse<double>` handles that
(see [`api-integration.md`](api-integration.md) §7).

## 8. Entities vs Models

- **Entities** (`domain/entities`) — pure Dart, `Equatable`, no JSON knowledge.
- **Models** (`data/models`) — DTOs that **extend** their entity and own
  (de)serialization via `safeParse`.

```dart
// domain/entities/trip_entity.dart
class TripEntity extends Equatable {
  final String id;
  final TripStatus status;
  const TripEntity({required this.id, required this.status});
  @override
  List<Object?> get props => [id, status];
}

// data/models/trip_model.dart
class TripModel extends TripEntity {
  final String? remarks;
  const TripModel({required super.id, required super.status, this.remarks});

  factory TripModel.fromJson(Map<String, dynamic> json) => TripModel(
        id: safeParse<String>(json['id'], 'id') ?? '',
        status: TripStatus.fromValue(safeParse<String>(json['status'], 'status')),
        remarks: safeParse<String>(json['remarks'], 'remarks'),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'status': status.value,
        if (remarks != null) 'remarks': remarks,
      };

  TripEntity toEntity() => TripEntity(id: id, status: status);
}
```

## 9. Error handling — Failures & Exceptions

`app/core/error/failures.dart` — what the UI receives (all `Equatable`):

```dart
abstract class Failure extends Equatable {
  const Failure(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, {this.statusCode});
  final int? statusCode;
  @override
  List<Object?> get props => [message, statusCode];
}

class NetworkFailure extends Failure {
  const NetworkFailure([String? message]) : super(message ?? 'No internet connection');
}
class CacheFailure extends Failure {
  const CacheFailure([String? message]) : super(message ?? 'Cache error');
}
class AuthFailure extends Failure {
  const AuthFailure([String? message]) : super(message ?? 'Authentication failed');
}
class ForbiddenFailure extends Failure {
  const ForbiddenFailure([String? message]) : super(message ?? 'You do not have access');
}
class NotFoundFailure extends Failure {
  const NotFoundFailure([String? message]) : super(message ?? 'Not found');
}
class ConflictFailure extends Failure {
  const ConflictFailure(super.message);
}
class ValidationFailure extends Failure {
  const ValidationFailure(this.fieldErrors) : super('Validation failed');
  final Map<String, String> fieldErrors;
  @override
  List<Object?> get props => [message, fieldErrors];
}
```

`app/core/error/exceptions.dart` — internal to the **Data** layer:

```dart
class ServerException implements Exception {
  ServerException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
}
class NetworkException implements Exception {
  NetworkException([this.message = 'No internet connection']);
  final String message;
}
class CacheException implements Exception {
  CacheException([this.message = 'Cache error']);
  final String message;
}
class AuthException implements Exception {
  AuthException([this.message = 'Authentication failed']);
  final String message;
}
```

**Rule:** data sources **throw** exceptions; repositories **catch** them and
return `Left(Failure)`. Each layer maps its own exception to its own failure —
never mix, never let a raw exception reach the UI. Mapping table and the
repository pattern: [`api-integration.md`](api-integration.md) §4 and
[`architecture.md`](architecture.md) §5.

## 10. Logger interceptor — never log bodies

```dart
class LoggerInterceptor extends Interceptor {
  LoggerInterceptor({required bool isDebug}) : _isDebug = isDebug;
  final bool _isDebug;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_isDebug) debugPrint('--> ${options.method} ${options.uri}');
    // ★ NEVER log the request body — passwords, OTPs, addresses, PII
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (_isDebug) debugPrint('<-- ${response.statusCode} ${response.requestOptions.uri}');
    // ★ NEVER log the response body
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (_isDebug) debugPrint('<-- ERROR ${err.requestOptions.uri} ${err.message}');
    handler.next(err);
  }
}
```

See [`security.md`](security.md) §4.

## 11. Trailing commas & file length

- **Trailing commas** in every multi-line collection / argument list — cleaner
  `dart format` diffs, reorderable without churn.
- **File length**: a file over ~300 lines is a smell — split it. Exceptions
  (generated code, large sealed-state files) should be rare and intentional.
  **Screen files have a hard limit of 120 lines** — extract blocks into public
  widgets (see [`ui-design.md`](ui-design.md) §9).
