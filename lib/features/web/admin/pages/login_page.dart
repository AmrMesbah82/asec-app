/// /admin/login — same e-mail and password as the ASEC app.
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/features/web/admin/admin_session.dart';
import 'package:asec/features/web/core/i18n.dart';
import 'package:asec/features/web/core/theme.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _pass = TextEditingController();
  bool _busy = false;
  bool _hide = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    AdminSession.instance.addListener(_onSession);
  }

  @override
  void dispose() {
    AdminSession.instance.removeListener(_onSession);
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  void _onSession() {
    final AdminSession s = AdminSession.instance;
    if (!mounted) return;
    if (s.isStaff) {
      context.go('/admin');
    } else if (s.state == AdminState.denied) {
      setState(() {
        _busy = false;
        _error = s.deniedReason == 'no_permission'
            ? const L('حسابك مشرف في التطبيق لكن بدون صلاحية "الموقع". اطلبها من المشرف الرئيسي.',
                    'Your admin account has no "website" permission. Ask the super admin.')
                .t
            : const L('هذا الحساب ليس مشرفًا.', 'This account is not an admin.').t;
      });
      AdminSession.instance.signOut();
    }
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AdminSession.instance.signIn(_email.text, _pass.text);
    } on FirebaseAuthException catch (e) {
      setState(() {
        _busy = false;
        _error = switch (e.code) {
          'invalid-credential' || 'wrong-password' || 'user-not-found' || 'invalid-email' =>
            const L('البريد أو كلمة المرور غير صحيحة', 'Wrong e-mail or password').t,
          'too-many-requests' => const L('محاولات كثيرة، حاول لاحقًا', 'Too many attempts, try later').t,
          'user-disabled' => const L('هذا الحساب موقوف', 'This account is disabled').t,
          _ => '${e.code}: ${e.message}',
        };
      });
    }
  }

  Future<void> _reset() async {
    if (_email.text.trim().isEmpty) {
      setState(() => _error = const L('اكتب بريدك أولًا', 'Type your e-mail first').t);
      return;
    }
    try {
      await AdminSession.instance.resetPassword(_email.text);
      setState(() => _error = const L('أرسلنا رابط تعيين كلمة المرور إلى بريدك', 'A reset link was sent').t);
    } catch (e) {
      setState(() => _error = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: AppLang.locale,
      builder: (BuildContext context, _, _) => Directionality(
        textDirection: AppLang.direction,
        child: Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: <Color>[WebColors.black, WebColors.navy],
              ),
            ),
            alignment: Alignment.center,
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: AutofillGroup(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: TextButton(
                            onPressed: AppLang.toggle,
                            child: Text(AppLang.isAr ? 'English' : 'عربي'),
                          ),
                        ),
                        Image.asset('assets/web/images/logo.png', height: 80),
                        const SizedBox(height: 14),
                        Text(const L('لوحة التحكم', 'Control panel').t,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: WebColors.navy)),
                        const SizedBox(height: 4),
                        Text(const L('ادخل بحساب المشرف في تطبيق ASEC', 'Sign in with your ASEC app admin account').t,
                            textAlign: TextAlign.center, style: TextStyle(color: WebColors.muted)),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _email,
                          textDirection: TextDirection.ltr,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const <String>[AutofillHints.email],
                          decoration: InputDecoration(
                            labelText: const L('البريد الإلكتروني', 'E-mail').t,
                            prefixIcon: const AppIcon(Icons.alternate_email_rounded),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _pass,
                          obscureText: _hide,
                          textDirection: TextDirection.ltr,
                          autofillHints: const <String>[AutofillHints.password],
                          onSubmitted: (_) => _busy ? null : _submit(),
                          decoration: InputDecoration(
                            labelText: const L('كلمة المرور', 'Password').t,
                            prefixIcon: const AppIcon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              onPressed: () => setState(() => _hide = !_hide),
                              icon: AppIcon(_hide ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                            ),
                          ),
                        ),
                        if (_error != null) ...<Widget>[
                          const SizedBox(height: 12),
                          Text(_error!, style: const TextStyle(color: WebColors.red)),
                        ],
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _busy ? null : _submit,
                          child: _busy
                              ? const SizedBox(
                                  width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Text(const L('دخول', 'Sign in').t),
                        ),
                        TextButton(onPressed: _reset, child: Text(const L('نسيت كلمة المرور؟', 'Forgot password?').t)),
                        TextButton(onPressed: () => context.go('/'), child: Text(const L('العودة للموقع', 'Back to site').t)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
