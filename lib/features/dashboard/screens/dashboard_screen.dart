import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/dashboard_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userDataProvider);
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final recentAsync = ref.watch(recentTransactionsProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.primaryColor,
          onRefresh: () async {
            ref.invalidate(userDataProvider);
            ref.invalidate(dashboardSummaryProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Balance Card ─────────────────────────────────────────────
                summaryAsync.when(
                  data: (summary) {
                    final name = userAsync.whenOrNull(
                          data: (u) => u?['name'] as String?,
                        ) ??
                        'User';
                    return _BalanceCard(
                      name: name ?? 'User',
                      balance: summary.balance,
                      totalIncome: summary.totalIncome,
                      totalExpense: summary.totalExpense,
                    );
                  },
                  loading: () => const _CardSkeleton(height: 180),
                  error: (e, _) => Text('Error: $e'),
                ),

                const SizedBox(height: 24),

                // ── Spending Overview ─────────────────────────────────────────
                const Text(
                  'Spending Overview',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                summaryAsync.when(
                  data: (summary) => _SpendingOverviewCard(
                    expenseByCategory: summary.expenseByCategory,
                    totalExpense: summary.totalExpense,
                  ),
                  loading: () => const _CardSkeleton(height: 120),
                  error: (e, _) => Text('Error: $e'),
                ),

                const SizedBox(height: 24),

                // ── Recent Transactions ───────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Transactions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'See all >',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                recentAsync.when(
                  data: (transactions) {
                    if (transactions.isEmpty) return _EmptyTransactions();
                    return Column(
                      children: transactions
                          .map((tx) => _TransactionTile(tx: tx))
                          .toList(),
                    );
                  },
                  loading: () => const Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.primaryColor)),
                  error: (e, _) => Text('Error: $e'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BALANCE CARD
// ─────────────────────────────────────────────────────────────────────────────
class _BalanceCard extends StatelessWidget {
  final String name;
  final double balance;
  final double totalIncome;
  final double totalExpense;

  const _BalanceCard({
    required this.name,
    required this.balance,
    required this.totalIncome,
    required this.totalExpense,
  });

  String _fmt(double v) {
    if (v >= 1000000) return '\$${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '\$${(v / 1000).toStringAsFixed(1)}K';
    return '\$${v.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.credit_card_rounded,
                    size: 16, color: AppTheme.primaryColor),
              ),
              const SizedBox(width: 8),
              const Text('Total Balance',
                  style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 12),

          // Balance amount
          Text('\$${balance.toStringAsFixed(2)}',
              style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary)),
          Text('Hello, $name!',
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.textSecondary)),

          const SizedBox(height: 16),
          const Divider(color: AppTheme.dividerColor, height: 1),
          const SizedBox(height: 16),

          // Income / Expense Row ← Data real dari Firestore
          Row(
            children: [
              Expanded(
                child: _IncomeExpenseItem(
                  icon: Icons.trending_up_rounded,
                  label: 'Income',
                  amount: _fmt(totalIncome),
                  color: AppTheme.incomeColor,
                ),
              ),
              Container(
                  width: 1, height: 40, color: AppTheme.dividerColor),
              Expanded(
                child: _IncomeExpenseItem(
                  icon: Icons.trending_down_rounded,
                  label: 'Expenses',
                  amount: _fmt(totalExpense),
                  color: AppTheme.expenseColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IncomeExpenseItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String amount;
  final Color color;

  const _IncomeExpenseItem({
    required this.icon,
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textSecondary)),
              Text(amount,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: color)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SPENDING OVERVIEW CARD
// ─────────────────────────────────────────────────────────────────────────────
class _SpendingOverviewCard extends StatelessWidget {
  final Map<String, double> expenseByCategory;
  final double totalExpense;

  const _SpendingOverviewCard({
    required this.expenseByCategory,
    required this.totalExpense,
  });

  static const Map<String, Color> _colors = {
    'Food': Color(0xFFFF6B6B),
    'Transport': Color(0xFF4ECDC4),
    'Shopping': Color(0xFFFFBE0B),
    'Bills': Color(0xFF3A86FF),
    'Entertainment': Color(0xFFFF006E),
    'Healthcare': Color(0xFFE63946),
    'Education': Color(0xFF8338EC),
    'Salary': Color(0xFF22C55E),
    'Freelance': Color(0xFF06B6D4),
    'Gift': Color(0xFFF59E0B),
    'Investment': Color(0xFF10B981),
    'Other': Color(0xFF6B7280),
  };

  static const Map<String, IconData> _icons = {
    'Food': Icons.restaurant_outlined,
    'Transport': Icons.directions_car_outlined,
    'Shopping': Icons.shopping_bag_outlined,
    'Bills': Icons.receipt_outlined,
    'Entertainment': Icons.movie_outlined,
    'Healthcare': Icons.favorite_border_rounded,
    'Education': Icons.school_outlined,
    'Other': Icons.more_horiz_rounded,
  };

  Color _color(String cat) => _colors[cat] ?? const Color(0xFF6B7280);
  IconData _icon(String cat) =>
      _icons[cat] ?? Icons.attach_money_outlined;

  @override
  Widget build(BuildContext context) {
    // Empty state
    if (totalExpense == 0 || expenseByCategory.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 2)),
          ],
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.pie_chart_outline_rounded,
                  size: 44, color: AppTheme.textSecondary),
              SizedBox(height: 8),
              Text('No spending data yet',
                  style: TextStyle(
                      fontSize: 13, color: AppTheme.textSecondary)),
              Text('Add an expense to see your overview',
                  style: TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary)),
            ],
          ),
        ),
      );
    }

    // Sort & clamp top 4 + sisanya jadi "Other"
    final sorted = expenseByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    List<MapEntry<String, double>> top;
    if (sorted.length > 4) {
      top = sorted.take(4).toList();
      final rest = sorted.skip(4).fold(0.0, (s, e) => s + e.value);
      final existingOther = top.indexWhere((e) => e.key == 'Other');
      if (existingOther >= 0) {
        top[existingOther] =
            MapEntry('Other', top[existingOther].value + rest);
      } else {
        top.add(MapEntry('Other', rest));
      }
    } else {
      top = sorted;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          // ── Top row: donut + legend ──────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Donut chart
              SizedBox(
                width: 96,
                height: 96,
                child: CustomPaint(
                  painter: _DonutPainter(
                    segments: top,
                    total: totalExpense,
                    colors: top.map((e) => _color(e.key)).toList(),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          totalExpense >= 1000
                              ? '\$${(totalExpense / 1000).toStringAsFixed(1)}K'
                              : '\$${totalExpense.toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary),
                        ),
                        const Text('spent',
                            style: TextStyle(
                                fontSize: 9,
                                color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),

              // Legend
              Expanded(
                child: Column(
                  children: top.map((e) {
                    final pct = totalExpense > 0
                        ? (e.value / totalExpense * 100)
                            .toStringAsFixed(1)
                        : '0';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                                color: _color(e.key),
                                shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(e.key,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary)),
                          ),
                          Text('$pct%',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: AppTheme.dividerColor),
          const SizedBox(height: 12),

          // ── Category breakdown bars ──────────────────────────────────────
          ...top.map((e) {
            final pct = totalExpense > 0 ? e.value / totalExpense : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: _color(e.key).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(_icon(e.key),
                        size: 14, color: _color(e.key)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(e.key,
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.textPrimary)),
                            Text(
                              '\$${e.value.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 5,
                            backgroundColor: Colors.grey.shade100,
                            color: _color(e.key),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DONUT CHART PAINTER
// ─────────────────────────────────────────────────────────────────────────────
class _DonutPainter extends CustomPainter {
  final List<MapEntry<String, double>> segments;
  final double total;
  final List<Color> colors;

  const _DonutPainter(
      {required this.segments,
      required this.total,
      required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    const gap = 0.04; // gap antar segment (radian)
    final rect = Rect.fromLTWH(0, 0, size.width, size.height).deflate(8);
    double angle = -pi / 2;

    for (int i = 0; i < segments.length; i++) {
      final sweep = total > 0
          ? (segments[i].value / total) * 2 * pi - gap
          : 0.0;
      if (sweep <= 0) continue;

      canvas.drawArc(
        rect,
        angle,
        sweep,
        false,
        Paint()
          ..color = colors[i]
          ..style = PaintingStyle.stroke
          ..strokeWidth = 14
          ..strokeCap = StrokeCap.butt,
      );
      angle += sweep + gap;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.segments != segments || old.total != total;
}

// ─────────────────────────────────────────────────────────────────────────────
// TRANSACTION TILE
// ─────────────────────────────────────────────────────────────────────────────
class _TransactionTile extends StatelessWidget {
  final Map<String, dynamic> tx;
  const _TransactionTile({required this.tx});

  IconData _icon(String cat) {
    switch (cat.toLowerCase()) {
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
    final color = isExpense ? AppTheme.expenseColor : AppTheme.incomeColor;
    final sign = isExpense ? '-' : '+';
    final category = tx['category'] as String? ?? 'Unknown';
    final date = tx['date'] as String? ?? '';
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
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_icon(category), color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary)),
                const SizedBox(height: 2),
                Text(
                  (note != null && note.isNotEmpty) ? note : date,
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            '$sign\$${(tx['amount'] as num? ?? 0).toStringAsFixed(2)}',
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// UTILITY WIDGETS
// ─────────────────────────────────────────────────────────────────────────────
class _CardSkeleton extends StatelessWidget {
  final double height;
  const _CardSkeleton({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: const Center(
          child:
              CircularProgressIndicator(color: AppTheme.primaryColor)),
    );
  }
}

class _EmptyTransactions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: const Center(
        child: Column(
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 48, color: AppTheme.textSecondary),
            SizedBox(height: 12),
            Text('No transactions yet',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary)),
            SizedBox(height: 4),
            Text('Tap + to add your first transaction',
                style:
                    TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }
}