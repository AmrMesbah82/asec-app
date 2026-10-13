/// Module: tools / t2_engineering_calc
///
///*************************** FILE INFO ****************************///
/// File Name: calcs_plumbing.dart
/// Purpose: The plumbing calculators — water supply demand by fixture units
///          (IPC Appendix E / Hunter's curve), drainage pipe sizes by DFU
///          (IPC 709–710), domestic water tank, booster pump and storm water.
///          Hazen–Williams pipe friction comes from calcs_fire.dart.
/// Author: ASEC team
/// Created: 4/10/2026
///
/// Every compute function receives and returns BASE SI units
/// (see calc_model.dart).

import 'dart:math' as math;

import 'package:asec/features/tools/t2_engineering_calc/domain/calc_model.dart';
import 'package:asec/features/tools/t2_engineering_calc/domain/calc_units.dart';
import 'package:asec/features/tools/t2_engineering_calc/domain/calcs_fire.dart';

// ── Pipe-size text ─────────────────────────────────────────────────────────

const Map<int, String> _dnInch = <int, String>{
  15: '½"', 20: '¾"', 25: '1"', 32: '1¼"', 40: '1½"', 50: '2"', 65: '2½"', //
  80: '3"', 100: '4"', 125: '5"', 150: '6"', 200: '8"', 250: '10"', 300: '12"', 375: '15"',
};

String _dnText(double dn) {
  if (dn.isNaN) return '—';
  final int d = dn.round();
  return 'DN $d (${_dnInch[d] ?? ''})';
}

String _inchText(double inch) {
  final int i = _inches.indexOf(inch);
  if (inch.isNaN || i < 0) return '—';
  final int dn = _inchDns[i];
  return 'DN $dn (${_dnInch[dn]})';
}

// ── 1. Water supply — fixture units ────────────────────────────────────────

/// Water-supply fixture units, IPC Table E103.3(2): [private, public].
const Map<String, List<double>> _wsfu = <String, List<double>>{
  'wcTank': <double>[2.2, 5],
  'wcValve': <double>[5, 10],
  'lav': <double>[0.7, 2],
  'kitchen': <double>[1.4, 4],
  'shower': <double>[1.4, 4],
  'bath': <double>[1.4, 4],
  'urinal': <double>[5, 5],
  'service': <double>[3, 3],
  'dishwasher': <double>[1.4, 1.5],
  'washer': <double>[1.4, 4],
};

/// IPC Table E103.3(3) — Hunter's curve, WSFU → demand gpm.
const List<List<double>> _tankCurve = <List<double>>[
  <double>[0, 0], <double>[1, 3], <double>[2, 5], <double>[3, 6.5], <double>[4, 8],
  <double>[5, 9.4], <double>[6, 10.7], <double>[7, 11.8], <double>[8, 12.8],
  <double>[9, 13.7], <double>[10, 14.6], <double>[11, 15.4], <double>[12, 16],
  <double>[13, 16.5], <double>[14, 17], <double>[15, 17.5], <double>[16, 18],
  <double>[17, 18.4], <double>[18, 18.8], <double>[19, 19.2], <double>[20, 19.6],
  <double>[25, 21.5], <double>[30, 23.3], <double>[35, 24.9], <double>[40, 26.3],
  <double>[45, 27.7], <double>[50, 29.1], <double>[60, 32], <double>[70, 35],
  <double>[80, 38], <double>[90, 41], <double>[100, 43.5], <double>[120, 48],
  <double>[140, 52.5], <double>[160, 57], <double>[180, 61], <double>[200, 65],
  <double>[225, 70], <double>[250, 75], <double>[275, 80], <double>[300, 85],
  <double>[400, 105], <double>[500, 124], <double>[750, 170], <double>[1000, 208],
  <double>[1250, 239], <double>[1500, 269], <double>[1750, 297], <double>[2000, 325],
  <double>[2500, 380], <double>[3000, 433], <double>[4000, 525], <double>[5000, 593],
];

