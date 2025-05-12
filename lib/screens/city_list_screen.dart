import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../strings.dart';

class CityListScreen extends StatefulWidget {
  const CityListScreen({super.key});

  @override
  _CityListScreenState createState() => _CityListScreenState();
}

class _CityListScreenState extends State<CityListScreen> {
  List<String> _cities = [];

  @override
  void initState() {
    super.initState();
    _loadCities();
  }

  Future<void> _loadCities() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _cities = prefs.getStringList('cities') ?? [];
    });
  }

  Future<void> _saveCity(String city) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _cities.add(city);
      prefs.setStringList('cities', _cities);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Strings.citiesListTitle),
      ),
      body: ListView.builder(
        itemCount: _cities.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(_cities[index]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _saveCity(Strings.newCity); // Exemple de nouvelle ville
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
