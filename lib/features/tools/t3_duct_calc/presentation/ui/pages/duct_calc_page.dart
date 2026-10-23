/// Module: tools / t3_duct_calc
///
///*************************** FILE INFO ****************************///
/// File Name: duct_calc_page.dart
/// Purpose: Declares `DuctCalcPage` — the Ducts tab: Duct Sizer and
///          Flexible Duct, switched with the app's CustomTabs.
/// Author: ASEC team
/// Created: 21/10/2026
/// Updated: 22/10/2026 - Shows its title (ConsolePage header) like the
///          converter and the engineering calculators.
/// Updated: 23/10/2026 - Only two tabs left: Duct Sizer and Flexible Duct
///          (was Round Duct); Rectangular, Velocities and Conversions removed.
///
/// WORKS OFFLINE — everything is computed on the device. Built only from
/// the app's own controls (CustomTabs, CustomTextField, CustomDropdown,
/// CustomCheckBox, AppDataTable), with their default look.
library;

import 'package:flutter/material.dart';

import 'package:asec/core/custom/10-custom_tabs.dart';
import 'package:asec/features/admin/a1_shell/presentation/ui/widgets/console_page.dart';
import 'package:asec/generated/l10n.dart';
import 'package:asec/features/tools/t3_duct_calc/presentation/ui/widgets/duct_sizer_tab.dart';
import 'package:asec/features/tools/t3_duct_calc/presentation/ui/widgets/round_duct_tab.dart';

class DuctCalcPage extends StatefulWidget {
  const DuctCalcPage({super.key});

  @override
  State<DuctCalcPage> createState() => _DuctCalcPageState();
}

class _DuctCalcPageState extends State<DuctCalcPage> {
  int _tab = 0;

  static const List<String> _titles = <String>[
    'Duct Sizer',
    'Flexible Duct',
  ];

  @override
  Widget build(BuildContext context) {
    // Titled like the other calculators (ConsolePage header).
    return ConsolePage(
      title: S.of(context).ductCalc,
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
                DuctSizerTab(),
                FlexibleDuctTab(),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}
