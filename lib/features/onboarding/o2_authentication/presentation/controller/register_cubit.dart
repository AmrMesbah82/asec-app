/// Module: onboarding / o2_authentication
///
///*************************** FILE INFO ****************************///
/// File Name: register_cubit.dart
/// Purpose: Declares `RegisterCubit` and `RegisterState` — creating a member
///          account.
/// Author: ASEC team
/// Created: 19/9/2026

import 'package:dartz/dartz.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_storage/get_storage.dart';

import 'package:asec/core/constants/app_keys.dart';
import 'package:asec/core/network/app_firebase.dart';
import 'package:asec/features/onboarding/o2_authentication/data/repository/auth_repository.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/base_repository/auth_base_repository.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/entities/app_user.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/enums/auth_failure_type.dart';
import 'package:asec/features/onboarding/o2_authentication/presentation/controller/auth_field_error.dart';

enum RegisterStatus { idle, submitting, success, failure }

class RegisterState {
  final RegisterStatus status;
  final AuthFailureType? failure;
  final AuthFieldError? nameError;
  final AuthFieldError? emailError;
  final AuthFieldError? passwordError;
  final AuthFieldError? confirmError;
  final bool obscure;
  final AppUser? user;

  const RegisterState({
    this.status = RegisterStatus.idle,
    this.failure,
    this.nameError,
    this.emailError,
    this.passwordError,
    this.confirmError,
    this.obscure = true,
    this.user,
  });

  bool get isSubmitting => status == RegisterStatus.submitting;

  RegisterState copyWith({
    RegisterStatus? status,
    AuthFailureType? failure,
    AuthFieldError? nameError,
    AuthFieldError? emailError,
    AuthFieldError? passwordError,
    AuthFieldError? confirmError,
    bool? obscure,
    AppUser? user,
    bool clearErrors = false,
  }) {
    return RegisterState(
      status: status ?? this.status,
      failure: clearErrors ? null : (failure ?? this.failure),
      nameError: clearErrors ? null : (nameError ?? this.nameError),
      emailError: clearErrors ? null : (emailError ?? this.emailError),
      passwordError: clearErrors ? null : (passwordError ?? this.passwordError),
      confirmError: clearErrors ? null : (confirmError ?? this.confirmError),
      obscure: obscure ?? this.obscure,
      user: user ?? this.user,
    );
  }
}

class RegisterCubit extends Cubit<RegisterState> {
  RegisterCubit({AuthBaseRepository? repository})
      : _repository = repository ?? AuthRepository(),
        super(const RegisterState());

  final AuthBaseRepository _repository;
  final GetStorage _storage = GetStorage();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();

  bool get firebaseMissing => AppFirebase.notConfigured;

  void toggleObscure() => emit(state.copyWith(obscure: !state.obscure));

  void clearErrors() => emit(state.copyWith(clearErrors: true));

  bool _validate() {
    final AuthFieldError? nameError =
        AuthFieldError.forName(nameController.text);
    final AuthFieldError? emailError =
        AuthFieldError.forEmail(emailController.text);
    final AuthFieldError? passwordError =
        AuthFieldError.forNewPassword(passwordController.text);
    // Only worth complaining about once the password itself is acceptable.
    final AuthFieldError? confirmError = passwordError == null &&
            confirmController.text != passwordController.text
        ? AuthFieldError.passwordsDiffer
        : null;

    emit(RegisterState(
      status: RegisterStatus.idle,
      nameError: nameError,
      emailError: emailError,
      passwordError: passwordError,
      confirmError: confirmError,
      obscure: state.obscure,
    ));
    return nameError == null &&
        emailError == null &&
        passwordError == null &&
        confirmError == null;
  }

  Future<void> submit() async {
    if (state.isSubmitting || !_validate()) return;
    emit(state.copyWith(status: RegisterStatus.submitting, clearErrors: true));

    final Either<AuthFailureType, AppUser> result = await _repository.register(
      fullName: nameController.text,
      email: emailController.text,
      phone: phoneController.text,
      password: passwordController.text,
    );
    if (isClosed) return;
    result.fold(
      (AuthFailureType failure) => emit(
        state.copyWith(status: RegisterStatus.failure, failure: failure),
      ),
      (AppUser user) {
        _storage.write(AppKeys.savedEmail, user.email);
        passwordController.clear();
        confirmController.clear();
        emit(state.copyWith(status: RegisterStatus.success, user: user));
      },
    );
  }

  @override
  Future<void> close() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    return super.close();
  }
}
