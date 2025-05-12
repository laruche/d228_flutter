import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import '../services/gps_service.dart';
import '../services/temperature_service.dart';
import '../services/temperature_data_service.dart';
import '../services/city_country_service.dart';
import '../strings.dart';
import 'popup/basic_popup.dart';
import 'popup/temperature_popup.dart';
import 'popup/city_country_popup.dart';

class mapPage extends StatefulWidget {
  const mapPage({super.key});

  @override
  _mapPageState createState() => _mapPageState();
}

class _mapPageState extends State<mapPage> {
  List<Marker> _markers = [];
  final ValueNotifier<LatLng?> mapCenterNotifier = ValueNotifier(null);
  final GpsService _gpsService = GpsService();
  final TemperatureService _temperatureService = TemperatureService();
  final TemperatureDataService _temperatureDataService = TemperatureDataService();
  final CityCountryService _cityCountryService = CityCountryService();

  final PopupController _popupController = PopupController();
  final MapController _mapController = MapController();
  final minLatLng = const LatLng(49.8566, 1.3522);
  final maxLatLng = const LatLng(58.3498, -10.2603);

  final Map<String, Map<String, dynamic>> _markerData = {};

  String? _selectedCity;
  String? _selectedCountry;
  bool _isFilterApplied = false;

  @override
  void initState() {
    super.initState();
    print('Adding listener to mapCenterNotifier');
    mapCenterNotifier.addListener(() {
      print('Map center changed: ${mapCenterNotifier.value}');
      if (mapCenterNotifier.value != null) {
        double zoomLevel = _getZoomLevel();
        print('Zoom level: $zoomLevel');
        print('Moving map to: ${mapCenterNotifier.value} with zoom: $zoomLevel');
        _mapController.move(mapCenterNotifier.value!, zoomLevel);
      }
    });
    _loadTemperatureData();
    _loadCities();
  }

