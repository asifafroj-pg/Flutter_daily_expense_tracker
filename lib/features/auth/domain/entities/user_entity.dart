import 'package:equatable/equatable.dart';

/// Pure domain entity — no JSON, no Flutter imports (architecture.md).
class UserEntity extends Equatable {
  const UserEntity({required this.id, required this.email, this.name});

  final String id;
  final String email;
  final String? name;

  String get displayName => name?.trim().isNotEmpty == true ? name! : email;
}
