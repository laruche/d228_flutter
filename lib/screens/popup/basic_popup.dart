import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

class ExamplePopup extends StatefulWidget {
  final Marker marker;
  final Map<String, dynamic> data;

  const ExamplePopup(this.marker, this.data, {super.key});

  @override
  State<StatefulWidget> createState() => _ExamplePopupState();
}

class _ExamplePopupState extends State<ExamplePopup> {
  final List<IconData> _icons = [
    Icons.star_border,
    Icons.star_half,
    Icons.star,
  ];
  int _currentIcon = 0;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap:
            () => setState(() {
              _currentIcon = (_currentIcon + 1) % _icons.length;
            }),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[_cardDescription(context)],
        ),
      ),
    );
  }

  Widget _cardDescription(BuildContext context) {
    final mesures = widget.data['mesures'] as List<Map<String, dynamic>>;
    String title = widget.data['city'];

    return Padding(
      padding: const EdgeInsets.all(10),
      child: Container(
        constraints: const BoxConstraints(minWidth: 100, maxWidth: 200),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              title,
              overflow: TextOverflow.fade,
              softWrap: false,
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14.0),
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4.0)),
            ...mesures
                .take(5)
                .map(
                  (mesure) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${mesure['mesure']}°C - par ${mesure['by']}, ${mesure['date']}',
                        style: const TextStyle(fontSize: 12.0),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4.0),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
