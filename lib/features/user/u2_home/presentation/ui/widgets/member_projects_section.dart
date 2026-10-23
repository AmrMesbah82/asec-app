/// Module: user / u2_home
///
///*************************** FILE INFO ****************************///
/// File Name: member_projects_section.dart
/// Purpose: Declares `MemberProjectsSection` — the website's projects as
///          their own section on the member's home page: a horizontal list
///          (three cards on screen, the rest one swipe away) that slides by
///          itself, and `MemberProjectPage`, one project in the app's own
///          look (not the website in a frame).
/// Author: ASEC team
/// Created: 21/10/2026
///
/// The projects are the published `site_projects` the website shows, read
/// live, so a project added in Website → Projects appears here too.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/animation/app_animations.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/features/web/core/doc.dart';
import 'package:asec/features/web/data/site_repo.dart';
import 'package:asec/features/web/site/widgets/cards.dart' show kProjectCategories;
import 'package:asec/generated/l10n.dart';

/// A text field of [d] in the APP's language: the `_en` twin in English
/// when it is filled, else the Arabic.
String _txt(BuildContext context, Doc d, String key) {
  final bool ar = Localizations.localeOf(context).languageCode == 'ar';
  if (!ar) {
    final String en = d.raw('${key}_en').trim();
    if (en.isNotEmpty) return en;
  }
  return d.raw(key).trim();
}

class MemberProjectsSection extends StatefulWidget {
  const MemberProjectsSection({super.key});

  @override
  State<MemberProjectsSection> createState() => _MemberProjectsSectionState();
}

class _MemberProjectsSectionState extends State<MemberProjectsSection> {
  late final Stream<List<Doc>> _projects = SiteRepo.published(Coll.projects);
  final ScrollController _scroll = ScrollController();
  Timer? _auto;
  bool _touching = false;
  double _step = 0;

  @override
  void initState() {
    super.initState();
    // THE LIST SLIDES BY ITSELF: one card every few seconds, back to the
    // start at the end. A finger on it stops the sliding.
    _auto = Timer.periodic(const Duration(seconds: 4), (_) => _next());
  }