  Future<void> _loadTemperatureData() async {
    try {
      print('Loading temperature data...');
      print('_selectedCity: $_selectedCity');
      print('_selectedCountry: $_selectedCountry');

      String type = 'all';
      if (_selectedCity != null) {
        type = 'city';
      } else if (_selectedCountry != null) {
        type = 'country';
      }
      String param = _selectedCity ?? _selectedCountry ?? '';

      List<Map<String, dynamic>> temperatureData = await _temperatureDataService
          .fetchTemperatureData(type, param);

      // on boucle les données de température
      // et on crée un marker pour chaque point
      // on utilise le service de température pour récupérer les données

      // print('Temperature data: $temperatureData');

      _markers = temperatureData
          .map((data) {
            // log data for debugging

            // print('Data: $data');

            double latitude = data['latlong']['lat'];
            double longitude = data['latlong']['long'];
            String temperature = data['mesures'][0]['mesure'].toString();

            // print(
            //   'Latitude: $latitude, Longitude: $longitude, Temperature: $temperature',
            // );

            _markerData['$latitude,$longitude'] = data;

            return Marker(
              width: 30,
              height: 30,
              anchorPos: AnchorPos.align(AnchorAlign.top),
              rotateAlignment: AnchorAlign.top.rotationAlignment,
              point: LatLng(latitude, longitude),
              builder: (ctx) => Container(
                width: 30.0,
                height: 30.0,
                decoration: BoxDecoration(
                  color: _getColorForTemperature(
                    double.parse(temperature),
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    temperature,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10.0,
                    ),
                  ),
                ),
              ),
            );
          })
          .whereType<Marker>()
          .toList();

      print('Markers: $_markers');
      // on modifie la position de la carte
      // on modifie le zoom de la carte

      if (type != 'all' && _markers.isNotEmpty) {
        print('Updating map center to: ${_markers[0].point}');
        mapCenterNotifier.value = _markers[0].point;
        print('mapCenterNotifier.value set to: ${mapCenterNotifier.value}');
      }

      setState(() {}); // Force a rebuild to update the UI
    } catch (e) {
      print('Error loading temperature data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load temperature data: $e')),
      );
    }
  }

  Future<void> _loadCities() async {
    try {
      List<Map<String, dynamic>> cities = await _cityCountryService.fetchCities();
      // You can store the cities in a state variable if needed
      print('Cities loaded: $cities');
    } catch (e) {
      print('Error loading cities: $e');
    }
  }

  Color _getColorForTemperature(double temperature) {
    if (temperature < 10) {
      return Colors.blue;
    } else if (temperature < 20) {
      return Colors.green;
    } else if (temperature < 30) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  double _getZoomLevel() {
    if (_selectedCity != null) {
      return 6.0; // Zoom pour une ville
    } else if (_selectedCountry != null) {
      return 5.0; // Zoom pour un pays
    } else {
      return 3.0; // Zoom par défaut
    }
  }

  void _sendTemperature() async {
    try {
      Position position = await _gpsService.getCurrentLocation();
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return TemperaturePopup(
            latitude: position.latitude,
            longitude: position.longitude,
            onTemperatureSelected: (temperature, pseudo) {
              _sendSelectedTemperature(
                position.latitude,
                position.longitude,
                temperature,
                pseudo,
              );
            },
          );
        },
      );
    } catch (e) {
      print('Error getting location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Strings.failedToSendTemperature + e.toString())),
      );
    }
  }

  void _sendSelectedTemperature(
    double latitude,
    double longitude,
    double temperature,
    String pseudo,
  ) async {
    try {
      await _temperatureService.sendTemperature(
        latitude,
        longitude,
        temperature,
        pseudo,
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(Strings.temperatureSent)));
      // Refresh the markers after sending the temperature
      await _loadTemperatureData();
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Strings.failedToSendTemperature + e.toString())),
      );
    }
  }

  void _showCityPopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CityCountryPopup(
          isCity: true,
          onSelected: (String? selectedItem) {
            setState(() {
              _selectedCity = selectedItem;
              _selectedCountry = null;
              _isFilterApplied = selectedItem != null;
            });
            _loadTemperatureData();
          },
        );
      },
    );
  }

  void _showCountryPopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CityCountryPopup(
          isCity: false,
          onSelected: (String? selectedItem) {
            setState(() {
              _selectedCity = null;
              _selectedCountry = selectedItem;
              _isFilterApplied = selectedItem != null;
            });
            _loadTemperatureData();
          },
        );
      },
    );
  }

  void _resetFilters() {
    setState(() {
      _selectedCity = null;
      _selectedCountry = null;
      _isFilterApplied = false;
    });
    _loadTemperatureData();
    mapCenterNotifier.value = LatLng(33.5731, -7.5898);

  }

  @override
  Widget build(BuildContext context) {
    String type = 'all';
    if (_selectedCity != null) {
      type = 'city';
    } else if (_selectedCountry != null) {
      type = 'country';
    }

    // on definit le zoom de la carte et la position de la carte
    double zoom = _getZoomLevel();
    LatLng center = LatLng(33.5731, -7.5898);

    // on le moodifie en fonction du type
    if (type == 'city' && _markers.isNotEmpty) {
      // on va chercher les positions des villes dans les markers
      // on prend la position de la première entree
      center = LatLng(_markers[0].point.latitude, _markers[0].point.longitude);
    } else if (type == 'country' && _markers.isNotEmpty) {
      // on va chercher les positions des pays dans les markers
      // on prend la position de la première entree
      center = LatLng(_markers[0].point.latitude, _markers[0].point.longitude);
    }

    return Scaffold(
      appBar: ModalRoute.of(context)?.isFirst == true ? null : AppBar(title: Text(Strings.mapTitle)),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: center,
              zoom: zoom,
              maxZoom: 13.0,
              // hide all popups when the map is tapped
              onTap: (_, __) => _popupController.hideAllPopups(),
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: 'com.laruche.d228',
              ),
              PopupMarkerLayer(
                options: PopupMarkerLayerOptions(
                  popupController: _popupController,
                  markers: _markers,
                  popupDisplayOptions: PopupDisplayOptions(
                    builder: (BuildContext context, Marker marker) {
                      final data = _markerData['${marker.point.latitude},${marker.point.longitude}'];
                      return ExamplePopup(marker, data ?? {});
                    },
                  ),
                  markerTapBehavior: MarkerTapBehavior.togglePopupAndHideRest(),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 65.0,
            left: 20.0,
            child: Column(
              children: [
                if (_isFilterApplied)
                  FloatingActionButton(
                    onPressed: _resetFilters,
                    heroTag: 'resetButton',
                    child: Icon(Icons.refresh),
                  ),
                SizedBox(height: 10.0),
                FloatingActionButton(
                  onPressed: _showCityPopup,
                  heroTag: 'cityButton',
                  child: Icon(Icons.location_city),
                ),
                SizedBox(height: 10.0),
                FloatingActionButton(
                  onPressed: _showCountryPopup,
                  heroTag: 'countryButton',
                  child: Icon(Icons.flag),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _sendTemperature,
        child: Icon(Icons.send),
      ),
    );
  }
}
