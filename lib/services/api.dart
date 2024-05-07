import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/country.dart';

class Api {
  Future<List<Map<String, dynamic>>> fetchDataFromApi(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body)['data']);
    } else {
      throw Exception(
          'Failed to load data from API (status code: ${response.statusCode})');
    }
  }

  Future<List<Country>> fetchDataFromApis() async {
    List<Country> mergedData = [];

    List<Map<String, dynamic>> country = await fetchDataFromApi(
        'https://countriesnow.space/api/v0.1/countries/capital');
    List<Map<String, dynamic>> countryFlag = await fetchDataFromApi(
        'https://countriesnow.space/api/v0.1/countries/flag/images');
    List<Map<String, dynamic>> countryCurrency = await fetchDataFromApi(
        'https://countriesnow.space/api/v0.1/countries/currency');

    // Merge data from all APIs
    for (var element in country) {
      var countryData = countryFlag
          .firstWhere((e) => e['name'] == element['name'], orElse: () => {});
      var currencyData = countryCurrency
          .firstWhere((e) => e['name'] == element['name'], orElse: () => {});
      if (countryData.isNotEmpty && currencyData.isNotEmpty) {
        mergedData.add(Country.fromJson({
          'name': element['name'],
          'capital': element['capital'],
          'flag': countryData['flag'],
          'iso2': element['iso2'],
          'iso3': element['iso3'],
          'currency': currencyData['currency'],
        }));
      }
    }
    return mergedData;
  }
}