const List<List<double>> _valveCurve = <List<double>>[
  <double>[5, 15], <double>[6, 17.4], <double>[7, 19.8], <double>[8, 22.2],
  <double>[9, 24.6], <double>[10, 27], <double>[11, 27.8], <double>[12, 28.6],
  <double>[13, 29.4], <double>[14, 30.2], <double>[15, 31], <double>[16, 31.8],
  <double>[17, 32.6], <double>[18, 33.4], <double>[19, 34.2], <double>[20, 35],
  <double>[25, 38], <double>[30, 42], <double>[35, 44], <double>[40, 46],
  <double>[45, 48], <double>[50, 50], <double>[60, 54], <double>[70, 58],
  <double>[80, 61.2], <double>[90, 64.3], <double>[100, 67.5], <double>[120, 73],
  <double>[140, 77], <double>[160, 81], <double>[180, 85.5], <double>[200, 90],
  <double>[225, 95.5], <double>[250, 101], <double>[275, 104.5], <double>[300, 108],
  <double>[400, 127], <double>[500, 143], <double>[750, 177], <double>[1000, 208],
  <double>[1250, 239], <double>[1500, 269], <double>[1750, 297], <double>[2000, 325],
  <double>[2500, 380], <double>[3000, 433], <double>[4000, 525], <double>[5000, 593],
];

double _interpolate(List<List<double>> curve, double x) {
  if (x <= curve.first[0]) return x <= 0 ? 0.0 : curve.first[1];
  for (int i = 1; i < curve.length; i++) {
    if (x <= curve[i][0]) {
      final List<double> a = curve[i - 1];
      final List<double> b = curve[i];
      return a[1] + (b[1] - a[1]) * (x - a[0]) / (b[0] - a[0]);
    }
  }
  final List<double> a = curve[curve.length - 2];
  final List<double> b = curve.last;
  return b[1] + (b[1] - a[1]) * (x - b[0]) / (b[0] - a[0]);
}

const List<int> _dnSizes = <int>[15, 20, 25, 32, 40, 50, 65, 80, 100, 125, 150, 200, 250, 300];

Map<String, double> _waterSupply(Map<String, double> v) {
  final int occ = v['occupancy']!.round();
  double total = 0;
  _wsfu.forEach((String id, List<double> fu) => total += v[id]! * fu[occ]);
  final double gpm =
      _interpolate(v['wcValve']! > 0 ? _valveCurve : _tankCurve, total);
  final double q = gpm * K.gpm;
  final double dMin = math.sqrt(4 * q / (math.pi * v['maxVel']!));
  final int dn = _dnSizes.firstWhere((int s) => s >= dMin * 1000 - 1e-9, orElse: () => -1);
  return <String, double>{
    'wsfu': total,
    'flow': q,
    'minDia': dMin,
    'dn': total <= 0 || dn < 0 ? double.nan : dn.toDouble(),
  };
}

const EngCalc waterSupply = EngCalc(
  id: 'waterSupply',
  en: 'Water supply (fixture units)',
  ar: 'تغذية المياه (وحدات الأجهزة)',
  fields: <CalcField>[
    CalcField.choice('occupancy', 'Use', 'نوع الاستخدام', <CalcChoice>[
      CalcChoice('Private (homes, apartments)', 'خاص (منازل، شقق)'),
      CalcChoice('Public (offices, schools, malls)', 'عام (مكاتب، مدارس، مولات)'),
    ]),
    CalcField('wcTank', 'Water closet — flush tank', 'مرحاض — صندوق طرد', def: 2),
    CalcField('wcValve', 'Water closet — flush valve', 'مرحاض — فلاش فالف', def: 0),
    CalcField('lav', 'Lavatory (wash basin)', 'حوض غسيل الأيدي', def: 2),
    CalcField('kitchen', 'Kitchen sink', 'حوض مطبخ', def: 1),
    CalcField('shower', 'Shower', 'دش', def: 2),
    CalcField('bath', 'Bathtub', 'بانيو', def: 0),
    CalcField('urinal', 'Urinal (flush valve)', 'مبولة (فلاش فالف)', def: 0),
    CalcField('service', 'Service / mop sink', 'حوض خدمة', def: 0),
    CalcField('dishwasher', 'Dishwasher', 'غسالة أطباق', def: 0),
    CalcField('washer', 'Washing machine', 'غسالة ملابس', def: 1),
    CalcField('maxVel', 'Maximum velocity', 'أقصى سرعة', qty: Q.waterSpeed, def: 2),
  ],
  results: <CalcResult>[
    CalcResult('wsfu', 'Total fixture units', 'إجمالي وحدات الأجهزة', unit: 'WSFU'),
    CalcResult('flow', 'Probable peak flow', 'أقصى تصرف محتمل', qty: Q.waterFlow, primary: true),
    CalcResult('minDia', 'Minimum internal diameter', 'أقل قطر داخلي', qty: Q.diameter),
    CalcResult('dn', 'Suggested pipe size', 'المقاس المقترح للماسورة', text: _dnText, primary: true),
  ],
  compute: _waterSupply,
  formula: 'WSFU = Σ (count × fixture units)\n'
      'Peak flow = Hunter\'s curve (IPC Table E103.3(3))\n'
      '   flush-valve curve when there are flush-valve WCs\n'
      'D = √(4Q ÷ πV)',
  noteEn: 'Fixture units from IPC Table E103.3(2) (hot + cold combined). For a hot or '
      'cold branch alone, take about ¾ of the fixture units. Pipe size assumes the '
      'internal diameter is close to DN — check against your pipe material.',
  noteAr: 'وحدات الأجهزة من جدول E103.3(2) في IPC (ساخن + بارد معًا). لفرع ساخن فقط أو '
      'بارد فقط خذ حوالي ¾ الوحدات. المقاس يفترض أن القطر الداخلي قريب من DN — '
      'راجعه حسب خامة الماسورة.',
);

