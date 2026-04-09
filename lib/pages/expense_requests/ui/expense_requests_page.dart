import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/router/route_names.dart';
import '../../../entities/expense_request/model/expense_request.dart';
import '../../../entities/expense_request/api/expense_request_repository.dart';
import '../../../shared/api/dio_client.dart';

// Provider for the list
final _expenseRepoProvider = Provider(
  (ref) => ExpenseRequestRepository(DioClient.create()),
);

final _statusFilterProvider = StateProvider<String?>((ref) => null);

final expenseRequestsProvider =
    FutureProvider.autoDispose.family<List<ExpenseRequest>, String?>(
  (ref, status) async {
    final repo = ref.read(_expenseRepoProvider);
    return repo.getAll(status: status);
  },
);

class ExpenseRequestsPage extends ConsumerWidget {
  const ExpenseRequestsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedStatus = ref.watch(_statusFilterProvider);
    final requestsAsync = ref.watch(expenseRequestsProvider(selectedStatus));

    return Scaffold(
      backgroundColor: AppColors.obsidian,
      appBar: AppBar(
        title: const Text("Xarajat so'rovlari"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: "Yangi so'rov",
            onPressed: () => context.pushNamed(RouteNames.expenseRequestCreate),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          _StatusFilterBar(
            selected: selectedStatus,
            onChanged: (v) => ref.read(_statusFilterProvider.notifier).state = v,
          ),

          // List
          Expanded(
            child: requestsAsync.when(
              loading: () => const _LoadingSkeleton(),
              error: (e, _) => _ErrorView(
                onRetry: () => ref.invalidate(expenseRequestsProvider(selectedStatus)),
              ),
              data: (items) => items.isEmpty
                  ? const _EmptyView()
                  : ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: items.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (_, i) => _ExpenseRequestTile(item: items[i]),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusFilterBar extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onChanged;

  const _StatusFilterBar({required this.selected, required this.onChanged});

  static const _filters = [
    (null, 'Barchasi'),
    ('pending', 'Kutilmoqda'),
    ('approved', 'Tasdiqlangan'),
    ('rejected', 'Rad etilgan'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.smoke)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: _filters.map((f) {
          final isActive = selected == f.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
            child: GestureDetector(
              onTap: () => onChanged(f.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.gold : AppColors.graphite,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive ? AppColors.gold : AppColors.smoke,
                  ),
                ),
                child: Center(
                  child: Text(
                    f.$2,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isActive ? AppColors.obsidian : AppColors.pearl,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ExpenseRequestTile extends StatelessWidget {
  final ExpenseRequest item;
  const _ExpenseRequestTile({required this.item});

  Color get _statusColor {
    switch (item.status) {
      case ExpenseStatus.approved:
        return AppColors.success;
      case ExpenseStatus.rejected:
        return AppColors.danger;
      case ExpenseStatus.pending:
        return AppColors.warning;
    }
  }

  String get _maskedCard {
    final digits = item.cardNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 4) return item.cardNumber;
    return '**** **** **** ${digits.substring(digits.length - 4)}';
  }

  String get _formattedAmount {
    return '${item.amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} UZS';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.charcoal,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.smoke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: amount + status badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formattedAmount,
                style: AppTextStyles.h3.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
              _StatusBadge(status: item.status, color: _statusColor),
            ],
          ),
          const SizedBox(height: 8),

          // Reason
          Text(
            item.reason,
            style: AppTextStyles.bodyMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),

          // Footer: card + date
          Row(
            children: [
              const Icon(Icons.credit_card, size: 14, color: AppColors.silver),
              const SizedBox(width: 4),
              Text(_maskedCard, style: AppTextStyles.bodySmall),
              const Spacer(),
              Text(
                _formatDate(item.createdAt),
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),

          // Worker info if available
          if (item.worker != null) ...[
            const SizedBox(height: 8),
            const Divider(color: AppColors.smoke, height: 1),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 14, color: AppColors.silver),
                const SizedBox(width: 4),
                Text(
                  item.worker!.fullName,
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(width: 8),
                Text(
                  '• ${item.worker!.position}',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final ExpenseStatus status;
  final Color color;
  const _StatusBadge({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Text(
        status.label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color),
      ),
    );
  }
}

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: 5,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, _) => Container(
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.charcoal,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.smoke),
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.receipt_long_outlined,
              size: 48, color: AppColors.ash),
          const SizedBox(height: 16),
          const Text("So'rovlar topilmadi", style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Text(
            "Yangi so'rov yaratish uchun + tugmasini bosing",
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
          const SizedBox(height: 16),
          const Text("Xatolik yuz berdi", style: AppTextStyles.h3),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text('Qayta urinish'),
          ),
        ],
      ),
    );
  }
}
