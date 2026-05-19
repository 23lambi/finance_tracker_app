import 'dart:io';

import 'package:flutter/material.dart';

import '../models/transaction_model.dart';

class TransactionVisual extends StatelessWidget {
  final TransactionModel transaction;
  final double size;
  final double borderRadius;

  const TransactionVisual({
    super.key,
    required this.transaction,
    this.size = 56,
    this.borderRadius = 18,
  });

  @override
  Widget build(BuildContext context) {
    final imagePath = transaction.photoPath;

    if (imagePath != null && imagePath.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.file(
          File(imagePath),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _CategoryFallback(
              category: transaction.category,
              type: transaction.type,
              size: size,
              borderRadius: borderRadius,
            );
          },
        ),
      );
    }

    return _CategoryFallback(
      category: transaction.category,
      type: transaction.type,
      size: size,
      borderRadius: borderRadius,
    );
  }
}

class _CategoryFallback extends StatelessWidget {
  final String category;
  final TransactionType type;
  final double size;
  final double borderRadius;

  const _CategoryFallback({
    required this.category,
    required this.type,
    required this.size,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _paletteForCategory(category, type);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [palette.background, palette.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Icon(
        _iconForCategory(category, type),
        color: Colors.white,
        size: size * 0.42,
      ),
    );
  }

  IconData _iconForCategory(String category, TransactionType type) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant_rounded;
      case 'transport':
        return Icons.directions_car_filled_rounded;
      case 'bills':
        return Icons.receipt_long_rounded;
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'salary':
        return Icons.payments_rounded;
      case 'entertainment':
        return Icons.movie_rounded;
      case 'health':
        return Icons.favorite_rounded;
      default:
        return type == TransactionType.income
            ? Icons.south_west_rounded
            : Icons.north_east_rounded;
    }
  }

  _CategoryPalette _paletteForCategory(String category, TransactionType type) {
    switch (category.toLowerCase()) {
      case 'food':
        return const _CategoryPalette(
          background: Color(0xFFE07A5F),
          accent: Color(0xFFF4A261),
        );
      case 'transport':
        return const _CategoryPalette(
          background: Color(0xFF3D5A80),
          accent: Color(0xFF669BBC),
        );
      case 'bills':
        return const _CategoryPalette(
          background: Color(0xFF6D597A),
          accent: Color(0xFFB56576),
        );
      case 'shopping':
        return const _CategoryPalette(
          background: Color(0xFF6B705C),
          accent: Color(0xFFA5A58D),
        );
      case 'salary':
        return const _CategoryPalette(
          background: Color(0xFF1B4332),
          accent: Color(0xFF40916C),
        );
      case 'entertainment':
        return const _CategoryPalette(
          background: Color(0xFF5E548E),
          accent: Color(0xFF9F86C0),
        );
      case 'health':
        return const _CategoryPalette(
          background: Color(0xFFBC4749),
          accent: Color(0xFFF28482),
        );
      default:
        return type == TransactionType.income
            ? const _CategoryPalette(
                background: Color(0xFF1B4332),
                accent: Color(0xFF52B788),
              )
            : const _CategoryPalette(
                background: Color(0xFF9B2226),
                accent: Color(0xFFE76F51),
              );
    }
  }
}

class _CategoryPalette {
  final Color background;
  final Color accent;

  const _CategoryPalette({
    required this.background,
    required this.accent,
  });
}
