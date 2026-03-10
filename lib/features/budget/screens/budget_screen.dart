import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/budget_provider.dart';
import '../services/budget_service.dart';

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  // Daftar kategori pengeluaran standar (bisa disesuaikan)
  final List<String> _categories = const [
    'Food', 'Transport', 'Shopping', 'Bills', 'Entertainment', 'Healthcare', 'Education', 'Other'
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Pantau data budget dan pengeluaran secara real-time
    final budgetsAsync = ref.watch(budgetsProvider);
    final expensesAsync = ref.watch(expensesByCategoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: Text(
              "Set monthly spending limits per category",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
          const SizedBox(height: 8),
          
          Expanded(
            child: budgetsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text("Error: $e")),
              data: (budgetMap) {
                return expensesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text("Error: $e")),
                  data: (expenseMap) {
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        final limit = budgetMap[category] ?? 0.0;
                        final spent = expenseMap[category] ?? 0.0;
                        
                        return _buildBudgetCard(context, ref, category, limit, spent);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetCard(BuildContext context, WidgetRef ref, String category, double limit, double spent) {
    // Hitung persentase progress (cegah pembagian dengan 0)
    double progress = limit > 0 ? (spent / limit) : 0.0;
    if (progress > 1.0) progress = 1.0; // Maksimal progress bar penuh

    final isExceeded = spent > limit && limit > 0;
    final progressColor = isExceeded ? AppTheme.errorColor : AppTheme.primaryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isExceeded ? AppTheme.errorColor.withValues(alpha: 0.5) : Colors.transparent),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.category_outlined, color: Colors.black54), // Bisa dikustomisasi ikonnya
                  const SizedBox(width: 12),
                  Text(category, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              TextButton(
                onPressed: () => _showSetLimitDialog(context, ref, category, limit),
                child: const Text("Set limit", style: TextStyle(color: AppTheme.primaryColor)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          Text(
            "\$${spent.toStringAsFixed(0)} spent ${limit > 0 ? 'of \$${limit.toStringAsFixed(0)}' : ''}",
            style: TextStyle(color: isExceeded ? AppTheme.errorColor : Colors.grey.shade600, fontSize: 14),
          ),
          
          if (limit > 0) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                color: progressColor,
              ),
            ),
          ]
        ],
      ),
    );
  }

  // Dialog untuk menginput limit baru
  void _showSetLimitDialog(BuildContext context, WidgetRef ref, String category, double currentLimit) {
    final controller = TextEditingController(text: currentLimit > 0 ? currentLimit.toStringAsFixed(0) : '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Set Limit for $category'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'Enter amount (e.g., 500)',
              prefixText: '\$ ',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
              onPressed: () async {
                final newLimit = double.tryParse(controller.text) ?? 0.0;
                if (newLimit > 0) {
                  // Simpan ke Firestore
                  await ref.read(budgetServiceProvider).setBudget(category: category, limitAmount: newLimit);
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