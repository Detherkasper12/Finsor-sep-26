import 'package:flutter/material.dart';

class CategoryColors {
  CategoryColors._();

  static const List<String> palette = [
    '#F44336', '#E91E63', '#9C27B0', '#673AB7',
    '#3F51B5', '#2196F3', '#03A9F4', '#00BCD4',
    '#009688', '#4CAF50', '#8BC34A', '#CDDC39',
    '#FFC107', '#FF9800', '#FF5722', '#795548',
  ];

  static Color fromHex(String hex) {
    final clean = hex.replaceAll('#', '');
    return Color(0xFF000000 | int.parse(clean.length == 6 ? clean : '666666', radix: 16));
  }

  static List<Color> get all => palette.map(fromHex).toList();
}
