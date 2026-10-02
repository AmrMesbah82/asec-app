/// Module: settings / se1_settings
///
///*************************** FILE INFO ****************************///
/// File Name: admins_card.dart
/// Purpose: Declares `AdminsCard` — super admin only: every admin account,
///          what each may manage, a switch to turn one off, and the form to
///          create a new admin with chosen permissions.
/// Author: ASEC team
/// Created: 25/9/2026

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/custom/101-custom_surface.dart';
import 'package:asec/core/custom/110-app_widgets.dart';
import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/core/custom/2-custom_textfield.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/entities/app_user.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/enums/admin_permission.dart';
import 'package:asec/features/settings/se1_settings/data/admins_repository.dart';
import 'package:asec/generated/l10n.dart';

class AdminsCard extends StatefulWidget {
  const AdminsCard({super.key});

  @override
  State<AdminsCard> createState() => _AdminsCardState();
}

class _AdminsCardState extends State<AdminsCard> {
  final AdminsRepository _repo = AdminsRepository();
  late final Stream<List<AppUser>> _admins = _repo.watchAdmins();

  void _toast(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _create() async {
    final bool? created = await showDialog<bool>(
      context: context,
      builder: (_) => _AdminFormDialog(repo: _repo),
    );
    if (created == true) _toast(S.of(context).adminCreated);
  }

  Future<void> _editPermissions(AppUser admin) async {
    final List<AdminPermission>? perms = await showDialog<List<AdminPermission>>(
      context: context,
      builder: (_) => _PermissionsDialog(
        title: admin.displayName,
        initial: admin.permissions,
      ),
    );
    if (perms == null) return;
    try {
      await _repo.setPermissions(admin.uid, perms);
      _toast(S.of(context).permissionsSaved);
    } catch (_) {
      _toast(S.of(context).errUnknown);
    }
  }

  Future<void> _remove(AppUser admin) async {
    final S s = S.of(context);
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(s.removeAdminQuestion),
        content: Text(s.removeAdminBody(admin.displayName)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.delete, style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _repo.remove(admin.uid);
    } catch (_) {
      _toast(s.errUnknown);
    }
  }

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);

    return AppCard(
      title: s.adminsTitle,
      caption: s.adminsHint,
      actions: <Widget>[
        AppButton(
          label: s.addAdmin,
          icon: Icons.person_add_alt_1_rounded,
          dense: true,
          onPressed: _create,
        ),
      ],
      child: StreamBuilder<List<AppUser>>(
        stream: _admins,
        builder: (BuildContext context, AsyncSnapshot<List<AppUser>> snap) {
          if (snap.hasError) {
            return Text(s.errUnknown,
                style: StyleText.fontSize13Weight400
                    .copyWith(color: AppColors.red));
          }
          if (!snap.hasData) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator.adaptive()),
            );
          }
          final List<AppUser> admins = snap.data!;
          if (admins.isEmpty) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              child: Text(
                s.noAdminsYet,
                style: StyleText.fontSize13Weight400
                    .copyWith(color: AppColors.secondaryText),
              ),
            );
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (final AppUser a in admins)
                _AdminRow(
                  admin: a,
                  onToggle: (bool v) async {
                    try {
                      await _repo.setActive(a.uid, v);
                    } catch (_) {
                      _toast(s.errUnknown);
                    }
                  },
                  onEdit: () => _editPermissions(a),
                  onRemove: () => _remove(a),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _AdminRow extends StatelessWidget {
  const _AdminRow({
    required this.admin,
    required this.onToggle,
    required this.onEdit,
    required this.onRemove,
  });

  final AppUser admin;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.chip,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              AppAvatar(name: admin.displayName, size: 40),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      admin.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: StyleText.fontSize14Weight600,
                    ),
                    Text(
                      admin.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: StyleText.fontSize12Weight400
                          .copyWith(color: AppColors.secondaryText),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: admin.active,
                activeTrackColor: AppColors.secondaryPrimary,
                onChanged: onToggle,
              ),
              PopupMenuButton<int>(
                icon: AppIcon(Icons.more_vert_rounded, size: 20.sp),
                onSelected: (int v) => v == 0 ? onEdit() : onRemove(),
                itemBuilder: (_) => <PopupMenuEntry<int>>[
                  PopupMenuItem<int>(value: 0, child: Text(s.editPermissions)),
                  PopupMenuItem<int>(
                    value: 1,
                    child: Text(s.removeAdmin,
                        style: TextStyle(color: AppColors.red)),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 6.w,
            runSpacing: 6.h,
            children: <Widget>[
              if (admin.permissions.isEmpty)
                Text(
                  s.noPermissions,
                  style: StyleText.fontSize12Weight400
                      .copyWith(color: AppColors.statusPending),
                ),
              for (final AdminPermission p in admin.permissions)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      AppIcon(p.icon, size: 13.sp, color: AppColors.onChip),
                      SizedBox(width: 4.w),
                      Text(
                        p.label(context),
                        style: StyleText.fontSize11Weight600
                            .copyWith(color: AppColors.onChip),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Checkbox list of permissions, reused by the create form and the edit
/// dialog.
class _PermissionPicker extends StatelessWidget {
  const _PermissionPicker({required this.selected, required this.onChanged});

  final Set<AdminPermission> selected;
  final ValueChanged<Set<AdminPermission>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final AdminPermission p in AdminPermission.values)
          CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: AppColors.primary,
            value: selected.contains(p),
            secondary: AppIcon(p.icon, size: 18.sp, color: AppColors.secondaryText),
            title: Text(p.label(context), style: StyleText.fontSize14Weight500),
            onChanged: (bool? v) {
              final Set<AdminPermission> next = <AdminPermission>{...selected};
              v == true ? next.add(p) : next.remove(p);
              onChanged(next);
            },
          ),
      ],
    );
  }
}

class _PermissionsDialog extends StatefulWidget {
  const _PermissionsDialog({required this.title, required this.initial});

  final String title;
  final List<AdminPermission> initial;

  @override
  State<_PermissionsDialog> createState() => _PermissionsDialogState();
}

class _PermissionsDialogState extends State<_PermissionsDialog> {
  late Set<AdminPermission> _selected = widget.initial.toSet();

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    return AlertDialog(
      backgroundColor: AppColors.card,
      title: Text('${s.editPermissions} · ${widget.title}',
          style: StyleText.fontSize16Weight600),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: _PermissionPicker(
            selected: _selected,
            onChanged: (Set<AdminPermission> v) => setState(() => _selected = v),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(s.cancel),
        ),
        AppButton(
          label: s.save,
          dense: true,
          onPressed: () => Navigator.pop(
            context,
            <AdminPermission>[
              for (final AdminPermission p in AdminPermission.values)
                if (_selected.contains(p)) p,
            ],
          ),
        ),
      ],
    );
  }
}

