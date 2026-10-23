/// Module: tools / t3_duct_calc
///
///*************************** FILE INFO ****************************///
/// File Name: round_duct_tab.dart
/// Purpose: Flexible Duct tab — air flow (l/s) and a diameter
///          (100 / 150 / 200 / 250 / 300 mm) in; velocity and pressure
///          drop per metre out. Always flexible duct, length fixed at 1 m.
/// Author: ASEC team
/// Created: 21/10/2026
/// Updated: 23/10/2026 - Renamed to Flexible Duct: duct length and duct
///          type removed (1 m, flexible), diameter picked from a dropdown,
///          only Vel and dP shown.
library;

import 'package:flutter/material.dart';

import 'package:asec/core/custom/1-custom_dropdown.dart';
import 'package:asec/core/custom/100-custom_data_table.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/features/tools/t3_duct_calc/domain/duct_calculator.dart';
import 'package:asec/features/tools/t3_duct_calc/domain/duct_data.dart';
import 'package:asec/features/tools/t3_duct_calc/presentation/ui/widgets/duct_fields.dart';

/// Diameters (mm) offered by the Flexible Duct dropdown.
const List<int> kFlexibleDuctDiametersMm = <int>[100, 150, 200, 250, 300];

class FlexibleDuctTab extends StatefulWidget {
  const FlexibleDuctTab({super.key});

  @override
  State<FlexibleDuctTab> createState() => _FlexibleDuctTabState();
}

class _FlexibleDuctTabState extends State<FlexibleDuctTab> {
  /// Duct length is fixed at 1 m (dP is per metre).
  static const double _lengthM = 1;

  final TextEditingController _flow = TextEditingController(text: '183.7');
  int _diameterMm = kFlexibleDuctDiametersMm.first;

  @override
  void dispose() {
    _flow.dispose();
    super.dispose();
  }

  List<RoundDuctRow> _rows() {
    final double? q = parseNumber(_flow.text);
    if (q == null || q <= 0) return const <RoundDuctRow>[];
    return DuctCalculator.roundTable(
      flowLs: q,
      lengthM: _lengthM,
      type: RoundDuctType.flexible,
      diametersMm: <int>[_diameterMm],
    );
  }

  List<AppTableColumn<RoundDuctRow>> _columns() {
    AppTableColumn<RoundDuctRow> col(
      String label,
      String Function(RoundDuctRow r) value, {
      bool emphasis = false,
    }) {
      return AppTableColumn<RoundDuctRow>(
        label: label,
        cell: (BuildContext context, RoundDuctRow r) =>
            AppTableCellText(value(r), emphasis: emphasis),
      );
    }

    return <AppTableColumn<RoundDuctRow>>[
      col('Ø (mm)', (RoundDuctRow r) => 'Ø ${r.diameterMm} mm', emphasis: true),
      col('Vel (m/s)', (RoundDuctRow r) => fmt(r.velocity, 2)),
      col('dP (Pa/m)', (RoundDuctRow r) => fmt(r.pressureDropPerMetre, 1)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final List<RoundDuctRow> rows = _rows();
    final List<AppTableColumn<RoundDuctRow>> columns = _columns();

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: <Widget>[
        ResponsiveFields(
          children: <Widget>[
            NumberField(
              controller: _flow,
              label: 'Air volume flow',
              unit: 'l/s',
              onChanged: (_) => setState(() {}),
            ),
            SizedBox(
              width: 240,
              child: CustomDropdown<int>(
                fillColor: AppColors.card,
                label: 'Diameter (mm)',
                value: _diameterMm,
                items: <DropdownItem<int>>[
                  for (final int d in kFlexibleDuctDiametersMm)
                    DropdownItem<int>(value: d, label: '$d'),
                ],
                onChanged: (int? d) {
                  if (d != null) setState(() => _diameterMm = d);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (rows.isEmpty)
          const Text('Enter the air flow.')
        else
          AppDataTable<RoundDuctRow>(
            shrinkWrap: true,
            rows: rows,
            columns: columns,
            // Phone / tablet: one full-width card.
            cardBuilder: (BuildContext context, RoundDuctRow r) =>
                ductCard<RoundDuctRow>(context, r, columns),
          ),
      ],
    );
  }
}
