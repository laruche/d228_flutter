import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';

class TemperatureDataService {
  final String apiUrl = Config.apiUrl; // Remplacez par votre URL API

  Future<List<Map<String, dynamic>>> fetchTemperatureData( type, param) async {


    String apiUrl = Config.apiUrl;
    if (type == 'city') {
      apiUrl += '/liste-par-ville?city=$param';
    } else if (type == 'country') {
      apiUrl += '/liste-par-pays?country=$param';
    } else if (type == 'all') {
      apiUrl += '/liste';
    } else {
      throw Exception('Invalid type: $type');
    }


    final response = await http.get(Uri.parse(apiUrl));


    if (response.statusCode == 200) {
      // Convert the dynamic list to a list of maps
      Map<String, List<Map<String, dynamic>>> groupedData = groupDataByLatLng(
        response.body,
      );

      // Prepare the data in the desired format
      List<Map<String, dynamic>> preparedData = prepareData(groupedData);

      return preparedData;
    } else {
      throw Exception('Failed to load temperature data');
    }
  }
}

Map<String, List<Map<String, dynamic>>> groupDataByLatLng(String jsonData) {
  // Parser les données JSON
  List<dynamic> data = jsonDecode(jsonData);

  // Dictionnaire pour regrouper les points
  Map<String, List<Map<String, dynamic>>> groupedData = {};

  // Parcourir les données et regrouper les points
  for (var item in data) {
    String latLng = item['LatLng'];
    if (!groupedData.containsKey(latLng)) {
      groupedData[latLng] = [];
    }
    groupedData[latLng]!.add({
      'idMesure': item['idMesure'],
      'User': item['User'],
      'Mesure': item['Mesure'],
      'Timestamp': item['Timestamp'],
      'City': item['City'],
    });
  }

  return groupedData;
}

List<Map<String, dynamic>> prepareData(
  Map<String, List<Map<String, dynamic>>> groupedData,
) {
  List<Map<String, dynamic>> preparedData = [];

  groupedData.forEach((latLng, points) {
    try {
      List<String> coords = latLng.split(',');
      double? latitude = double.tryParse(coords[0]);
      double? longitude = double.tryParse(coords[1]);
      if ((latitude != null && longitude != null)) {
        if (latitude != 0 && longitude != 0) {
          List<Map<String, dynamic>> mesures =
              points.map((point) {
                return {
                  'id': point['idMesure'],
                  'by': point['User'],
                  'mesure': point['Mesure'],
                  'date': _formatTimestamp(int.parse(point['Timestamp'])),
                };
              }).toList();

          try {
            preparedData.add({
              'latlong': {'lat': latitude, 'long': longitude},
              'city': points.isNotEmpty ? points.first['City'] : '',
              'mesures': mesures,
            });
          } catch (e) {
            print('Error adding data to preparedData: $e');
          }
        }
      }
    } catch (e) {
      print('Error processing latLng $latLng: $e');
    }
  });
  return preparedData;
}

String _formatTimestamp(int timestamp) {

  try {
    final now = DateTime.now();
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'il y a ${difference.inSeconds} secondes';
    } else if (difference.inMinutes < 60) {
      return 'il y a ${difference.inMinutes} minutes';
    } else if (difference.inHours < 24) {
      return 'il y a ${difference.inHours} heures';
    } else {
      return 'il y a ${difference.inDays} jours';
    }
  } catch (e) {
    print('Error formatting timestamp: $e');
    return 'Date invalide';
  }
}
