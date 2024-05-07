import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/country.dart';

class CountryCard extends StatelessWidget {
  final Country country;

  const CountryCard({super.key, required this.country});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      color: Colors.white,
      child: ListTile(
        leading: SizedBox(
          width: 30.0,
          height: 20.0,
          child: SvgPicture.network(
            country.flag,
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                country.name,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 5),
            Card(
              color: Colors.blue,
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Text(
                  country.currency,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          country.capital,
          style: const TextStyle(
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
