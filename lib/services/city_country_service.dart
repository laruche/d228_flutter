import 'dart:convert';
import 'package:http/http.dart' as http;
import '../country_codes.dart';
import '../config.dart';


class CityCountryService {
  final String apiUrl = Config.apiUrl; 
  Future<List<Map<String, dynamic>>> fetchCities() async {
    final response = await http.get(Uri.parse('$apiUrl/liste-villes'));
    if (response.statusCode == 200) {
      List<Map<String, dynamic>> cities = List<Map<String, dynamic>>.from(json.decode(response.body));
      return cities.where((city) => city['City'] != null && city['City'] != 'indéfini' && city['City'] != 'undefined').map((city) {
        city['CountryCode'] = countryCodes[city['Country']] ?? '';
        // on limit le nom de la ville à 25 caractères
        if (city['City'].length > 25) {
          city['City'] = city['City'].substring(0, 25) + '...';
        }
        return city;
      }).toList();
    } else {
      throw Exception('Failed to load cities');
    }
  }

  Future<List<Map<String, dynamic>>> fetchCountries() async {
    final response = await http.get(Uri.parse('$apiUrl/liste-pays'));
    if (response.statusCode == 200) {
      List<Map<String, dynamic>> countries = List<Map<String, dynamic>>.from(json.decode(response.body));
      return countries.where((country) => country['Country'] != null && country['Country'] != 'indéfini' && country['Country'] != 'undefined').map((country) {
        country['CountryCode'] = countryCodes[country['Country']] ?? '';
        // on limit le nom du pays à 25 caractères
        if (country['Country'].length > 25) {
          country['Country'] = country['Country'].substring(0, 25) + '...';
        }
        return country;
      }).toList();
    } else {
      throw Exception('Failed to load countries');
    }
  }
}
