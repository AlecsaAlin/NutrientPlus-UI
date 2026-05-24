import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'auth_service.dart';

class PriceService {
  static String get _baseUrl => AppConfig.baseUrl;

  static Future<RecipePriceResponse?> getRecipePrice({
    required int recipeId,
  }) async {
    final token = await AuthService.getToken();
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/pricing/recipe/$recipeId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return RecipePriceResponse.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}


class IngredientPriceDetail {
  final String name;
  final double? quantityG;
  final double? pieceCount;
  final double? pricePerKg;   
  final double? pricePerPiece;
  final double? cost;

  IngredientPriceDetail({
    required this.name,
    this.quantityG,
    this.pieceCount,
    this.pricePerKg,
    this.pricePerPiece,
    this.cost,
  });

  factory IngredientPriceDetail.fromJson(Map<String, dynamic> json) {
    final p100g = (json['price_per_100g'] as num?)?.toDouble();
    return IngredientPriceDetail(
      name: json['name'] ?? '',
      quantityG: (json['quantity_g'] as num?)?.toDouble(),
      pieceCount: (json['piece_count'] as num?)?.toDouble(),
      pricePerKg: p100g != null ? p100g * 10 : null,
      pricePerPiece: (json['price_per_piece'] as num?)?.toDouble(),
      cost: (json['cost'] as num?)?.toDouble(),
    );
  }

  String get quantityLabel {
    if (quantityG != null) {
      final g = quantityG!;
      if (g >= 1000) return '${(g / 1000).toStringAsFixed(2)} kg';
      return '${g % 1 == 0 ? g.toInt() : g.toStringAsFixed(1)} g';
    }
    if (pieceCount != null) {
      final n = pieceCount!;
      return '${n % 1 == 0 ? n.toInt() : n.toStringAsFixed(1)} pcs';
    }
    return '';
  }

  String get unitPriceLabel {
    if (pricePerPiece != null) {
      return '${pricePerPiece!.toStringAsFixed(2)} €/pc';
    }
    if (pricePerKg != null) {
      return '${(pricePerKg! / 10).toStringAsFixed(2)} €/100g';
    }
    return '';
  }
}

class RecipePriceResponse {
  final int recipeId;
  final double? totalCost;
  final String currency;
  final List<IngredientPriceDetail> ingredients;
  final int pricedCount;
  final int ingredientCount;

  RecipePriceResponse({
    required this.recipeId,
    this.totalCost,
    required this.currency,
    required this.ingredients,
    required this.pricedCount,
    required this.ingredientCount,
  });

  factory RecipePriceResponse.fromJson(Map<String, dynamic> json) {
    final rawList = json['ingredients'] as List<dynamic>? ?? [];
    return RecipePriceResponse(
      recipeId: json['recipe_id'] ?? 0,
      totalCost: (json['total_cost'] as num?)?.toDouble(),
      currency: json['currency'] ?? 'EUR',
      ingredients: rawList
          .map((i) => IngredientPriceDetail.fromJson(i as Map<String, dynamic>))
          .toList(),
      pricedCount: json['priced_count'] ?? 0,
      ingredientCount: json['ingredient_count'] ?? 0,
    );
  }

  String get coverageLabel {
    if (ingredientCount == 0) return '';
    if (pricedCount == ingredientCount) return 'All $ingredientCount ingredients priced';
    return '$pricedCount of $ingredientCount ingredients priced';
  }

  bool get hasCost => totalCost != null && totalCost! > 0;
}