// ── 2. Drainage — DFU ──────────────────────────────────────────────────────

/// Drainage fixture units, IPC Table 709.1.
const Map<String, double> _dfu = <String, double>{
  'wc': 4, 'lav': 1, 'shower': 2, 'bath': 2, 'kitchen': 2, 'urinal': 4, //
  'floorDrain': 2, 'dishwasher': 2, 'washer': 2, 'service': 3,
};

const List<double> _inches = <double>[1.25, 1.5, 2, 2.5, 3, 4, 5, 6, 8, 10, 12, 15];
const List<int> _inchDns = <int>[32, 40, 50, 65, 80, 100, 125, 150, 200, 250, 300, 375];

/// Max DFU per size — IPC Table 710.1(2). 0 = not allowed.
const List<double> _branchMax = <double>[0, 3, 6, 12, 20, 160, 360, 620, 1400, 2500, 3900, 7000];
const List<double> _stackShortMax = <double>[0, 4, 10, 20, 48, 240, 540, 960, 2200, 3800, 6000, 0];
const List<double> _stackTallMax = <double>[0, 8, 24, 42, 72, 500, 1100, 1900, 3600, 5600, 8400, 0];

/// Building drain — IPC Table 710.1(1): slope 1/8, 1/4, 1/2 in. per ft.
const List<List<double>> _drainMax = <List<double>>[
  <double>[0, 0, 0, 0, 36, 180, 390, 700, 1600, 2900, 4600, 8300],
  <double>[1, 3, 21, 24, 42, 216, 480, 840, 1920, 3500, 5600, 10000],
  <double>[1, 3, 26, 31, 50, 250, 575, 1000, 2300, 4200, 6700, 12000],
];

double _pick(List<double> capacity, double dfu, double minInch) {
  for (int i = 0; i < _inches.length; i++) {
    if (_inches[i] < minInch) continue;
    if (capacity[i] >= dfu) return _inches[i];
  }
  return double.nan;
}

Map<String, double> _drainage(Map<String, double> v) {
  double dfu = 0;
  _dfu.forEach((String id, double u) => dfu += v[id]! * u);
  if (dfu <= 0) {
    return <String, double>{'dfu': 0, 'branch': double.nan, 'stack': double.nan, 'drain': double.nan};
  }
  final double minInch = v['wc']! > 0 ? 3.0 : 1.25;
  return <String, double>{
    'dfu': dfu,
    'branch': _pick(_branchMax, dfu, minInch),
    'stack': _pick(v['floors']!.round() == 0 ? _stackShortMax : _stackTallMax, dfu, minInch),
    'drain': _pick(_drainMax[v['slope']!.round()], dfu, minInch),
  };
}

