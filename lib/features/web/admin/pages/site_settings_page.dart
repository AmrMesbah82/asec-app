/// /admin/site — every text, image and contact detail of the site that is
/// not a list item (site_settings/main).
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/features/web/admin/configs.dart';
import 'package:asec/features/web/admin/fields.dart';
import 'package:asec/features/web/admin/widgets.dart';
import 'package:asec/features/web/core/i18n.dart';
import 'package:asec/features/web/core/widgets.dart';
import 'package:asec/features/web/data/site_repo.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';

class SiteSettingsPage extends StatefulWidget {
  const SiteSettingsPage({super.key});

  @override
  State<SiteSettingsPage> createState() => _SiteSettingsPageState();
}

class _SiteSettingsPageState extends State<SiteSettingsPage> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  Map<String, dynamic>? _values;
  Object? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> s = await SiteRepo.settingsDoc.get();
      setState(() => _values = <String, dynamic>{
            ...blankValues(siteSettingsSpecs),
            ...?s.data(),
          });
    } catch (e) {
      setState(() => _error = e);
    }
  }

  Future<void> _save() async {
    final Map<String, dynamic>? v = _values;
    if (v == null) return;
    setState(() => _saving = true);
    await guarded(context, () => SiteRepo.settingsDoc.set(<String, dynamic>{
          for (final String k in storedKeys(siteSettingsSpecs)) k: v[k],
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)));
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return AdminPageFrame(
      title: const L('إعدادات الموقع', 'Site settings').t,
      icon: Icons.tune_rounded,
      subtitle: const L(
              'النصوص والصور وبيانات التواصل. لكل نص خانة بالعربي وخانة بالإنجليزي للنسخة الإنجليزية من الموقع. تظهر على الموقع فور الحفظ.',
              'Texts, images and contact details. Each text has an Arabic box and an English box for the English version of the site. Live on the site as soon as you save.')
          .t,
      actions: <Widget>[
        FilledButton.icon(
          onPressed: _saving || _values == null ? null : _save,
          icon: const AppIcon(Icons.save_rounded),
          label: Text(FormatHelper.capitalize(const L('حفظ', 'Save').t)),
        ),
      ],
      child: _error != null
          ? ErrorNote(_error)
          : _values == null
              ? const Loading()
              : Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: DocForm(formKey: _form, specs: siteSettingsSpecs, values: _values!, folder: 'settings'),
                  ),
                ),
    );
  }
}
