/// Module: tools / t5_plumbing_fire
///
///*************************** FILE INFO ****************************///
/// File Name: co2_tab.dart
/// Purpose: CO₂ tab — room area and height in; room volume, CO₂ weight
///          and number of 45 kg cylinders out.
/// Author: ASEC team
/// Created: 22/10/2026
library;

import 'package:flutter/material.dart';

import 'package:asec/features/tools/t3_duct_calc/presentation/ui/widgets/duct_fields.dart';
import 'package:asec/features/tools/t5_plumbing_fire/domain/fire_gas.dart';

class Co2Tab extends StatefulWidget {
  const Co2Tab({super.key});

  @override
  State<Co2Tab> createState() => _Co2TabState();
}

class _Co2TabState extends State<Co2Tab> {
  final TextEditingController _area = TextEditingController(text: '50');
  final TextEditingController _height = TextEditingController(text: '3');

  @override
  void dispose() {
    _area.dispose();
    _height.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double? a = parseNumber(_area.text);
    final double? h = parseNumber(_height.text);
    final Co2Result? r = (a == null || h == null || a <= 0 || h <= 0)
        ? null
        : Co2.calculate(areaM2: a, heightM: h);
    void changed(String _) => setState(() {});

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: <Widget>[
        ResponsiveFields(
          children: <Widget>[
            NumberField(controller: _area, label: 'Room area', unit: 'm²', onChanged: changed),
            NumberField(controller: _height, label: 'Room height', unit: 'm', onChanged: changed),
          ],
        ),
        const SizedBox(height: 16),
        if (r == null)
          const Text('Enter the room area and height.')
        else
          ResultTable(
            items: <ResultItem>[
              ResultItem('Room volume (V)', fmt(r.volume, 2), 'm³'),
              ResultItem('Flooding factor', fmt(r.factor, 2), 'kg/m³'),
              ResultItem('Total weight of CO₂ required', fmt(r.weight, 1), 'kg'),
              ResultItem('Weight of one cylinder', fmt(Co2.cylinderKg, 0), 'kg'),
              ResultItem('Number of cylinders required', '${r.cylinders}'),
            ],
          ),
      ],
    );
  }
}
