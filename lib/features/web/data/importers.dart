/// Getting the content of asecbim.com into Firestore.
///
/// 1. `importStarter()` — assets/web/seed/site_seed.json: the texts, services,
///    features, 16 projects, partners and testimonials, taken from the
///    WordPress site on 26/9/2026. Fixed ids, so running it twice updates
///    the same documents instead of duplicating them.
///    Also writes the English versions (step 3).
/// 2. `importWordPress()` — every published post (~100) and the privacy
///    page, read live from the WordPress REST API
///    (https://asecbim.com/wp-json/wp/v2/…). Ids are `wp_{postId}`.
///
/// 3. `importEnglish()` — assets/web/seed/site_seed_en.json: the English
///    version of the starter content. Writes ONLY the `*_en` fields (and
///    `label_en` on the counters), so Arabic edits made in the panel stay.
///    Articles are not translated: they show in Arabic on the English site
///    until an admin fills their English fields.
///
/// Images keep their asecbim.com/wp-content URLs, so WordPress must stay
/// online (it does — this site lives on a subdomain). To move an image to
/// Firebase Storage, open the item in the panel and press "Upload".
library;

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

import 'package:asec/features/web/data/site_repo.dart';

typedef Progress = void Function(String line);

abstract final class Importers {
  static Future<int> _writeAll(String coll, List<Map<String, dynamic>> items) async {
    int n = 0;
    WriteBatch batch = SiteRepo.db.batch();
    int inBatch = 0;
    for (final Map<String, dynamic> raw in items) {
      final Map<String, dynamic> m = Map<String, dynamic>.of(raw);
      final String id = '${m.remove('id') ?? ''}';
      final DocumentReference<Map<String, dynamic>> ref =
          id.isEmpty ? SiteRepo.db.collection(coll).doc() : SiteRepo.db.collection(coll).doc(id);
      batch.set(ref, <String, dynamic>{...m, 'updated_at': FieldValue.serverTimestamp()}, SetOptions(merge: true));
      n++;
      if (++inBatch == 400) {
        await batch.commit();
        batch = SiteRepo.db.batch();
        inBatch = 0;
      }
    }
    if (inBatch > 0) await batch.commit();
    return n;
  }

  static List<Map<String, dynamic>> _list(Object? v) => <Map<String, dynamic>>[
        if (v is List)
          for (final Object? e in v)
            if (e is Map) Map<String, dynamic>.from(e),
      ];

