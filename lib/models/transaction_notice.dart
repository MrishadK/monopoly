import 'package:flutter/material.dart';

class TransactionNotice {
  final String id;
  final String type; // 'trade', 'rent', 'mortgage', 'redeem', 'sell', 'buy', 'auction', 'tax'
  final String title;
  final String description;
  final String icon;
  final int colorValue;

  const TransactionNotice({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    required this.colorValue,
  });

  Color get color => Color(colorValue);

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type,
    'title': title,
    'description': description,
    'icon': icon,
    'colorValue': colorValue,
  };

  factory TransactionNotice.fromMap(Map<String, dynamic> map) => TransactionNotice(
    id: map['id'] ?? '',
    type: map['type'] ?? 'general',
    title: map['title'] ?? '',
    description: map['description'] ?? '',
    icon: map['icon'] ?? '💰',
    colorValue: (map['colorValue'] as num?)?.toInt() ?? 0xFF0F172A,
  );
}
