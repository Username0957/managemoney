import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/transactions_provider.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeFilter = ref.watch(transactionFilterProvider);
    final transactionsAsync = ref.watch(allTransactionsProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Text(
                'Transaction',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.dividerColor),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    const Icon(Icons.search_rounded,
                        color: AppTheme.textSecondary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Search transaction...',
                          hintStyle: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 14),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          filled: false,
                        ),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Filter chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _FilterChip(
                      label: 'All',
                      isSelected: activeFilter == 'All',
                      onTap: () => ref
                          .read(transactionFilterProvider.notifier)
                          .state = 'All'),
                  const SizedBox(width: 8),
                  _FilterChip(
                      label: 'Income',
                      isSelected: activeFilter == 'Income',
                      onTap: () => ref
                          .read(transactionFilterProvider.notifier)
                          .state = 'Income'),
                  const SizedBox(width: 8),
                  _FilterChip(
                      label: 'Expense',
                      isSelected: activeFilter == 'Expense',
                      onTap: () => ref
                          .read(transactionFilterProvider.notifier)
                          .state = 'Expense'),
                ],
              ),
            ),
            const SizedBox(height: 4),

            const Divider(height: 24, color: AppTheme.dividerColor),

            // Transaction list
            Expanded(
              child: transactionsAsync.when(
                data: (transactions) {
                  if (transactions.isEmpty) {
                    return _EmptyState(filter: activeFilter);
                  }

                  // Group by date
                  final grouped = <String, List<Map<String, dynamic>>>{};
                  for (final tx in transactions) {
                    final date = tx['date'] as String? ?? 'No Date';
                    grouped.putIfAbsent(date, () => []).add(tx);
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    itemCount: grouped.length,
                    itemBuilder: (context, groupIndex) {
                      final date = grouped.keys.elementAt(groupIndex);
                      final items = grouped[date]!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              _formatDateLabel(date),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                          ...items
                              .map((tx) => _TransactionTile(tx: tx))
                              .toList(),
                        ],
                      );
                    },
                  );
                },
                loading: () => const Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.primaryColor)),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateLabel(String date) {
    // Simple display – could be enhanced
    try {
      final parts = date.split('-');
      if (parts.length == 3) {
        final months = [
          '', 'January', 'February', 'March', 'April', 'May', 'June',
          'July', 'August', 'September', 'October', 'November', 'December'
        ];
        final month = int.tryParse(parts[1]) ?? 0;
        final day = int.tryParse(parts[2]) ?? 0;
        final year = parts[0];
        final monthName = month > 0 && month <= 12 ? months[month] : '';
        if (monthName.isNotEmpty) {
          // Try to get day name
          final dt = DateTime.tryParse(date);
          if (dt != null) {
            final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
            final dayName = days[dt.weekday - 1];
            return '$dayName, $monthName $day';
          }
        }
      }
    } catch (_) {}
    return date;
  }
}

// ─── Filter Chip ─────────────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label,
      required this.isSelected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.dividerColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ─── Transaction Tile ────────────────────────────────────────────────────────
class _TransactionTile extends StatelessWidget {
  final Map<String, dynamic> tx;
  const _TransactionTile({required this.tx});

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food': return Icons.restaurant_outlined;
      case 'transport': return Icons.directions_car_outlined;
      case 'shopping': return Icons.shopping_bag_outlined;
      case 'bills': return Icons.receipt_outlined;
      case 'entertainment': return Icons.movie_outlined;
      case 'healthcare': return Icons.favorite_border_rounded;
      case 'education': return Icons.school_outlined;
      case 'salary': return Icons.payments_outlined;
      case 'freelance': return Icons.laptop_outlined;
      case 'gift': return Icons.card_giftcard_outlined;
      case 'investment': return Icons.trending_up_outlined;
      default: return Icons.attach_money_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isExpense = tx['type'] == 'Expense';
    final amountColor =
        isExpense ? AppTheme.expenseColor : AppTheme.incomeColor;
    final sign = isExpense ? '-' : '+';
    final category = tx['category'] ?? 'Unknown';
    final note = tx['note'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: amountColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_categoryIcon(category), color: amountColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary),
                ),
                if (note != null && note.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(note,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
          Text(
            '$sign\$${(tx['amount'] ?? 0).toStringAsFixed(2)}',
            style: TextStyle(
                color: amountColor,
                fontWeight: FontWeight.bold,
                fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String filter;
  const _EmptyState({required this.filter});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            filter == 'All'
                ? 'No transactions yet'
                : 'No $filter transactions',
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tap + to add a transaction',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}