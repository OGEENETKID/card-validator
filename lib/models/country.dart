class Country {
  const Country(this.code, this.name);

  /// ISO 3166-1 alpha-2.
  final String code;
  final String name;

  /// Regional indicator pair, renders as the flag emoji.
  String get flag {
    const base = 0x1F1E6;
    final a = code.codeUnitAt(0) - 0x41 + base;
    final b = code.codeUnitAt(1) - 0x41 + base;
    return String.fromCharCodes([a, b]);
  }

  @override
  bool operator ==(Object other) => other is Country && other.code == code;

  @override
  int get hashCode => code.hashCode;
}

/// Reference list of issuing countries, parsed once on first access.
abstract final class Countries {
  static final List<Country> all = _parse();

  static final Map<String, Country> _byCode = {for (final c in all) c.code: c};

  static Country? byCode(String code) => _byCode[code.toUpperCase()];

  static String nameOf(String code) => byCode(code)?.name ?? code;

  static List<Country> search(String query) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return all;
    return all
        .where((c) => c.name.toLowerCase().contains(needle) || c.code.toLowerCase() == needle)
        .toList();
  }

  static List<Country> _parse() => _packed
      .split(';')
      .where((entry) => entry.isNotEmpty)
      .map((entry) {
        final parts = entry.split(':');
        return Country(parts[0], parts[1]);
      })
      .toList()
    ..sort((a, b) => a.name.compareTo(b.name));

  static const String _packed = 'AF:Afghanistan;AL:Albania;DZ:Algeria;AO:Angola;AR:Argentina;'
      'AM:Armenia;AU:Australia;AT:Austria;AZ:Azerbaijan;BH:Bahrain;BD:Bangladesh;BB:Barbados;'
      'BY:Belarus;BE:Belgium;BZ:Belize;BJ:Benin;BO:Bolivia;BA:Bosnia and Herzegovina;'
      'BW:Botswana;BR:Brazil;BG:Bulgaria;BF:Burkina Faso;BI:Burundi;KH:Cambodia;CM:Cameroon;'
      'CA:Canada;CF:Central African Republic;TD:Chad;CL:Chile;CN:China;CO:Colombia;'
      'CD:Congo (DRC);CR:Costa Rica;HR:Croatia;CU:Cuba;CY:Cyprus;CZ:Czechia;DK:Denmark;'
      'DO:Dominican Republic;EC:Ecuador;EG:Egypt;SV:El Salvador;EE:Estonia;ET:Ethiopia;'
      'FI:Finland;FR:France;GA:Gabon;GE:Georgia;DE:Germany;GH:Ghana;GR:Greece;GT:Guatemala;'
      'GN:Guinea;GY:Guyana;HT:Haiti;HN:Honduras;HK:Hong Kong;HU:Hungary;IS:Iceland;IN:India;'
      'ID:Indonesia;IR:Iran;IQ:Iraq;IE:Ireland;IL:Israel;IT:Italy;CI:Ivory Coast;JM:Jamaica;'
      'JP:Japan;JO:Jordan;KZ:Kazakhstan;KE:Kenya;KW:Kuwait;LA:Laos;LV:Latvia;LB:Lebanon;'
      'LR:Liberia;LY:Libya;LT:Lithuania;LU:Luxembourg;MG:Madagascar;MW:Malawi;MY:Malaysia;'
      'ML:Mali;MT:Malta;MR:Mauritania;MU:Mauritius;MX:Mexico;MD:Moldova;MN:Mongolia;'
      'ME:Montenegro;MA:Morocco;MZ:Mozambique;MM:Myanmar;NA:Namibia;NP:Nepal;NL:Netherlands;'
      'NZ:New Zealand;NI:Nicaragua;NE:Niger;NG:Nigeria;KP:North Korea;MK:North Macedonia;'
      'NO:Norway;OM:Oman;PK:Pakistan;PA:Panama;PY:Paraguay;PE:Peru;PH:Philippines;PL:Poland;'
      'PT:Portugal;QA:Qatar;RO:Romania;RU:Russia;RW:Rwanda;SA:Saudi Arabia;SN:Senegal;'
      'RS:Serbia;SL:Sierra Leone;SG:Singapore;SK:Slovakia;SI:Slovenia;SO:Somalia;'
      'ZA:South Africa;KR:South Korea;SS:South Sudan;ES:Spain;LK:Sri Lanka;SD:Sudan;SE:Sweden;'
      'CH:Switzerland;SY:Syria;TW:Taiwan;TZ:Tanzania;TH:Thailand;TG:Togo;TT:Trinidad and Tobago;'
      'TN:Tunisia;TR:Turkey;UG:Uganda;UA:Ukraine;AE:United Arab Emirates;GB:United Kingdom;'
      'US:United States;UY:Uruguay;UZ:Uzbekistan;VE:Venezuela;VN:Vietnam;YE:Yemen;ZM:Zambia;'
      'ZW:Zimbabwe';
}
