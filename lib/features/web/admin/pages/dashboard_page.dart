/// /admin — counts at a glance and the newest inbox items. The super admin
/// also sees the ASEC app's numbers (members, videos, quizzes).
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:asec/features/web/admin/admin_session.dart';
import 'package:asec/features/web/admin/panel_nav.dart';
import 'package:asec/features/web/admin/pages/inbox_page.dart';
import 'package:asec/features/web/admin/widgets.dart';
import 'package:asec/features/web/core/doc.dart';
import 'package:asec/features/web/core/i18n.dart';
import 'package:asec/features/web/core/theme.dart';
import 'package:asec/features/web/core/widgets.dart';
import 'package:asec/features/web/data/site_repo.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isSuper = AdminSession.instance.isSuper;
    final int cols = context.width >= 1300 ? 4 : (context.width >= 760 ? 3 : (context.width >= 480 ? 2 : 1));
    Widget grid(List<Widget> tiles) => LayoutBuilder(
          builder: (BuildContext c, BoxConstraints bc) {
            final double w = (bc.maxWidth - 14 * (cols - 1)) / cols;
            return Wrap(spacing: 14, runSpacing: 14, children: <Widget>[for (final Widget t in tiles) SizedBox(width: w, child: t)]);
          },
        );
    return AdminPageFrame(
      title: const L('لوحة المعلومات', 'Dashboard').t,
      icon: Icons.space_dashboard_outlined,
      subtitle: '${const L('أهلًا', 'Welcome').t} ${AdminSession.instance.name}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _Heading(const L('الوارد الجديد', 'New in inbox').t),
          grid(<Widget>[
            _NewCount(coll: Coll.messages, label: const L('رسائل التواصل', 'Messages').t, icon: Icons.mail_outline_rounded, tab: 0),
            _NewCount(
                coll: Coll.serviceRequests, label: const L('طلبات الخدمة', 'Service requests').t, icon: Icons.design_services_outlined, tab: 1),
            _NewCount(coll: Coll.jobApplications, label: const L('طلبات التوظيف', 'Job applications').t, icon: Icons.work_outline_rounded, tab: 2),
          ]),
          const SizedBox(height: 26),
          _Heading(const L('محتوى الموقع', 'Website content').t),
          grid(<Widget>[
            _Count(coll: Coll.projects, label: const L('الأعمال', 'Projects').t, icon: Icons.apartment_rounded, path: '/admin/projects'),
            _Count(coll: Coll.articles, label: const L('المقالات', 'Articles').t, icon: Icons.article_outlined, path: '/admin/articles'),
            _Count(coll: Coll.services, label: const L('الخدمات', 'Services').t, icon: Icons.design_services_rounded, path: '/admin/services'),
            _Count(coll: Coll.partners, label: const L('شركاء النجاح', 'Partners').t, icon: Icons.handshake_outlined, path: '/admin/partners'),
            _Count(
                coll: Coll.testimonials, label: const L('أراء العملاء', 'Testimonials').t, icon: Icons.format_quote_rounded, path: '/admin/testimonials'),
          ]),
          if (isSuper) ...<Widget>[
            const SizedBox(height: 26),
            _Heading(const L('تطبيق ASEC', 'ASEC app').t),
            grid(<Widget>[
              _Aggregate(
                query: SiteRepo.db.collection(Coll.users).where('role', isEqualTo: 'user'),
                label: const L('الأعضاء', 'Members').t,
                icon: Icons.groups_2_outlined,
              ),
              _Aggregate(query: SiteRepo.db.collection('videos'), label: const L('الفيديوهات', 'Videos').t, icon: Icons.video_library_outlined),
              _Aggregate(query: SiteRepo.db.collection('quizzes'), label: const L('الاختبارات', 'Quizzes').t, icon: Icons.quiz_outlined),
              _Aggregate(query: SiteRepo.db.collection('cvs'), label: const L('السير الذاتية', 'CVs').t, icon: Icons.assignment_outlined),
            ]),
          ],
          const SizedBox(height: 26),
          _Heading(const L('آخر الوارد', 'Latest in inbox').t),
          const LatestInbox(),
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: WebColors.navy)),
      );
}

class _Count extends StatelessWidget {
  const _Count({required this.coll, required this.label, required this.icon, required this.path});

  final String coll;
  final String label;
  final IconData icon;
  final String path;

  @override
  Widget build(BuildContext context) => StreamBuilder<List<Doc>>(
        stream: SiteRepo.all(coll),
        builder: (BuildContext c, AsyncSnapshot<List<Doc>> s) {
          final List<Doc> d = s.data ?? const <Doc>[];
          final int pub = d.where((Doc x) => x.b('published')).length;
          return StatTile(
            label: '$label · ${const L('منشور', 'published').t} $pub',
            value: s.hasData ? '${d.length}' : '…',
            icon: icon,
            onTap: () => panelGo(context, path),
          );
        },
      );
}

class _NewCount extends StatelessWidget {
  const _NewCount({required this.coll, required this.label, required this.icon, required this.tab});

  final String coll;
  final String label;
  final IconData icon;
  final int tab;

  @override
  Widget build(BuildContext context) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: SiteRepo.db.collection(coll).where('status', isEqualTo: 'new').snapshots(),
        builder: (BuildContext c, AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> s) => StatTile(
          label: label,
          value: s.hasData ? '${s.data!.size}' : '…',
          icon: icon,
          color: WebColors.red,
          onTap: () => panelGo(context, '/admin/inbox?tab=$tab'),
        ),
      );
}

class _Aggregate extends StatelessWidget {
  const _Aggregate({required this.query, required this.label, required this.icon});

  final Query<Map<String, dynamic>> query;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) => FutureBuilder<AggregateQuerySnapshot>(
        future: query.count().get(),
        builder: (BuildContext c, AsyncSnapshot<AggregateQuerySnapshot> s) => StatTile(
          label: label,
          value: s.hasError ? '—' : (s.hasData ? '${s.data!.count ?? 0}' : '…'),
          icon: icon,
          color: WebColors.blue,
        ),
      );
}
