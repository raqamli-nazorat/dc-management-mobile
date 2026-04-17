import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

const _kFilterKey = 'expense_filter_v1';
const _unset = Object();

class ExpenseFilter {
  final int? projectId;
  final String? projectTitle;
  final int? categoryId;
  final String? categoryTitle;
  final double? amountMin;
  final double? amountMax;
  final DateTime? createdAt;
  final DateTime? paidAt;
  final DateTime? confirmedAt;

  const ExpenseFilter({
    this.projectId,
    this.projectTitle,
    this.categoryId,
    this.categoryTitle,
    this.amountMin,
    this.amountMax,
    this.createdAt,
    this.paidAt,
    this.confirmedAt,
  });

  bool get isActive =>
      projectId != null ||
      categoryId != null ||
      amountMin != null ||
      amountMax != null ||
      createdAt != null ||
      paidAt != null ||
      confirmedAt != null;

  Map<String, dynamic> toJson() => {
        'project_id': projectId,
        'project_title': projectTitle,
        'category_id': categoryId,
        'category_title': categoryTitle,
        'amount_min': amountMin,
        'amount_max': amountMax,
        'created_at': createdAt?.toIso8601String(),
        'paid_at': paidAt?.toIso8601String(),
        'confirmed_at': confirmedAt?.toIso8601String(),
      };

  factory ExpenseFilter.fromJson(Map<String, dynamic> json) => ExpenseFilter(
        projectId: json['project_id'] as int?,
        projectTitle: json['project_title'] as String?,
        categoryId: json['category_id'] as int?,
        categoryTitle: json['category_title'] as String?,
        amountMin: (json['amount_min'] as num?)?.toDouble(),
        amountMax: (json['amount_max'] as num?)?.toDouble(),
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'] as String)
            : null,
        paidAt: json['paid_at'] != null
            ? DateTime.tryParse(json['paid_at'] as String)
            : null,
        confirmedAt: json['confirmed_at'] != null
            ? DateTime.tryParse(json['confirmed_at'] as String)
            : null,
      );

  static Future<ExpenseFilter> loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kFilterKey);
    if (raw == null) return const ExpenseFilter();
    try {
      return ExpenseFilter.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const ExpenseFilter();
    }
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kFilterKey, jsonEncode(toJson()));
  }

  static Future<void> clearSaved() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kFilterKey);
  }

  ExpenseFilter copyWith({
    Object? projectId = _unset,
    Object? projectTitle = _unset,
    Object? categoryId = _unset,
    Object? categoryTitle = _unset,
    Object? amountMin = _unset,
    Object? amountMax = _unset,
    Object? createdAt = _unset,
    Object? paidAt = _unset,
    Object? confirmedAt = _unset,
  }) =>
      ExpenseFilter(
        projectId: projectId == _unset ? this.projectId : projectId as int?,
        projectTitle: projectTitle == _unset
            ? this.projectTitle
            : projectTitle as String?,
        categoryId:
            categoryId == _unset ? this.categoryId : categoryId as int?,
        categoryTitle: categoryTitle == _unset
            ? this.categoryTitle
            : categoryTitle as String?,
        amountMin:
            amountMin == _unset ? this.amountMin : amountMin as double?,
        amountMax:
            amountMax == _unset ? this.amountMax : amountMax as double?,
        createdAt:
            createdAt == _unset ? this.createdAt : createdAt as DateTime?,
        paidAt: paidAt == _unset ? this.paidAt : paidAt as DateTime?,
        confirmedAt: confirmedAt == _unset
            ? this.confirmedAt
            : confirmedAt as DateTime?,
      );
}
