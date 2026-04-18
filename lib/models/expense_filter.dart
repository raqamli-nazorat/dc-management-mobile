import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

const _kFilterKey = 'expense_filter_v2';
const _unset = Object();

class ExpenseFilter {
  final int? projectId;
  final String? projectTitle;
  final int? categoryId;
  final String? categoryTitle;
  final int? toifaId;
  final String? toifaTitle;
  final double? amountMin;
  final double? amountMax;
  // date ranges
  final DateTime? createdAtFrom;
  final DateTime? createdAtTo;
  final DateTime? paidAtFrom;
  final DateTime? paidAtTo;
  final DateTime? confirmedAtFrom;
  final DateTime? confirmedAtTo;

  const ExpenseFilter({
    this.projectId,
    this.projectTitle,
    this.categoryId,
    this.categoryTitle,
    this.toifaId,
    this.toifaTitle,
    this.amountMin,
    this.amountMax,
    this.createdAtFrom,
    this.createdAtTo,
    this.paidAtFrom,
    this.paidAtTo,
    this.confirmedAtFrom,
    this.confirmedAtTo,
  });

  bool get isActive =>
      projectId != null ||
      categoryId != null ||
      toifaId != null ||
      amountMin != null ||
      amountMax != null ||
      createdAtFrom != null ||
      createdAtTo != null ||
      paidAtFrom != null ||
      paidAtTo != null ||
      confirmedAtFrom != null ||
      confirmedAtTo != null;

  Map<String, dynamic> toJson() => {
        'project_id': projectId,
        'project_title': projectTitle,
        'category_id': categoryId,
        'category_title': categoryTitle,
        'toifa_id': toifaId,
        'toifa_title': toifaTitle,
        'amount_min': amountMin,
        'amount_max': amountMax,
        'created_at_from': createdAtFrom?.toIso8601String(),
        'created_at_to': createdAtTo?.toIso8601String(),
        'paid_at_from': paidAtFrom?.toIso8601String(),
        'paid_at_to': paidAtTo?.toIso8601String(),
        'confirmed_at_from': confirmedAtFrom?.toIso8601String(),
        'confirmed_at_to': confirmedAtTo?.toIso8601String(),
      };

  factory ExpenseFilter.fromJson(Map<String, dynamic> json) => ExpenseFilter(
        projectId: json['project_id'] as int?,
        projectTitle: json['project_title'] as String?,
        categoryId: json['category_id'] as int?,
        categoryTitle: json['category_title'] as String?,
        toifaId: json['toifa_id'] as int?,
        toifaTitle: json['toifa_title'] as String?,
        amountMin: (json['amount_min'] as num?)?.toDouble(),
        amountMax: (json['amount_max'] as num?)?.toDouble(),
        createdAtFrom: _parseDate(json['created_at_from']),
        createdAtTo: _parseDate(json['created_at_to']),
        paidAtFrom: _parseDate(json['paid_at_from']),
        paidAtTo: _parseDate(json['paid_at_to']),
        confirmedAtFrom: _parseDate(json['confirmed_at_from']),
        confirmedAtTo: _parseDate(json['confirmed_at_to']),
      );

  static DateTime? _parseDate(dynamic v) =>
      v != null ? DateTime.tryParse(v as String) : null;

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
    Object? toifaId = _unset,
    Object? toifaTitle = _unset,
    Object? amountMin = _unset,
    Object? amountMax = _unset,
    Object? createdAtFrom = _unset,
    Object? createdAtTo = _unset,
    Object? paidAtFrom = _unset,
    Object? paidAtTo = _unset,
    Object? confirmedAtFrom = _unset,
    Object? confirmedAtTo = _unset,
  }) =>
      ExpenseFilter(
        projectId: projectId == _unset ? this.projectId : projectId as int?,
        projectTitle: projectTitle == _unset ? this.projectTitle : projectTitle as String?,
        categoryId: categoryId == _unset ? this.categoryId : categoryId as int?,
        categoryTitle: categoryTitle == _unset ? this.categoryTitle : categoryTitle as String?,
        toifaId: toifaId == _unset ? this.toifaId : toifaId as int?,
        toifaTitle: toifaTitle == _unset ? this.toifaTitle : toifaTitle as String?,
        amountMin: amountMin == _unset ? this.amountMin : amountMin as double?,
        amountMax: amountMax == _unset ? this.amountMax : amountMax as double?,
        createdAtFrom: createdAtFrom == _unset ? this.createdAtFrom : createdAtFrom as DateTime?,
        createdAtTo: createdAtTo == _unset ? this.createdAtTo : createdAtTo as DateTime?,
        paidAtFrom: paidAtFrom == _unset ? this.paidAtFrom : paidAtFrom as DateTime?,
        paidAtTo: paidAtTo == _unset ? this.paidAtTo : paidAtTo as DateTime?,
        confirmedAtFrom: confirmedAtFrom == _unset ? this.confirmedAtFrom : confirmedAtFrom as DateTime?,
        confirmedAtTo: confirmedAtTo == _unset ? this.confirmedAtTo : confirmedAtTo as DateTime?,
      );
}
