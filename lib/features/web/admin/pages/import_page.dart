/// /admin/import — fill Firestore with the content of asecbim.com.
library;

import 'package:flutter/material.dart';

import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/features/web/admin/widgets.dart';
import 'package:asec/features/web/core/i18n.dart';
import 'package:asec/features/web/core/theme.dart';
import 'package:asec/features/web/data/importers.dart';

class ImportPage extends StatefulWidget {
  const ImportPage({super.key});

  @override
  State<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends State<ImportPage> {
  final TextEditingController _base = TextEditingController(text: 'https://asecbim.com');
  final List<String> _log = <String>[];
  bool _busy = false;
  bool _overwrite = false;

  @override
  void dispose() {
    _base.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() job) async {
    setState(() {
      _busy = true;
      _log.clear();
    });
    try {
      await job();
      _add(const L('انتهى ✓', 'Done ✓').t);
    } catch (e) {
      _add('✗ ${describeError(e)}');
      if ('$e'.contains('XMLHttpRequest') || '$e'.contains('Failed to fetch') || '$e'.contains('ClientException')) {
        _add(const L(
          'المتصفح منع قراءة موقع ووردبريس (CORS). جرّب مرة أخرى بعد نشر الموقع على الدومين الفرعي، أو فعّل REST API/CORS في ووردبريس.',
          'The browser blocked reading WordPress (CORS). Try again from the deployed subdomain, or allow CORS on the WordPress REST API.',
        ).t);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _add(String s) {
    if (mounted) setState(() => _log.add(s));
  }

  @override
  Widget build(BuildContext context) {
    return AdminPageFrame(
      title: const L('استيراد المحتوى', 'Import content').t,
      icon: Icons.cloud_download_outlined,
      subtitle: const L('انقل محتوى asecbim.com (ووردبريس) إلى Firebase مرة واحدة، ثم عدّله من اللوحة.',
              'Copy the content of asecbim.com (WordPress) into Firebase once, then edit it here.')
          .t,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _Step(
            n: '1',
            title: const L('المحتوى الأساسي', 'Starter content').t,
            text: const L(
              'النصوص، بيانات التواصل، الخدمات الثلاث، المميزات، 16 مشروعًا بصورها، شركاء النجاح وآراء العملاء — كما هي على الموقع الحالي.',
              'Texts, contact details, the 3 services, features, 16 projects with images, partners and testimonials — as on the current site.',
            ).t,
            extra: CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _overwrite,
              onChanged: (bool? v) => setState(() => _overwrite = v ?? false),
              title: Text(const L('استبدال النصوص الموجودة في إعدادات الموقع', 'Overwrite texts already in Site settings').t),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            button: FilledButton.icon(
              onPressed: _busy ? null : () => _run(() => Importers.importStarter(_add, overwriteSettings: _overwrite)),
              icon: const AppIcon(Icons.download_rounded),
              label: Text(const L('استيراد المحتوى الأساسي', 'Import starter content').t),
            ),
          ),
          const SizedBox(height: 16),
          _Step(
            n: '2',
            title: const L('النسخة الإنجليزية', 'English content').t,
            text: const L(
              'يضيف الترجمة الإنجليزية للنصوص والخدمات والمميزات والمشاريع وآراء العملاء (خانات الإنجليزي فقط — لا يغيّر العربي). تتم تلقائيًا مع الخطوة 1؛ استخدمها إذا كان المحتوى مستوردًا من قبل.',
              'Adds the English translation of the texts, services, features, projects and testimonials (English boxes only — the Arabic is not touched). Step 1 already does this; use it if the content was imported before.',
            ).t,
            button: FilledButton.icon(
              onPressed: _busy ? null : () => _run(() => Importers.importEnglish(_add)),
              icon: const AppIcon(Icons.translate_rounded),
              label: Text(const L('إضافة المحتوى الإنجليزي', 'Add English content').t),
            ),
          ),
          const SizedBox(height: 16),
          _Step(
            n: '3',
            title: const L('المقالات من ووردبريس', 'Articles from WordPress').t,
            text: const L(
              'كل المقالات المنشورة (حوالي 100) مع الصور والتصنيفات، وصفحة سياسة الخصوصية. يمكن إعادة التشغيل لاحقًا لجلب الجديد.',
              'Every published post (about 100) with images and categories, plus the privacy page. Run again later to pick up new posts.',
            ).t,
            extra: TextField(
              controller: _base,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(labelText: const L('رابط موقع ووردبريس', 'WordPress site URL').t),
            ),
            button: FilledButton.icon(
              onPressed: _busy ? null : () => _run(() => Importers.importWordPress(_add, base: _base.text.trim())),
              icon: const AppIcon(Icons.article_outlined),
              label: Text(const L('استيراد المقالات', 'Import articles').t),
            ),
          ),
          if (_log.isNotEmpty || _busy) ...<Widget>[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: WebColors.adminSide, borderRadius: BorderRadius.circular(10)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (_busy) const LinearProgressIndicator(),
                  for (final String l in _log)
                    SelectableText(l, style: const TextStyle(color: Colors.white, fontFamily: 'monospace', height: 1.7)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.n, required this.title, required this.text, required this.button, this.extra});

  final String n;
  final String title;
  final String text;
  final Widget button;
  final Widget? extra;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              CircleAvatar(backgroundColor: WebColors.red, child: Text(n, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: WebColors.navy)),
                    const SizedBox(height: 6),
                    Text(text, style: TextStyle(color: WebColors.muted, height: 1.7)),
                    if (extra != null) ...<Widget>[const SizedBox(height: 10), extra!],
                    const SizedBox(height: 12),
                    button,
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
