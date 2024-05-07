import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget {
  final String title;
  final Widget? searchField;

  const CustomAppBar({super.key, required this.title, this.searchField});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      flexibleSpace: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20.0),
          ),
          if (searchField != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: searchField!,
            ),
        ],
      ),
    );
  }
}