class _AdminFormDialog extends StatefulWidget {
  const _AdminFormDialog({required this.repo});

  final AdminsRepository repo;

  @override
  State<_AdminFormDialog> createState() => _AdminFormDialogState();
}

class _AdminFormDialogState extends State<_AdminFormDialog> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  Set<AdminPermission> _perms = <AdminPermission>{
    AdminPermission.dashboard,
    AdminPermission.videos,
    AdminPermission.quizzes,
  };
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final S s = S.of(context);
    final String email = _email.text.trim();
    if (_name.text.trim().isEmpty ||
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      setState(() => _error = s.adminFormInvalid);
      return;
    }
    if (_password.text.length < 6) {
      setState(() => _error = s.adminPasswordShort);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.repo.createAdmin(
        fullName: _name.text,
        email: email,
        password: _password.text,
        permissions: <AdminPermission>[
          for (final AdminPermission p in AdminPermission.values)
            if (_perms.contains(p)) p,
        ],
      );
      if (mounted) Navigator.pop(context, true);
    } on FirebaseAuthException catch (e) {
      setState(() {
        _busy = false;
        _error = e.code == 'email-already-in-use'
            ? s.adminEmailInUse
            : (e.message ?? s.errUnknown);
      });
    } catch (e) {
      setState(() {
        _busy = false;
        _error = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    return AlertDialog(
      backgroundColor: AppColors.card,
      title: Text(s.addAdmin, style: StyleText.fontSize18Weight600),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              CustomTextField(controller: _name, label: s.fullName),
              SizedBox(height: 10.h),
              CustomTextField(
                controller: _email,
                label: s.email,
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 10.h),
              CustomTextField(
                controller: _password,
                label: s.password,
                obscureText: true,
              ),
              SizedBox(height: 14.h),
              Text(s.permissionsTitle, style: StyleText.fontSize14Weight600),
              _PermissionPicker(
                selected: _perms,
                onChanged: (Set<AdminPermission> v) => setState(() => _perms = v),
              ),
              if (_error != null) ...<Widget>[
                SizedBox(height: 8.h),
                Text(
                  _error!,
                  style: StyleText.fontSize12Weight500
                      .copyWith(color: AppColors.red),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context, false),
          child: Text(s.cancel),
        ),
        AppButton(
          label: s.createAdmin,
          icon: Icons.check_rounded,
          dense: true,
          loading: _busy,
          onPressed: _busy ? null : _submit,
        ),
      ],
    );
  }
}
