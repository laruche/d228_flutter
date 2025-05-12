import 'package:flutter/material.dart';
import 'package:country_flags/country_flags.dart';
import '../services/city_country_service.dart';
import '../strings.dart';

class CityCountrySelector extends StatefulWidget {
  final bool isCity;
  final Function(String) onSelected;

  const CityCountrySelector({Key? key, required this.isCity, required this.onSelected}) : super(key: key);

  @override
  _CityCountrySelectorState createState() => _CityCountrySelectorState();
}

class _CityCountrySelectorState extends State<CityCountrySelector> {
  final CityCountryService _cityCountryService = CityCountryService();
  List<Map<String, dynamic>> _items = [];
  String? _selectedItem;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    try {
      if (widget.isCity) {
        _items = await _cityCountryService.fetchCities();
      } else {
        _items = await _cityCountryService.fetchCountries();
      }
      print('Loaded items: $_items');
      setState(() {});
    } catch (e) {
      print('Error loading items: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return _items.isEmpty
        ? Center(child: CircularProgressIndicator())
        : Container(
             child: DropdownButton<String>(
              hint: Text(widget.isCity ? Strings.selectCity : Strings.selectCountry),
              value: _selectedItem,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedItem = newValue;
                });
                widget.onSelected(newValue!);
              },
              items: _items.map<DropdownMenuItem<String>>((Map<String, dynamic> item) {
                String name = widget.isCity ? item['City'] ?? 'Unknown' : item['Country'] ?? 'Unknown';
                String countryCode = item['CountryCode'] ?? '';
                // selectItem = 'city||country';
                String countryName = item['Country'] ?? '';
                String cityName = item['City'] ?? '';
                String selectedItem = widget.isCity ? '$cityName||$countryName' : 'null||$countryName';
               
                return DropdownMenuItem<String>(
                  value: name,
                  child: Row(
                    children: [
                      if (countryCode.isNotEmpty)
                        CountryFlag.fromCountryCode(
                          countryCode,
                          width: 24,
                          height: 24,
                        ),
                      SizedBox(width: 8),
                      Text(name),
                    ],
                  ),
                );
              }).toList(),
            ),
          );
  }
}