  void _next() {
    if (_touching || !_scroll.hasClients || _step <= 0) return;
    final ScrollPosition p = _scroll.position;
    if (p.maxScrollExtent <= 0) return;
    final double to = p.pixels + _step >= p.maxScrollExtent + 1 ? 0 : p.pixels + _step;
    _scroll.animateTo(
      to.clamp(0, p.maxScrollExtent),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _auto?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    return StreamBuilder<List<Doc>>(
      stream: _projects,
      builder: (BuildContext context, AsyncSnapshot<List<Doc>> snap) {
        final List<Doc> items = snap.data ?? const <Doc>[];
        if (items.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              s.libraryProjects,
              style: StyleText.fontSize18Weight600.copyWith(color: AppColors.text),
            ),
            SizedBox(height: 10.h),
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints c) {
                // THREE ON SCREEN, then scroll.
                final double gap = 12.w;
                final double width = (c.maxWidth - gap * 2) / 3;
                _step = width + gap;
                final double imageH = width * 3 / 4;
                final double height = imageH + 58.h;
                return SizedBox(
                  height: height,
                  child: Listener(
                    onPointerDown: (_) => _touching = true,
                    onPointerUp: (_) => _touching = false,
                    onPointerCancel: (_) => _touching = false,
                    child: ListView.separated(
                      controller: _scroll,
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => SizedBox(width: gap),
                      itemBuilder: (BuildContext context, int i) => FadeSlideIn(
                        delay: staggerDelay(i, stepMs: 70),
                        offset: const Offset(40, 0),
                        child: SizedBox(
                          width: width,
                          child: _ProjectCard(doc: items[i], imageHeight: imageH),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.doc, required this.imageHeight});

  final Doc doc;
  final double imageHeight;

  @override
  Widget build(BuildContext context) {
    final String title = _txt(context, doc, 'title');
    final String category = kProjectCategories[doc.raw('category')] ?? '';
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16.r),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => MemberProjectPage(doc: doc),
        )),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SizedBox(
              height: imageHeight,
              child: Hero(tag: 'project_${doc.id}', child: _Cover(url: doc.raw('cover'))),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: StyleText.fontSize13Weight600.copyWith(color: AppColors.text),
                    ),
                    if (category.isNotEmpty)
                      Text(
                        category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: StyleText.fontSize11Weight500.copyWith(color: AppColors.primary),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final Widget placeholder = Container(
      color: AppColors.chip,
      alignment: Alignment.center,
      child: Icon(Icons.apartment_rounded, color: AppColors.secondaryText, size: 28),
    );
    if (url.trim().isEmpty) return placeholder;
    return Image.network(
      url,
      fit: BoxFit.cover,
      webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
      errorBuilder: (_, __, ___) => placeholder,
      loadingBuilder: (BuildContext c, Widget child, ImageChunkEvent? p) =>
          p == null ? child : placeholder,
    );
  }
}

/// One project in the app's own look.
class MemberProjectPage extends StatelessWidget {
  const MemberProjectPage({super.key, required this.doc});

  final Doc doc;

  @override
  Widget build(BuildContext context) {
    final bool ar = Localizations.localeOf(context).languageCode == 'ar';
    final String title = _txt(context, doc, 'title');
    final String category = kProjectCategories[doc.raw('category')] ?? '';
    final String description = _txt(context, doc, 'description');
    final List<String> gallery = doc.l('gallery');
    final List<(String, String)> facts = <(String, String)>[
      (ar ? 'العميل' : 'Client', _txt(context, doc, 'client')),
      (ar ? 'الموقع' : 'Location', _txt(context, doc, 'location')),
      (ar ? 'المساحة' : 'Area', _txt(context, doc, 'area')),
      (ar ? 'التاريخ' : 'Date', _txt(context, doc, 'date')),
    ].where(((String, String) f) => f.$2.isNotEmpty).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        surfaceTintColor: AppColors.transparent,
        iconTheme: IconThemeData(color: AppColors.text),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: StyleText.fontSize16Weight600.copyWith(color: AppColors.text),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.r),
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(18.r),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: Hero(tag: 'project_${doc.id}', child: _Cover(url: doc.raw('cover'))),
            ),
          ),
          SizedBox(height: 14.h),
          Text(title, style: StyleText.fontSize20Weight600.copyWith(color: AppColors.text)),
          if (category.isNotEmpty) ...<Widget>[
            SizedBox(height: 4.h),
            Text(category, style: StyleText.fontSize13Weight600.copyWith(color: AppColors.primary)),
          ],
          if (facts.isNotEmpty) ...<Widget>[
            SizedBox(height: 14.h),
            Wrap(
              spacing: 10.w,
              runSpacing: 10.h,
              children: <Widget>[
                for (final (String label, String value) in facts)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(label, style: StyleText.fontSize11Weight500.copyWith(color: AppColors.secondaryText)),
                        Text(value, style: StyleText.fontSize13Weight600.copyWith(color: AppColors.text)),
                      ],
                    ),
                  ),
              ],
            ),
          ],
          if (description.isNotEmpty) ...<Widget>[
            SizedBox(height: 16.h),
            Text(
              description,
              style: StyleText.fontSize14Weight400.copyWith(color: AppColors.text, height: 1.7),
            ),
          ],
          if (gallery.isNotEmpty) ...<Widget>[
            SizedBox(height: 18.h),
            SizedBox(
              height: 140.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: gallery.length,
                separatorBuilder: (_, __) => SizedBox(width: 10.w),
                itemBuilder: (BuildContext context, int i) => ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: AspectRatio(aspectRatio: 4 / 3, child: _Cover(url: gallery[i])),
                ),
              ),
            ),
          ],
          SizedBox(height: 24.h),
        ],
      ),
    );
  }
}
