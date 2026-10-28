# Coding Style & Best Practices

The small daily decisions that compound into a maintainable codebase. Applies to every Dart file.

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
| File / folder | `snake_case` | `item_repository_impl.dart` |
| Class / enum / mixin | `PascalCase` | `ItemRepositoryImpl` |
| Variable / function | `camelCase` | `fetchItems` |
| Constant | `lowerCamelCase` | `defaultPageSize` |
| Bloc | `<Subject>Bloc` | `ItemListBloc` |
| Cubit | `<Subject>Cubit` | `FilterCubit` |
| Event | `<Verb><Subject>Event` | `LoadItemsEvent` |
| State | `<Subject><Phase>` | `ItemLoaded`, `ItemError` |
| Use case | `<Verb><Subject>UseCase` | `GetItemsUseCase` |
| Repository impl | `<Subject>RepositoryImpl` | `ItemRepositoryImpl` |
| Repository contract | `<Subject>Repository` | `ItemRepository` |
| DTO model | `<Subject>Model` | `ItemModel` |
| Entity | `<Subject>Entity` | `ItemEntity` |
| Route registry | `AppPages` | — |

## 2. Immutability

Widgets, entities, and states are immutable.

- **Widgets**: mark `const` wherever possible.
- **Entities**: `final` fields only, `extends Equatable`, changes via `copyWith`.
- **States**: `const` constructor + `copyWith`.

## 3. `const` usage

- Mark a widget constructor `const` if all fields are `final` and set via the constructor.
- Prefer `const` subtrees.
- Prefer `const []` / `const {}` for literal collections.

## 4. Comments

- `///` doc comments on every public API.
- `//` only for non-obvious implementation detail.

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

Gates: `dart format --set-exit-if-changed .` and `flutter analyze` → 0 issues.

## 6. Domain purity & equality

- `domain/` imports only `dart:*`, `equatable`, `dartz` — no Flutter, Dio, Hive, bloc, or get_it.
- Every entity extends `Equatable` and lists fields in `props`.
- Never put a raw `Map<String, dynamic>` in `props`.

## 7. `safeParse` — the only JSON parser

One shared helper at `app/core/utils/data_parser.dart` should be used for all JSON casting.

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
```

Usage:

```dart
factory ItemModel.fromJson(Map<String, dynamic> json) => ItemModel(
  id: safeParse<String>(json['id'], 'id') ?? '',
  quantity: safeParse<int>(json['quantity'], 'quantity') ?? 0,
  price: safeParse<double>(json['price'], 'price') ?? 0,
  notes: safeParse<String>(json['notes'], 'notes'),
);
```

Never use `(x as T)` after a null check without proper validation.

## 8. Entities vs Models

- **Entities** (`domain/entities`) — pure Dart, `Equatable`, no JSON knowledge.
- **Models** (`data/models`) — DTOs that extend their entity and own (de)serialization.

## 9. Error handling — Failures & Exceptions

`app/core/error/failures.dart` — what the UI receives.

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
```

`app/core/error/exceptions.dart` — internal to the Data layer.

**Rule:** data sources throw exceptions; repositories catch them and return `Left(Failure)`. The UI never sees a raw exception.

## 10. Logger interceptor — never log bodies

```dart
class LoggerInterceptor extends Interceptor {
  LoggerInterceptor({required bool isDebug}) : _isDebug = isDebug;
  final bool _isDebug;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_isDebug) debugPrint('--> ${options.method} ${options.uri}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (_isDebug) debugPrint('<-- ${response.statusCode} ${response.requestOptions.uri}');
    handler.next(response);
  }
}
```

Never log request or response bodies.

## 11. Trailing commas & file length

- Trailing commas in every multi-line collection / argument list.
- A file over ~300 lines is a smell — split it.
- Screen files have a hard limit of 120 lines, and large visual blocks should be extracted into widgets.
