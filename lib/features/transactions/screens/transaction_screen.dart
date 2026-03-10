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
      appBar: AppBar(
        title: const Text('Transactions', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- 1. Filter Chips ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: Row(
              children: [
                _buildFilterChip(context, ref, 'All', activeFilter),
                const SizedBox(width: 8),
                _buildFilterChip(context, ref, 'Income', activeFilter),
                const SizedBox(width: 8),
                _buildFilterChip(context, ref, 'Expense', activeFilter),
              ],
            ),
          ),
          
          const Divider(),

          // --- 2. Daftar Transaksi ---
          Expanded(
            child: transactionsAsync.when(
              data: (transactions) {
                if (transactions.isEmpty) {
                  return const Center(
                    child: Text("Belum ada transaksi di kategori ini."),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(24.0),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final tx = transactions[index];
                    return _buildTransactionTile(tx);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  // Komponen untuk tombol filter
  Widget _buildFilterChip(BuildContext context, WidgetRef ref, String label, String activeFilter) {
    final isSelected = activeFilter == label;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
      checkmarkColor: AppTheme.primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryColor : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (_) {
        // Ubah state filter saat diklik
        ref.read(transactionFilterProvider.notifier).state = label;
      },
    );
  }

  // Komponen untuk item transaksi (mirip dengan yang ada di Dashboard)
  Widget _buildTransactionTile(Map<String, dynamic> tx) {
    final isExpense = tx['type'] == 'Expense';
    final amountColor = isExpense ? AppTheme.errorColor : AppTheme.primaryColor;
    final sign = isExpense ? "-" : "+";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          // Ikon bisa dinamis berdasarkan kategori nantinya
          child: Icon(
            isExpense ? Icons.shopping_bag_outlined : Icons.account_balance_wallet_outlined, 
            color: Colors.black54,
          ),
        ),
        title: Text(tx['category'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(tx['date'] ?? 'No Date', style: const TextStyle(fontSize: 12)),
        trailing: Text(
          "$sign\$${tx['amount']?.toString() ?? '0'}",
          style: TextStyle(color: amountColor, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}