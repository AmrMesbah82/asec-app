/// One list page for every content type: search, publish switch, edit,
/// delete, add. The editor is `DocEditorPage` below, driven by the config.
library;

import 'package:flutter/material.dart';

import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/features/web/admin/configs.dart';
import 'package:asec/features/web/admin/fields.dart';
import 'package:asec/features/web/admin/widgets.dart';
import 'package:asec/features/web/core/doc.dart';
import 'package:asec/features/web/core/i18n.dart';
import 'package:asec/features/web/core/theme.dart';
import 'package:asec/features/web/core/widgets.dart';
import 'package:asec/features/web/data/site_repo.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';

class CollectionPage extends StatefulWidget {
  const CollectionPage({super.key, required this.config});

  final CollectionConfig config;

  @override
  State<CollectionPage> createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage> {
  late Stream<List<Doc>> _stream = SiteRepo.all(widget.config.coll, by: widget.config.sort);
  String _q = '';

  @override
  void didUpdateWidget(CollectionPage old) {
    super.didUpdateWidget(old);
    if (old.config.coll != widget.config.coll) {
      _stream = SiteRepo.all(widget.config.coll, by: widget.config.sort);
      _q = '';
    }
  }

  Future<void> _edit(Doc? d) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => DocEditorPage(config: widget.config, doc: d),
      ),
    );
  }

  Future<void> _delete(Doc d) async {
    final bool ok = await confirm(
      context,
      const L('حذف العنصر؟', 'Delete item?').t,
      '"${d.s(widget.config.titleKey)}" ${const L('سيُحذف نهائيًا.', 'will be deleted for good.').t}',
    );
    if (!ok) return;
    await guarded(context, () => SiteRepo.remove(widget.config.coll, d.id));
  }

  @override
  Widget build(BuildContext context) {
    final CollectionConfig cfg = widget.config;
    return AdminPageFrame(
      title: cfg.title.t,
      icon: cfg.icon,
      actions: <Widget>[
        FilledButton.icon(
          onPressed: () => _edit(null),
          icon: const AppIcon(Icons.add_rounded),
          label: Text(FormatHelper.capitalize(const L('إضافة', 'Add').t)),
        ),
      ],
      child: StreamBuilder<List<Doc>>(
        stream: _stream,
        builder: (BuildContext context, AsyncSnapshot<List<Doc>> snap) {
          if (snap.hasError) return ErrorNote(snap.error);
          if (!snap.hasData) return const Loading();
          final String q = _q.trim().toLowerCase();
          final List<Doc> items = snap.data!
              .where((Doc d) => q.isEmpty || d.s(cfg.titleKey).toLowerCase().contains(q))
              .toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  SizedBox(
                    width: 320,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: const L('بحث', 'Search').t,
                        prefixIcon: const AppIcon(Icons.search_rounded),
                      ),
                      onChanged: (String v) => setState(() => _q = v),
                    ),
                  ),
                  const Spacer(),
                  Text(FormatHelper.capitalize('${items.length} / ${snap.data!.length}'), style: TextStyle(color: WebColors.muted)),
                ],
              ),
              const SizedBox(height: 14),
              if (items.isEmpty)
                EmptyNote(const L('لا يوجد شيء بعد — اضغط "إضافة" أو استورد المحتوى من صفحة الاستيراد',
                        'Nothing yet — press Add, or use the Import page')
                    .t)
              else
                Card(
                  child: Column(
                    children: <Widget>[
                      for (int i = 0; i < items.length; i++) ...<Widget>[
                        if (i > 0) const Divider(),
                        _Row(
                          doc: items[i],
                          cfg: cfg,
                          onEdit: () => _edit(items[i]),
                          onDelete: () => _delete(items[i]),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.doc, required this.cfg, required this.onEdit, required this.onDelete});

  final Doc doc;
  final CollectionConfig cfg;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final bool pub = doc.b('published');
    final String sub = cfg.subtitleKey == null ? '' : doc.s(cfg.subtitleKey!);
    final DateTime? date = doc.t('published_at');
    return ListTile(
      onTap: onEdit,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: cfg.imageKey == null
          ? CircleAvatar(backgroundColor: WebColors.surface, child: AppIcon(cfg.icon, color: WebColors.navy))
          : SizedBox(width: 64, height: 48, child: NetImage(doc.s(cfg.imageKey!), radius: 6)),
      title: Text(FormatHelper.capitalize(doc.s(cfg.titleKey, '—')), maxLines: 1, overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(
        FormatHelper.capitalize(<String>[
          if (sub.isNotEmpty) sub,
          if (date != null) panelDate(date),
          if (cfg.sort == SortBy.order) '#${doc.i('order')}',
        ].join('  ·  ')),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Tooltip(
            message: pub ? const L('منشور', 'Published').t : const L('مخفي', 'Hidden').t,
            child: Switch(
              value: pub,
              onChanged: (bool v) => guarded(context, () => SiteRepo.patch(cfg.coll, doc.id, <String, dynamic>{'published': v})),
            ),
          ),
          if (cfg.publicPath != null)
            IconButton(
              tooltip: const L('فتح على الموقع', 'Open on site').t,
              onPressed: () => openLink(Uri.base.resolve(cfg.publicPath!(doc.id, doc.data)).toString()),
              icon: const AppIcon(Icons.open_in_new_rounded),
            ),
          IconButton(tooltip: const L('تعديل', 'Edit').t, onPressed: onEdit, icon: const AppIcon(Icons.edit_outlined)),
          IconButton(
            tooltip: const L('حذف', 'Delete').t,
            onPressed: onDelete,
            icon: const AppIcon(Icons.delete_outline_rounded, color: WebColors.red),
          ),
        ],
      ),
    );
  }
}

class DocEditorPage extends StatefulWidget {
  const DocEditorPage({super.key, required this.config, this.doc});

  final CollectionConfig config;
  final Doc? doc;

  @override
  State<DocEditorPage> createState() => _DocEditorPageState();
}

class _DocEditorPageState extends State<DocEditorPage> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  late final Map<String, dynamic> _values = <String, dynamic>{
    ...widget.config.blank(),
    ...?widget.doc?.data,
  };
  bool _saving = false;

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final Map<String, dynamic> data = <String, dynamic>{
      for (final String k in storedKeys(widget.config.specs)) k: _values[k],
    };
    final bool ok = await guarded(context, () => SiteRepo.save(widget.config.coll, widget.doc?.id, data));
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bool isNew = widget.doc == null;
    return Directionality(
      textDirection: AppLang.direction,
      child: Scaffold(
        backgroundColor: WebColors.adminBg,
        appBar: AppBar(
          leading: IconButton(
            tooltip: const L('إغلاق', 'Close').t,
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const AppIcon(Icons.close_rounded),
          ),
          title: Text(FormatHelper.capitalize('${isNew ? const L('إضافة', 'New').t : const L('تعديل', 'Edit').t} — ${widget.config.title.t}')),
          actions: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const AppIcon(Icons.save_rounded),
                label: Text(FormatHelper.capitalize(const L('حفظ', 'Save').t)),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Contained(
            maxWidth: 860,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: DocForm(
                  formKey: _form,
                  specs: widget.config.specs,
                  values: _values,
                  folder: widget.config.coll.replaceFirst('site_', ''),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
