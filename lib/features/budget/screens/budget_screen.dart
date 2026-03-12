import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/budget_provider.dart';
import '../services/budget_service.dart';

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  static const List<_CategoryMeta> _categories = [
    _CategoryMeta('Food & Dining', Icons.restaurant_outlined, Color(0xFFFF6B6B)),
    _CategoryMeta('Transport', Icons.directions_car_outlined, Color(0xFF4ECDC4)),
    _CategoryMeta('Shopping', Icons.shopping_bag_outlined, Color(0xFFFFBE0B)),
    _CategoryMeta('Bills & Utilities', Icons.receipt_outlined, Color(0xFF3A86FF)),
    _CategoryMeta('Entertainment', Icons.movie_outlined, Color(0xFFFF006E)),
    _CategoryMeta('Healthcare', Icons.favorite_border_rounded, Color(0xFFE63946)),
    _CategoryMeta('Education', Icons.school_outlined, Color(0xFF8338EC)),
    _CategoryMeta('Other', Icons.more_horiz_rounded, Color(0xFF6B7280)),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetsProvider);
    final expensesAsync = ref.watch(expensesByCategoryProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Text(
                'Budget',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Text(
                'Set monthly spending limits per category',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
            ),

            // Budget list
            Expanded(
              child: budgetsAsync.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.primaryColor)),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (budgetMap) {
                  return expensesAsync.when(
                    loading: () => const Center(
                        child: CircularProgressIndicator(
                            color: AppTheme.primaryColor)),
                    error: (e, _) => Center(child: Text('Error: $e')),
                    data: (expenseMap) {
                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final cat = _categories[index];
                          // Map to old category keys if needed
                          final budgetKey = _getBudgetKey(cat.name);
                          final limit = budgetMap[budgetKey] ?? 0.0;
                          final spent = expenseMap[budgetKey] ?? 0.0;
                          return _BudgetCard(
                            cat: cat,
                            limit: limit,
                            spent: spent,
                            onSetLimit: () => _showSetLimitDialog(
                                context, ref, budgetKey, limit),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getBudgetKey(String displayName) {
    // Map display names to Firestore keys
    switch (displayName) {
      case 'Food & Dining': return 'Food';
      case 'Bills & Utilities': return 'Bills';
      default: return displayName;
    }
  }

  void _showSetLimitDialog(
      BuildContext context, WidgetRef ref, String category, double currentLimit) {
    final controller = TextEditingController(
        text: currentLimit > 0 ? currentLimit.toStringAsFixed(0) : '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Set limit for $category'),
          content: TextField(
            controller: controller,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Enter amount (e.g., 500)',
              prefixText: '\$ ',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel',
                  style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor),
              onPressed: () async {
                final newLimit = double.tryParse(controller.text) ?? 0.0;
                if (newLimit > 0) {
                  await ref
                      .read(budgetServiceProvider)
                      .setBudget(category: category, limitAmount: newLimit);
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final _CategoryMeta cat;
  final double limit;
  final double spent;
  final VoidCallback onSetLimit;

  const _BudgetCard({
    required this.cat,
    required this.limit,
    required this.spent,
    required this.onSetLimit,
  });

  @override
  Widget build(BuildContext context) {
    double progress = limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;
    final isExceeded = spent > limit && limit > 0;
    final progressColor =
        isExceeded ? AppTheme.expenseColor : AppTheme.primaryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isExceeded
            ? Border.all(
                color: AppTheme.expenseColor.withValues(alpha: 0.3))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Category icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cat.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(cat.icon, color: cat.color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cat.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      limit > 0
                          ? '\$${spent.toStringAsFixed(0)} spent of \$${limit.toStringAsFixed(0)}'
                          : '\$${spent.toStringAsFixed(0)} spent',
                      style: TextStyle(
                        fontSize: 12,
                        color: isExceeded
                            ? AppTheme.expenseColor
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onSetLimit,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  backgroundColor:
                      AppTheme.primaryColor.withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text(
                  'Set limit',
                  style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          if (limit > 0) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: Colors.grey.shade100,
                color: progressColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryMeta {
  final String name;
  final IconData icon;
  final Color color;
  const _CategoryMeta(this.name, this.icon, this.color);
}