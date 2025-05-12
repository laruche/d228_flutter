import 'package:flutter/material.dart';
import '../../services/city_country_selector.dart';
import '../../strings.dart';

class CityCountryPopup extends StatelessWidget {
  final bool isCity;
  final Function(String) onSelected;

  const CityCountryPopup({Key? key, required this.isCity, required this.onSelected}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isCity ? Strings.selectCity : Strings.selectCountry),
      contentPadding: const EdgeInsets.all(16.0), // Ajout d'un padding personnalisé
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8 + 50, // Augmente la largeur de 50px
        child: CityCountrySelector(
          isCity: isCity,
          onSelected: (selectedItem) {
            onSelected(selectedItem);
            Navigator.of(context).pop();
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(Strings.cancel),
        ),
      ],
    );
  }
}
