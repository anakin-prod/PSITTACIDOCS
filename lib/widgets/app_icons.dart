import 'package:flutter/material.dart';

/// Traduit les identifiants d'icônes utilisés dans les données (ex. 'egg',
/// 'shield') vers une icône Material. Centralise ce choix pour rester
/// cohérent dans toute l'appli.
IconData iconFor(String name) {
  switch (name) {
    case 'egg':
      return Icons.egg_outlined;
    case 'leaf':
      return Icons.eco_outlined;
    case 'shield':
      return Icons.shield_outlined;
    case 'scale':
      return Icons.monitor_weight_outlined;
    case 'steth':
      return Icons.medical_services_outlined;
    case 'bowl':
      return Icons.ramen_dining_outlined;
    case 'doc':
      return Icons.description_outlined;
    case 'tree':
      return Icons.account_tree_outlined;
    case 'out':
      return Icons.output_outlined;
    case 'chart':
      return Icons.bar_chart_outlined;
    case 'book':
      return Icons.menu_book_outlined;
    case 'gear':
      return Icons.settings_outlined;
    case 'plus':
      return Icons.add;
    case 'cam':
      return Icons.photo_camera_outlined;
    case 'search':
      return Icons.search;
    case 'bird':
      return Icons.flutter_dash;
    case 'couple':
      return Icons.favorite_border;
    case 'calendar':
      return Icons.calendar_today_outlined;
    case 'more':
      return Icons.menu;
    case 'thermo':
      return Icons.thermostat_outlined;
    case 'genetics':
      return Icons.science_outlined;
    case 'idea':
      return Icons.lightbulb_outline;
    case 'pdf':
      return Icons.picture_as_pdf_outlined;
    default:
      return Icons.circle_outlined;
  }
}
