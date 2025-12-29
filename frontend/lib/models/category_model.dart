import 'package:flutter/material.dart';

class CategoryModel {
  final String id;
  final String name;
  final String slug;
  final String iconKey;
  final String colorHex;
  final int sortOrder;

  CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.iconKey,
    required this.colorHex,
    required this.sortOrder,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      iconKey: json['icon_key'] as String,
      colorHex: json['color_hex'] as String,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  // Helper to get IconData from key
  IconData get iconData {
    switch (iconKey) {
      case 'restaurant': return Icons.restaurant;
      case 'shopping_bag': return Icons.shopping_bag;
      case 'health_and_safety': return Icons.health_and_safety;
      case 'build': return Icons.build;
      case 'movie': return Icons.movie;
      case 'brush': return Icons.brush;
      case 'fitness_center': return Icons.fitness_center;
      case 'grid_view': return Icons.grid_view;
      case 'local_bar': return Icons.local_bar;
      case 'pets': return Icons.pets;
      case 'flash_on': return Icons.flash_on;
      case 'shopping_basket': return Icons.shopping_basket;
      case 'local_pharmacy': return Icons.local_pharmacy;
      case 'add': return Icons.add;
      default: return Icons.category;
    }
  }

  // Helper to parse Color from Hex String
  Color get color {
    try {
      if (colorHex.startsWith('0x')) {
        return Color(int.parse(colorHex));
      } else if (colorHex.startsWith('#')) {
        return Color(int.parse(colorHex.replaceAll('#', '0xFF')));
      }
      return Colors.grey;
    } catch (e) {
      return Colors.grey;
    }
  }
}