const EngCalc drainage = EngCalc(
  id: 'drainage',
  en: 'Drainage (DFU pipe sizes)',
  ar: 'الصرف (مقاسات المواسير بوحدات الصرف)',
  fields: <CalcField>[
    CalcField('wc', 'Water closet', 'مرحاض', def: 2),
    CalcField('lav', 'Lavatory (wash basin)', 'حوض غسيل الأيدي', def: 2),
    CalcField('shower', 'Shower', 'دش', def: 2),
    CalcField('bath', 'Bathtub', 'بانيو', def: 0),
    CalcField('kitchen', 'Kitchen sink', 'حوض مطبخ', def: 1),
    CalcField('urinal', 'Urinal', 'مبولة', def: 0),
    CalcField('floorDrain', 'Floor drain', 'صفاية أرضية', def: 2),
    CalcField('dishwasher', 'Dishwasher', 'غسالة أطباق', def: 0),
    CalcField('washer', 'Washing machine', 'غسالة ملابس', def: 1),
    CalcField('service', 'Service / mop sink', 'حوض خدمة', def: 0),
    CalcField.choice('floors', 'Stack', 'العمود (الصاعد)', <CalcChoice>[
      CalcChoice('Up to 3 branch intervals (floors)', 'حتى 3 أدوار'),
      CalcChoice('More than 3 branch intervals', 'أكثر من 3 أدوار'),
    ]),
    CalcField.choice('slope', 'Building drain slope', 'ميل خط الصرف الرئيسي', <CalcChoice>[
      CalcChoice('1% (⅛" per ft)', '1% (⅛ بوصة لكل قدم)'),
      CalcChoice('2% (¼" per ft)', '2% (¼ بوصة لكل قدم)'),
      CalcChoice('4% (½" per ft)', '4% (½ بوصة لكل قدم)'),
    ], defOption: 1),
  ],
  results: <CalcResult>[
    CalcResult('dfu', 'Total drainage fixture units', 'إجمالي وحدات الصرف', unit: 'DFU', primary: true),
    CalcResult('branch', 'Horizontal fixture branch', 'الفرع الأفقي للأجهزة', text: _inchText),
    CalcResult('stack', 'Soil / waste stack', 'عمود الصرف', text: _inchText),
    CalcResult('drain', 'Building drain / sewer', 'خط الصرف الرئيسي للمبنى', text: _inchText, primary: true),
  ],
  compute: _drainage,
  formula: 'DFU = Σ (count × fixture units)   (IPC Table 709.1)\n'
      'Branch & stack: IPC Table 710.1(2)\n'
      'Building drain: IPC Table 710.1(1) at the chosen slope',
  noteEn: 'Any pipe that carries a water closet is at least 3" (DN 80 — DN 110 in uPVC). '
      'Venting is not included.',
  noteAr: 'أي ماسورة تحمل صرف مرحاض لا تقل عن 3 بوصة (DN 80 — 110 مم في uPVC). '
      'التهوية غير محسوبة هنا.',
);

// ── 3. Domestic water tank ─────────────────────────────────────────────────

Map<String, double> _waterTank(Map<String, double> v) {
  final double daily = v['people']! * v['perCapita']! / 1000; // m³/day
  final double domestic = daily * v['days']! / 86400;
  return <String, double>{
    'daily': daily,
    'domestic': domestic,
    'total': domestic + v['fireReserve']!,
    'avgFlow': daily / 86400,
  };
}

const EngCalc waterTank = EngCalc(
  id: 'waterTank',
  en: 'Domestic water tank',
  ar: 'خزان المياه المنزلية',
  fields: <CalcField>[
    CalcField.choice('building', 'Building type', 'نوع المبنى', <CalcChoice>[
      CalcChoice('Residential', 'سكني', <String, double>{'perCapita': 200}),
      CalcChoice('Office (per employee)', 'إداري (لكل موظف)', <String, double>{'perCapita': 50}),
      CalcChoice('School (per student)', 'مدرسة (لكل طالب)', <String, double>{'perCapita': 50}),
      CalcChoice('Hotel (per guest)', 'فندق (لكل نزيل)', <String, double>{'perCapita': 300}),
      CalcChoice('Hospital (per bed)', 'مستشفى (لكل سرير)', <String, double>{'perCapita': 450}),
      CalcChoice('Custom', 'قيمة مخصصة'),
    ]),
    CalcField('people', 'Number of people / beds', 'عدد الأشخاص / الأسرّة', def: 100),
    CalcField('perCapita', 'Daily consumption', 'الاستهلاك اليومي', qty: Q.perCapita, def: 200),
    CalcField('days', 'Storage', 'مدة التخزين', qty: Q.days, def: 1),
    CalcField('fireReserve', 'Fire reserve (if the tank is shared)', 'احتياطي الحريق (لو الخزان مشترك)', qty: Q.tank, def: 0),
  ],
  results: <CalcResult>[
    CalcResult('daily', 'Daily demand', 'الاحتياج اليومي', qty: Q.tank),
    CalcResult('domestic', 'Domestic storage', 'تخزين المياه المنزلية', qty: Q.tank),
    CalcResult('total', 'Total tank volume', 'الحجم الكلي للخزان', qty: Q.tank, primary: true),
    CalcResult('avgFlow', 'Average flow', 'متوسط التصرف', qty: Q.waterFlow),
  ],
  compute: _waterTank,
  formula: 'Daily = people × consumption\nTank = daily × days + fire reserve',
  noteEn: 'Consumption presets are typical values — use the figure from your local code '
      'or the client brief.',
  noteAr: 'قيم الاستهلاك الجاهزة قيم معتادة — استخدم الرقم المطلوب في الكود المحلي أو '
      'متطلبات العميل.',
);

