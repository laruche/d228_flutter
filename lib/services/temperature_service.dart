import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';


class TemperatureService {
  // GET request to send temperature data
  // {{url}}/envoi?LatLng=33.5922,-7.6184&user=loic&mesure=17



  Future<void> sendTemperature(double latitude, double longitude, double temperature, String pseudo) async {
    
    final String apiUrl = '${Config.apiUrl}/envoi?LatLng=$latitude,$longitude&user=$pseudo&mesure=$temperature';
    final response = await http.get(Uri.parse(apiUrl));
    if (response.statusCode != 200) {
      throw Exception('Failed to send temperature');
    }
    
  }
}
