/// Module: cv / c1_cv
///
///*************************** FILE INFO ****************************///
/// File Name: cv_options.dart
/// Purpose: Declares `CvOptions` — every closed list a CV field picks from.
/// Author: ASEC team
/// Created: 20/9/2026
///
/// The lists are ENGX's, field for field, so a CV written here holds the same
/// data an ENGX CV does. Only the wording of the UI around them is ours.
///
/// WHY CLOSED LISTS AT ALL: free text in `specialization` gives you "Civil",
/// "civil eng.", "Civil Engineering" and a directory nobody can filter. A
/// fixed list is what makes the CV browsable.

abstract final class CvOptions {
  const CvOptions._();

  static const List<String> governorates = <String>[
    'Cairo', 'Giza', 'Alexandria', 'Dakahlia', 'Red Sea', 'Beheira',
    'Fayoum', 'Gharbia', 'Ismailia', 'Menofia', 'Minya', 'Qalyubia',
    'New Valley', 'North Sinai', 'Port Said', 'Sharqia', 'South Sinai',
    'Suez', 'Aswan', 'Assiut', 'Beni Suef', 'Kafr El Sheikh', 'Luxor',
    'Matruh', 'Qena', 'Sohag',
  ];

  static const List<String> militaryStatus = <String>[
    'Exempted',
    'Completed',
    'Postponed',
    'Not Applicable',
  ];

  /// 2015 up to and including the current year, newest first — the year a
  /// list like this is scrolled to most often is the recent end.
  static List<String> graduationYears() {
    final int thisYear = DateTime.now().year;
    return <String>[
      for (int y = thisYear; y >= 2015; y--) '$y',
    ];
  }

  static const List<String> specializations = <String>[
    'Civil Engineering',
    'Mechanical Engineering',
    'Electrical Engineering',
    'Chemical Engineering',
    'Industrial Engineering',
    'Computer Engineering',
    'Electronics Engineering',
    'Architecture Engineering',
  ];

  static const List<String> roles = <String>[
    'Site Engineer',
    'Technical Office Engineer',
    'Procurement Engineer',
    'Sales Engineer',
    'Tendering Engineer',
  ];

  static const List<String> languages = <String>[
    'Arabic',
    'English',
    'French',
    'Other',
  ];

  static const List<String> softSkills = <String>[
    'Communication Skills',
    'Teamwork',
    'Time Management',
    'Problem Solving',
    'Attention to Detail',
    'Adaptability',
    'Work Under Pressure',
    'Self-Learning',
    'Responsibility',
  ];

  /// The professional skills offered depend on the ROLE, not the
  /// specialization: a site engineer and a tendering engineer in the same
  /// discipline reach for different tools.
  static const Map<String, List<String>> skillsByRole = <String, List<String>>{
    'Site Engineer': <String>[
      'AutoCAD', 'Site Supervision', 'Quality Control',
      'Construction Management', 'BOQ', 'Shop Drawings', 'As-Built Drawings',
      'Daily Reports', 'Material Inspection', 'Safety Management',
      'Setting Out', 'Subcontractor Management',
    ],
    'Technical Office Engineer': <String>[
      'AutoCAD', 'Revit', 'Shop Drawings', 'As-Built Drawings', 'BOQ',
      'Quantity Surveying', 'Technical Submittals', 'RFI Management',
      'Material Approvals', 'Cost Estimation', 'MS Office', 'Coordination',
    ],
    'Procurement Engineer': <String>[
      'Procurement Management', 'Supply Chain', 'Vendor Management',
      'Contract Management', 'Cost Estimation', 'BOQ', 'Tendering',
      'Material Sourcing', 'Negotiation', 'ERP Systems', 'MS Office',
      'Market Analysis',
    ],
    'Sales Engineer': <String>[
      'Technical Sales', 'Client Relationship Management', 'Product Knowledge',
      'Presentations', 'Negotiation', 'CRM Software', 'Market Analysis',
      'Proposal Writing', 'After-Sales Support', 'MS Office',
      'Communication Skills', 'Business Development',
    ],
    'Tendering Engineer': <String>[
      'Tendering', 'BOQ', 'Cost Estimation', 'Quantity Surveying',
      'Contract Management', 'Primavera P6', 'MS Project', 'AutoCAD',
      'Proposal Writing', 'Value Engineering', 'Risk Analysis', 'MS Office',
    ],
  };

  /// The skills to offer for [role]. An unknown or empty role offers nothing —
  /// the form says "pick a role first" rather than showing a random list.
  static List<String> skillsFor(String role) =>
      skillsByRole[role] ?? const <String>[];
}
