/// Module: web / core
///
///*************************** FILE INFO ****************************///
/// File Name: builtin_en.dart
/// Purpose: English for the site's starter content (the three services) —
///          used while the site is in English and the admin has not filled
///          the field's English version (`{key}_en`) in the panel. An English
///          text typed in the panel always wins.
/// Author: ASEC team
/// Created: 21/10/2026
library;

/// document id → field → English text (String) or list (List<String>).
const Map<String, Map<String, Object>> kBuiltInEnglish = <String, Map<String, Object>>{
  // ── Site settings (site_settings/main): the CEO section and the address ──
  'main': <String, Object>{
    'ceo_name': 'Ahmed Shehib',
    'ceo_bio': 'At Ahmed Shehib Engineering Consultants, we believe excellence comes only through mastery and '
        'precision. Since our founding, we have worked tirelessly to deliver innovative engineering solutions in '
        'electromechanical systems design, committed to the highest standards of quality and professionalism.\n\n'
        'Our motto, "Design Precision", is not just words — it is the heart of our work and the vision we pursue '
        'in every project. Our goal is to be your first partner in success, delivering integrated engineering '
        'designs that keep pace with progress and meet your needs with the highest efficiency.\n\n'
        'We always look to broaden our horizons and strengthen our place as a leading firm in this field, thanks to '
        'our outstanding team and our successful partnerships with our valued clients. Together, we build the future.',
    'address': '4 Mohamed Mokalled St., Nasr City / Cairo / Egypt',
  },
  // ── Services ──────────────────────────────────────────────────────────────
  'integrated-design': <String, Object>{
    'title': 'Integrated Design',
    'tagline': 'Our attention to detail makes a model design',
    'body': 'Our team is committed to high-quality services that satisfy our clients while meeting every '
        'international and local code. We always deliver on time and within budget, and we carry out all '
        'the engineering and technical studies and consultancy for residential, commercial, government and '
        'hospital projects, with careful, professional supervision of every source we choose.\n\n'
        'The design starts in full harmony with the client\'s requirements, presenting creative ideas step '
        'by step. Once the client approves the initial proposal, we carry out the structural, architectural, '
        'mechanical and electrical calculations and an early estimate of the project cost, so the design fits '
        'the client\'s budget. We then produce the final design with the calculation notes, the bill of '
        'quantities and a list of suppliers. Our goal is always full coordination between all disciplines '
        'using Building Information Modeling (BIM).\n\n'
        'Work runs on COLLABORATE PRO, so everyone on the project can coordinate and follow the design, and '
        'the client can follow the project\'s progress daily through a personal e-mail.',
    'points': <String>[
      'Detail and quality: high-quality services with attention to detail, meeting international and local standards.',
      'Time and budget: the project is delivered on time and within the agreed budget.',
      'Experience and services: residential, commercial, government and hospital projects, with the consulting and engineering studies they need.',
      'Collaboration and follow-up: COLLABORATE PRO for coordination and design follow-up, with daily progress the client can see.',
      'Technology: Building Information Modeling (BIM) for full coordination between all disciplines.',
    ],
  },
  'shop-drawings': <String, Object>{
    'title': 'Shop Drawings',
    'tagline': 'We solve your problems before construction',
    'body': 'Shop drawings are one of the most important stages of a project, and a drawing that can really be '
        'built needs coordination between every discipline. Our team works with Building Information Modeling, '
        'so all disciplines share one central model where everyone sees the others\' work, which makes '
        'coordination easy.\n\n'
        'After coordination we study the clashes realistically, taking the clearances between disciplines into '
        'account, using Navisworks, so the client gets a project that is 100% coordinated. We then issue the '
        'drawings with every detail construction needs, and follow construction through to the AS BUILT drawings '
        'at the end of the project.',
    'points': <String>[
      'Coordination before construction: coordinating all disciplines before the shop drawings ensures the project can be built and fits together.',
      'BIM: every team sees the central model and collaborates easily.',
      'Clash detection: a realistic study in Navisworks for a 100% coordinated project.',
      'Shop drawings: every detail construction needs, followed through to AS BUILT drawings.',
    ],
  },
  'supervision': <String, Object>{
    'title': 'Construction Supervision',
    'tagline': 'An eye on your project',
    'body': 'Our office has experience supervising the construction of many projects of every kind — commercial, '
        'residential, industrial and medical. We study the technical and financial offers, compare the technical '
        'specifications of the materials with the project\'s standard specifications, prepare the project '
        'schedules and link them to the payment certificates. We know the latest systems well, which helps us '
        'overcome every obstacle quickly and deliver outstanding work — this team has helped us complete many '
        'projects.',
    'points': <String>[
      'Experience across projects: supervising commercial, residential, industrial and medical projects.',
      'Study and comparison: reviewing technical and financial offers and comparing material specifications with the project standards.',
      'Planning and cost: project schedules linked to the payment certificates.',
      'Up-to-date know-how: the latest systems and technologies to overcome challenges quickly and efficiently.',
    ],
  },
};

/// Phone numbers shown with the one saved in the panel (footer, Contact).
const List<String> kExtraPhones = <String>['+201080601010'];

/// Every phone to show: the panel's, then [kExtraPhones], no repeats.
List<String> sitePhones(String saved) => <String>{
      if (saved.trim().isNotEmpty) saved.trim(),
      ...kExtraPhones,
    }.toList();

/// Arabic starter title → document key above, for copies saved under
/// another id.
const Map<String, String> kBuiltInEnglishByArabicTitle = <String, String>{
  'تصميم متكامل': 'integrated-design',
  'لوحات تنفيذية': 'shop-drawings',
  'اشراف على التنفيذ': 'supervision',
};
