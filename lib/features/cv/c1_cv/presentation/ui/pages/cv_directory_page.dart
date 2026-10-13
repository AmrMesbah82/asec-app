/// Module: cv / c1_cv
///
///*************************** FILE INFO ****************************///
/// File Name: cv_directory_page.dart
/// Purpose: Declares `CvDirectoryPage` — every CV in the centre, searchable.
/// Author: ASEC team
/// Created: 20/9/2026
///
/// ONE PAGE, TWO AUDIENCES. Members browse each other's CVs here; the admin
/// sees the same list with the review state on every card and delete inside.
/// [isAdmin] is the only difference, and it changes what is SHOWN, never what
/// is read — the rules let every signed-in account read the directory.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/custom/110-app_widgets.dart';
import 'package:asec/core/custom/69-cross_axis_count_helper.dart';
import 'package:asec/core/custom/1-custom_dropdown.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/features/admin/a1_shell/presentation/ui/widgets/console_page.dart';
import 'package:asec/features/cv/c1_cv/data/repository/cv_repository.dart';
import 'package:asec/features/cv/c1_cv/domain/base_repository/cv_base_repository.dart';
import 'package:asec/features/cv/c1_cv/domain/entities/cv_profile.dart';
import 'package:asec/features/cv/c1_cv/presentation/ui/pages/cv_detail_page.dart';
import 'package:asec/features/cv/c1_cv/presentation/ui/widgets/cv_card.dart';
import 'package:asec/generated/l10n.dart';

class CvDirectoryPage extends StatefulWidget {
  const CvDirectoryPage({super.key, this.isAdmin = false});

  final bool isAdmin;

  @override
  State<CvDirectoryPage> createState() => _CvDirectoryPageState();
}

class _CvDirectoryPageState extends State<CvDirectoryPage> {
  final CvBaseRepository _repository = CvRepository();
  final TextEditingController _search = TextEditingController();
  late final Stream<List<CvProfile>> _cvs = _repository.watchAll();

  static const String _allRoles = '__all__';
  String _roleFilter = _allRoles;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Search covers name, email, role, specialization, location and every
  /// skill — one box, because the reader does not know which field holds the
  /// word they remember.
  List<CvProfile> _visible(List<CvProfile> all) {
    final String query = _search.text.trim().toLowerCase();
    return all.where((CvProfile cv) {
      if (_roleFilter != _allRoles && cv.role != _roleFilter) return false;
      if (query.isEmpty) return true;
      return cv.searchIndex.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<List<CvProfile>>(
        stream: _cvs,
        builder: (BuildContext context, AsyncSnapshot<List<CvProfile>> snap) {
          if (snap.hasError) return AppErrorView(message: s.errUnknown);
          if (!snap.hasData) return const AppLoading();

          final List<CvProfile> all = snap.data!;
          if (all.isEmpty) {
            return ConsolePage(
              title: s.cvs,
              subtitle: widget.isAdmin ? s.cvAdminSub : s.cvDirectorySub,
              child: AppEmptyView(
                title: s.noCvsTitle,
                subtitle: widget.isAdmin ? s.noCvsSubAdmin : s.noCvsSubUser,
              ),
            );
          }

          final List<CvProfile> rows = _visible(all);

          // The roles are taken from the CVs that exist, not from the full
          // role list: a choice that filters to nothing is a dead end.
          final Map<String, int> roleCounts = <String, int>{};
          for (final CvProfile cv in all) {
            if (cv.role.isEmpty) continue;
            roleCounts[cv.role] = (roleCounts[cv.role] ?? 0) + 1;
          }

          return ConsolePage(
            title: s.cvs,
            subtitle: widget.isAdmin ? s.cvAdminSub : s.cvDirectorySub,
            actions: <Widget>[
              ConsoleSearchField(
                hint: s.searchCv,
                onChanged: (String value) => setState(() {
                  _search.text = value;
                }),
              ),
              // A DROPDOWN, not a row of chips: with many roles the chips ran
              // off the screen on a phone. Each role shows how many CVs it has.
              SizedBox(
                width: 240.w,
                height: kConsoleControlHeight.h,
                child: CustomDropdown<String>(
                  value: _roleFilter,
                  height: kConsoleControlHeight.h,
                  maxOverlayHeight: 360,
                  prefixIcon: Icon(
                    Icons.filter_list_rounded,
                    size: 18,
                    color: AppColors.secondaryText,
                  ),
                  items: <DropdownItem<String>>[
                    DropdownItem<String>(
                      value: _allRoles,
                      label: '${s.all} (${all.length})',
                    ),
                    for (final MapEntry<String, int> e in roleCounts.entries)
                      DropdownItem<String>(
                        value: e.key,
                        label: '${e.key} (${e.value})',
                      ),
                  ],
                  onChanged: (String key) => setState(() => _roleFilter = key),
                ),
              ),
            ],
            child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return CustomScrollView(
                slivers: <Widget>[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          SizedBox(height: 14.h),
                        ],
                      ),
                    ),
                  ),
                  if (rows.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: AppEmptyView(
                        title: s.noRowsMatch,
                        subtitle: s.noAttemptsMatchSub,
                        size: 130,
                      ),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.only(bottom: 24.h),
                      sliver: SliverGrid(
                        gridDelegate: CrossAxisCountHelper.gridDelegate(
                          context,
                          mainAxisExtent: 210,
                          minCellWidth: 300,
                          availableWidth: constraints.maxWidth,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (BuildContext context, int index) {
                            final CvProfile cv = rows[index];
                            return CvCard(
                              cv: cv,
                              showStatus: widget.isAdmin,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => CvDetailPage(
                                    cv: cv,
                                    isAdmin: widget.isAdmin,
                                  ),
                                ),
                              ),
                            );
                          },
                          childCount: rows.length,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          );
        },
      ),
    );
  }
}
