import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config.dart';
import '../../strings.dart';

class TemperaturePopup extends StatefulWidget {
  final double latitude;
  final double longitude;
  final Function(double, String) onTemperatureSelected;

  const TemperaturePopup({
    required this.latitude,
    required this.longitude,
    required this.onTemperatureSelected,
  });

  @override
  _TemperaturePopupState createState() => _TemperaturePopupState();
}

class _TemperaturePopupState extends State<TemperaturePopup> {
  double _selectedTemperature = 0.0;
  bool _isLoading = true;
  String _pseudo = '';
  final FixedExtentScrollController _scrollController = FixedExtentScrollController();
  final TextEditingController _pseudoController = TextEditingController();

  final List<double> temperatures = [
    -20.0, -19.0, -18.0, -17.0, -16.0, -15.0, -14.0, -13.0, -12.0, -11.0,
    -10.0, -9.0, -8.0, -7.0, -6.0, -5.0, -4.0, -3.0, -2.0, -1.0, 0.0, 1.0,
    2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0,
    15.0, 16.0, 17.0, 18.0, 19.0, 20.0, 21.0, 22.0, 23.0, 24.0, 25.0, 26.0,
    27.0, 28.0, 29.0, 30.0, 31.0, 32.0, 33.0, 34.0, 35.0, 36.0, 37.0, 38.0,
    39.0, 40.0, 41.0, 42.0, 43.0, 44.0, 45.0, 46.0, 47.0, 48.0, 49.0, 50.0,
  ];

  @override
  void initState() {
    super.initState();
    _loadPseudo();
    _fetchTemperatureFromAPI(widget.latitude, widget.longitude);
  }

  Future<void> _loadPseudo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pseudo = prefs.getString('pseudo') ?? '';
      _pseudoController.text = _pseudo; // Initialiser le contrôleur avec la valeur chargée
    });
  }

  Future<void> _savePseudo(String pseudo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pseudo', pseudo);
  }

  Future<void> _fetchTemperatureFromAPI(double latitude, double longitude) async {
    final response = await http.get(Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?lat=$latitude&lon=$longitude&appid=${Config.owapiKey}&units=metric'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      double temp = data['main']['temp'].toDouble().roundToDouble();

      setState(() {
        _selectedTemperature = temp;
        _isLoading = false;
      });

      // Déplace la liste à la position correcte
      _scrollController.jumpToItem(temperatures.indexOf(_selectedTemperature));
    } else {
      setState(() {
        _isLoading = false;
      });
      throw Exception('Failed to load temperature');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr, // Force la direction du texte de gauche à droite
      child: AlertDialog(
        title: Text(Strings.selectTemperature),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(labelText: Strings.selectPseudo),
              onChanged: (value) {
                setState(() {
                  _pseudo = value;
                });
              },
              controller: _pseudoController,
            ),
            SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: ListWheelScrollView.useDelegate(
                itemExtent: 70,
                childDelegate: ListWheelChildBuilderDelegate(
                  builder: (context, index) {
                    return Center(
                      child: Text(
                        temperatures[index].toString() + ' °C',
                        style: TextStyle(
                          fontSize: 24,
                          color: temperatures[index] == _selectedTemperature
                              ? Colors.blue
                              : Colors.black,
                        ),
                      ),
                    );
                  },
                  childCount: temperatures.length,
                ),
                onSelectedItemChanged: (index) {
                  setState(() {
                    _selectedTemperature = temperatures[index];
                  });
                },
                controller: _scrollController,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _savePseudo(_pseudo); // Sauvegarde le pseudo uniquement lorsque l'utilisateur appuie sur "Send"
              Navigator.of(context).pop();
              widget.onTemperatureSelected(_selectedTemperature, _pseudo);
            },
            child: Text(Strings.sendTemperature),
          ),
        ],
      ),
    );
  }
}
