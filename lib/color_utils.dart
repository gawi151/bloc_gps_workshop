import 'package:flutter/material.dart';

final Map<String, Color> colorOptions = {
  'Red': Colors.red,
  'Blue': Colors.blue,
  'Green': Colors.green,
  'Orange': Colors.orange,
};

Color getColorFromName(String name) {
  switch (name) {
    case 'Blue':
      return Colors.blue;
    case 'Green':
      return Colors.green;
    case 'Orange':
      return Colors.orange;
    default:
      return Colors.red;
  }
}
