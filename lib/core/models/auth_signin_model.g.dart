// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_signin_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthSigninModel _$AuthSigninModelFromJson(Map<String, dynamic> json) =>
    AuthSigninModel(
      email: json['email'] as String,
      password: json['password'] as String,
      rememberMe: json['rememberMe'] as bool? ?? false,
    );

Map<String, dynamic> _$AuthSigninModelToJson(AuthSigninModel instance) =>
    <String, dynamic>{
      'email': instance.email,
      'password': instance.password,
      'rememberMe': instance.rememberMe,
    };

AuthSigninResponse _$AuthSigninResponseFromJson(Map<String, dynamic> json) =>
    AuthSigninResponse(
      id: json['id'] as String,
      email: json['email'] as String,
      phoneNumber: json['phone_number'] as String,
      isOwner: json['is_owner'] as bool,
      fullName: json['full_name'] as String,
      token: json['token'] as String,
      refreshToken: json['refresh_token'] as String,
    );

Map<String, dynamic> _$AuthSigninResponseToJson(AuthSigninResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'phone_number': instance.phoneNumber,
      'is_owner': instance.isOwner,
      'full_name': instance.fullName,
      'token': instance.token,
      'refresh_token': instance.refreshToken,
    };
