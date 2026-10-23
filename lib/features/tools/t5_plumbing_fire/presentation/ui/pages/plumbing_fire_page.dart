/// Module: tools / t5_plumbing_fire
///
///*************************** FILE INFO ****************************///
/// File Name: plumbing_fire_page.dart
/// Purpose: Declares `PlumbingFirePage` — the Plumbing calculator: Storm
///          water and Hot water, switched with the app's CustomTabs.
///          (FM-200 moved to `FireCalcPage`.)
/// Author: ASEC team
/// Created: 22/10/2026
/// Updated: 22/10/2026 - Shows its title (ConsolePage header) like the
///          converter and the engineering calculators.
/// Updated: 23/10/2026 - Plumbing only (Storm Water, Hot Water); FM-200
///          moved to its own Fire calculator, CO₂ tab removed.
///
/// WORKS OFFLINE — computed on the device. Built from the app's own
/// controls (CustomTabs, CustomTextField, CustomDropdown, AppDataTable,
/// customButton), the same way as the duct calculator.
library;

import 'package:flutter/material.dart';

import 'package:asec/core/custom/10-custom_tabs.dart';
import 'package:asec/features/admin/a1_shell/presentation/ui/widgets/console_page.dart';
import 'package:asec/generated/l10n.dart';
import 'package:asec/features/tools/t5_plumbing_fire/presentation/ui/widgets/hot_water_tab.dart';
import 'package:asec/features/tools/t5_plumbing_fire/presentation/ui/widgets/storm_water_tab.dart';

class PlumbingFirePage extends StatefulWidget {
  const PlumbingFirePage({super.key});

  @override
  State<PlumbingFirePage> createState() => _PlumbingFirePageState();
}

class _PlumbingFirePageState extends State<PlumbingFirePage> {
  int _tab = 0;

  static const List<String> _titles = <String>[
    'Storm Water',
    'Hot Water',
  ];

  @override
  Widget build(BuildContext context) {
    // Titled like the other calculators (ConsolePage header).
    return ConsolePage(
      title: S.of(context).plumbingFireCalc,
      child: Material(
      type: MaterialType.transparency,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.zero,
            child: CustomTabs(
              tabs: _titles,
              selectedValue: _tab,
              onChanged: (int i) => setState(() => _tab = i),
            ),
          ),
          // IndexedStack keeps every tab's inputs while switching.
          Expanded(
            child: IndexedStack(
              index: _tab,
              children: const <Widget>[
                StormWaterTab(),
                HotWaterTab(),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}
