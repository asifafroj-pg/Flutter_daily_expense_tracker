import 'package:equatable/equatable.dart';

import '../../../../app/core/utils/data_parser.dart';
import '../../domain/entities/user_entity.dart';

/// Data-layer representation of a user account.
///
/// Parsing always goes through [safeParse] (coding-style.md §4) so a malformed
/// payload can never crash the app.
class UserModel extends Equatable {
  const UserModel({required this.id, required this.email, this.name});

  /// Builds a [UserModel] from a decoded JSON map.
  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: safeParse(() => json['id'] as String),
        email: safeParse(() => json['email'] as String) ?? '',
        name: safeParse(() => json['name'] as String?),
      );

  final String id;
  final String email;
  final String? name;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'email': email,
        'name': name,
      };

  UserEntity toEntity() => UserEntity(id: id, email: email, name: name);

  @override
  List<Object?> get props => <Object?>[id, email, name];
}
