/// Module: tools / t5_plumbing_fire
///
///*************************** FILE INFO ****************************///
/// File Name: fire_calc_page.dart
/// Purpose: Declares `FireCalcPage` — the Fire fighting calculator
///          (FM-200), its own entry in the calculators list.
/// Author: ASEC team
/// Created: 23/10/2026
///
/// WORKS OFFLINE — computed on the device. Titled with the ConsolePage
/// header like the other calculators.
library;

import 'package:flutter/material.dart';

import 'package:asec/features/admin/a1_shell/presentation/ui/widgets/console_page.dart';
import 'package:asec/generated/l10n.dart';
import 'package:asec/features/tools/t5_plumbing_fire/presentation/ui/widgets/fm200_tab.dart';

class FireCalcPage extends StatelessWidget {
  const FireCalcPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ConsolePage(
      title: S.of(context).fireCalc,
      child: const Material(
        type: MaterialType.transparency,
        child: Fm200Tab(),
      ),
    );
  }
}