// ── 4. Booster pump ────────────────────────────────────────────────────────

Map<String, double> _boosterPump(Map<String, double> v) {
  final double p = v['minP']! + 1000 * K.g * v['height']! + v['friction']! - v['suction']!;
  return <String, double>{
    'pressure': p,
    'head': p,
    'power': v['flow']! * p / (v['eff']! / 100),
  };
}

const EngCalc boosterPump = EngCalc(
  id: 'boosterPump',
  en: 'Booster pump',
  ar: 'طلمبة رفع الضغط',
  fields: <CalcField>[
    CalcField('flow', 'Design flow', 'التصرف التصميمي', qty: Q.waterFlow, def: 3),
    CalcField('height', 'Height of highest fixture above the pump', 'ارتفاع أعلى جهاز فوق الطلمبة', qty: Q.length, def: 30),
    CalcField('minP', 'Pressure needed at the highest fixture', 'الضغط المطلوب عند أعلى جهاز', qty: Q.barPsi, def: 1.5),
    CalcField('friction', 'Pipe friction losses', 'فقد الاحتكاك في المواسير', qty: Q.barPsi, def: 0.5),
    CalcField('suction', 'Suction pressure (+ flooded / − lift)', 'ضغط السحب (+ سحب موجب / − رفع)', qty: Q.barPsi, def: 0),
    CalcField('eff', 'Pump efficiency', 'كفاءة الطلمبة', unit: '%', def: 65),
  ],
  results: <CalcResult>[
    CalcResult('pressure', 'Pump pressure', 'ضغط الطلمبة', qty: Q.barPsi, primary: true),
    CalcResult('head', 'Pump head', 'رفع الطلمبة', qty: Q.head),
    CalcResult('power', 'Shaft power', 'قدرة العمود', qty: Q.motor, primary: true),
  ],
  compute: _boosterPump,
  formula: 'P = P fixture + ρ·g·h + friction − suction\nPower = Q·P ÷ η',
  noteEn: 'Usual fixture pressure: about 1 bar (15 psi) for tank WCs and taps, 1.7–2 bar '
      '(25–30 psi) for flush valves. Keep the pressure at the lowest floors under about '
      '5.5 bar (80 psi) — add pressure-reducing valves if needed.',
  noteAr: 'الضغط المعتاد عند الأجهزة: حوالي 1 بار (15 psi) للخلاطات وصناديق الطرد، و1.7–2 '
      'بار (25–30 psi) للفلاش فالف. اجعل الضغط في الأدوار السفلى أقل من حوالي 5.5 بار '
      '(80 psi) — أضف محابس تخفيض ضغط عند الحاجة.',
);

// ── 5. Storm water ─────────────────────────────────────────────────────────

Map<String, double> _stormWater(Map<String, double> v) {
  final double q = v['c']! * v['intensity']! / 1000 / 3600 * v['area']!;
  return <String, double>{'flow': q};
}

const EngCalc stormWater = EngCalc(
  id: 'stormWater',
  en: 'Storm water (roof drains)',
  ar: 'مياه الأمطار (صفايات الأسطح)',
  fields: <CalcField>[
    CalcField('area', 'Roof / catchment area', 'مساحة السطح / التجميع', qty: Q.area, def: 500),
    CalcField('intensity', 'Rainfall intensity', 'شدة المطر', qty: Q.rainfall, def: 50),
    CalcField('c', 'Runoff coefficient (roofs ≈ 1.0)', 'معامل الجريان (الأسطح ≈ 1.0)', def: 1),
  ],
  results: <CalcResult>[
    CalcResult('flow', 'Storm water flow', 'تصرف مياه الأمطار', qty: Q.waterFlow, primary: true),
  ],
  compute: _stormWater,
  formula: 'Q = C × i × A',
  noteEn: 'Use the rainfall intensity your local code or authority gives for your city '
      '(often the 1-hour, 100-year storm).',
  noteAr: 'استخدم شدة المطر التي يحددها الكود المحلي أو الجهة المختصة لمدينتك (غالبًا '
      'عاصفة ساعة واحدة كل 100 سنة).',
);

const List<EngCalc> plumbingCalcs = <EngCalc>[
  waterSupply,
  drainage,
  waterTank,
  boosterPump,
  stormWater,
  pipeFriction,
];
