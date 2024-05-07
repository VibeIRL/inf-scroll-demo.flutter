class Country {
  final String name;
  final String capital;
  final String flag;
  final String iso2;
  final String iso3;
  final String currency;

  Country({
    required this.name,
    required this.capital,
    required this.flag,
    required this.iso2,
    required this.iso3,
    required this.currency,
  });

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      name: json['name'] ?? '',
      capital: json['capital'] ?? '',
      flag: json['flag'] ?? '',
      iso2: json['iso2'] ?? '',
      iso3: json['iso3'] ?? '',
      currency: json['currency'] ?? '',
    );
  }
}