  static Future<void> importStarter(Progress log, {bool overwriteSettings = true}) async {
    final Map<String, dynamic> seed =
        jsonDecode(await rootBundle.loadString('assets/web/seed/site_seed.json')) as Map<String, dynamic>;

    final Map<String, dynamic> settings = Map<String, dynamic>.from(seed['settings'] as Map);
    if (!overwriteSettings) {
      final DocumentSnapshot<Map<String, dynamic>> cur = await SiteRepo.settingsDoc.get();
      final Map<String, dynamic> existing = cur.data() ?? <String, dynamic>{};
      settings.removeWhere((String k, dynamic _) => existing.containsKey(k));
    }
    await SiteRepo.settingsDoc.set(<String, dynamic>{
      ...settings,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    log('✓ site_settings/main');

    final Map<String, String> colls = <String, String>{
      'services': Coll.services,
      'features': Coll.features,
      'projects': Coll.projects,
      'partners': Coll.partners,
      'testimonials': Coll.testimonials,
    };
    for (final MapEntry<String, String> e in colls.entries) {
      final int n = await _writeAll(e.value, _list(seed[e.key]));
      log('✓ ${e.value}: $n');
    }
    await importEnglish(log);
  }

  // ── English ─────────────────────────────────────────────────────────────

  static Future<void> importEnglish(Progress log) async {
    final Map<String, dynamic> en =
        jsonDecode(await rootBundle.loadString('assets/web/seed/site_seed_en.json')) as Map<String, dynamic>;

    Map<String, dynamic> onlyEn(Object? m) => <String, dynamic>{
          if (m is Map)
            for (final MapEntry<dynamic, dynamic> e in m.entries)
              if ('${e.key}'.endsWith('_en')) '${e.key}': e.value,
        };

    // Settings: the *_en texts, and an English label on each counter whose
    // Arabic label we know (the numbers the admin set are kept).
    final Map<String, dynamic> settings = onlyEn(en['settings']);
    final Map<String, dynamic> labels = Map<String, dynamic>.from((en['counter_labels_en'] as Map?) ?? <String, dynamic>{});
    final DocumentSnapshot<Map<String, dynamic>> cur = await SiteRepo.settingsDoc.get();
    final Object? counters = cur.data()?['counters'];
    if (counters is List) {
      settings['counters'] = <Map<String, dynamic>>[
        for (final Object? c in counters)
          if (c is Map)
            <String, dynamic>{
              ...Map<String, dynamic>.from(c),
              if ('${c['label_en'] ?? ''}'.trim().isEmpty && labels['${c['label']}'] != null)
                'label_en': labels['${c['label']}'],
            },
      ];
    }
    await SiteRepo.settingsDoc.set(<String, dynamic>{
      ...settings,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    log('✓ site_settings/main (English)');

    final Map<String, String> colls = <String, String>{
      'services': Coll.services,
      'features': Coll.features,
      'projects': Coll.projects,
      'partners': Coll.partners,
      'testimonials': Coll.testimonials,
    };
    for (final MapEntry<String, String> e in colls.entries) {
      final Object? byId = en[e.key];
      if (byId is! Map) continue;
      int n = 0;
      final WriteBatch batch = SiteRepo.db.batch();
      for (final MapEntry<dynamic, dynamic> item in byId.entries) {
        final Map<String, dynamic> fields = onlyEn(item.value);
        if (fields.isEmpty) continue;
        // Only documents that exist: never re-create one an admin deleted.
        final DocumentReference<Map<String, dynamic>> ref = SiteRepo.db.collection(e.value).doc('${item.key}');
        if (!(await ref.get()).exists) continue;
        batch.set(ref, <String, dynamic>{...fields, 'updated_at': FieldValue.serverTimestamp()}, SetOptions(merge: true));
        n++;
      }
      await batch.commit();
      log('✓ ${e.value} (English): $n');
    }
  }

  // ── WordPress ───────────────────────────────────────────────────────────

  static String _decodeEntities(String s) {
    const Map<String, String> named = <String, String>{
      '&amp;': '&', '&quot;': '"', '&#039;': "'", '&apos;': "'", '&lt;': '<', '&gt;': '>',
      '&nbsp;': ' ', '&hellip;': '…', '&ndash;': '–', '&mdash;': '—', '&laquo;': '«', '&raquo;': '»',
    };
    String out = s.replaceAllMapped(RegExp(r'&#(x?[0-9a-fA-F]+);'), (Match m) {
      final String g = m.group(1)!;
      final int? code = g.startsWith('x') ? int.tryParse(g.substring(1), radix: 16) : int.tryParse(g);
      return code == null ? m.group(0)! : String.fromCharCode(code);
    });
    named.forEach((String k, String v) => out = out.replaceAll(k, v));
    return out;
  }

  static String _stripTags(String html) =>
      _decodeEntities(html.replaceAll(RegExp(r'<[^>]*>'), ' ')).replaceAll(RegExp(r'\s+'), ' ').trim();

  /// WordPress/Elementor wraps content in <div>s and inline styles the
  /// Flutter HTML renderer does not need; drop styles, scripts and the
  /// "related posts" tail, keep the structure.
  static String _cleanHtml(String html) => html
      .replaceAll(RegExp(r'<script[\s\S]*?</script>', caseSensitive: false), '')
      .replaceAll(RegExp(r'<style[\s\S]*?</style>', caseSensitive: false), '')
      .replaceAll(RegExp(r'\s(style|class|id|srcset|sizes|data-[\w-]+)="[^"]*"'), '')
      .replaceAll(RegExp(r'<(/?)(div|span|section)[^>]*>'), '')
      .trim();

  static Future<dynamic> _get(Uri url) async {
    final http.Response r = await http.get(url, headers: <String, String>{'Accept': 'application/json'});
    if (r.statusCode != 200) {
      throw http.ClientException('HTTP ${r.statusCode}', url);
    }
    return jsonDecode(utf8.decode(r.bodyBytes));
  }

  static Future<int> importWordPress(Progress log, {String base = 'https://asecbim.com'}) async {
    final String root = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    final List<Map<String, dynamic>> out = <Map<String, dynamic>>[];
    for (int page = 1; page <= 20; page++) {
      final Uri url = Uri.parse('$root/wp-json/wp/v2/posts').replace(queryParameters: <String, String>{
        'per_page': '100',
        'page': '$page',
        '_embed': 'wp:featuredmedia,wp:term',
      });
      dynamic data;
      try {
        data = await _get(url);
      } on http.ClientException catch (e) {
        // WordPress answers 400 when the page is past the end.
        if (page > 1 && e.message.contains('400')) break;
        rethrow;
      }
      if (data is! List || data.isEmpty) break;
      for (final dynamic p in data) {
        if (p is! Map) continue;
        final Map<String, dynamic> post = Map<String, dynamic>.from(p);
        final Map<String, dynamic> emb =
            post['_embedded'] is Map ? Map<String, dynamic>.from(post['_embedded'] as Map) : <String, dynamic>{};
        String cover = '';
        final Object? media = emb['wp:featuredmedia'];
        if (media is List && media.isNotEmpty && media.first is Map) {
          cover = '${(media.first as Map)['source_url'] ?? ''}';
        }
        String category = '';
        final Object? terms = emb['wp:term'];
        if (terms is List && terms.isNotEmpty && terms.first is List && (terms.first as List).isNotEmpty) {
          final Object? t = (terms.first as List).first;
          if (t is Map) category = _decodeEntities('${t['name'] ?? ''}');
        }
        String rendered(String k) {
          final Object? v = post[k];
          return v is Map ? '${v['rendered'] ?? ''}' : '';
        }

        final DateTime date = DateTime.tryParse('${post['date'] ?? ''}') ?? DateTime.now();
        out.add(<String, dynamic>{
          'id': 'wp_${post['id']}',
          'wp_id': post['id'],
          'slug': Uri.decodeComponent('${post['slug'] ?? ''}'),
          'wp_link': '${post['link'] ?? ''}',
          'title': _decodeEntities(_stripTags(rendered('title'))),
          'excerpt': _stripTags(rendered('excerpt')),
          'body_html': _cleanHtml(rendered('content')),
          'cover': cover,
          'category': category,
          'published_at': Timestamp.fromDate(date),
          'published': true,
        });
      }
      log('… ${out.length}');
      if (data.length < 100) break;
    }
    final int n = await _writeAll(Coll.articles, out);
    log('✓ ${Coll.articles}: $n');

    try {
      final dynamic privacy = await _get(Uri.parse('$root/wp-json/wp/v2/pages/3'));
      if (privacy is Map && privacy['content'] is Map) {
        await SiteRepo.settingsDoc.set(<String, dynamic>{
          'privacy_html': _cleanHtml('${(privacy['content'] as Map)['rendered'] ?? ''}'),
        }, SetOptions(merge: true));
        log('✓ privacy_html');
      }
    } catch (e) {
      log('– privacy page: $e');
    }
    return n;
  }
}
