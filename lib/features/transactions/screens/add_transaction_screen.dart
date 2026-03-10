import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../services/transaction_service.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  String _selectedType = 'Expense'; // Default ke pengeluaran
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String? _selectedCategory;
  bool _isLoading = false;

  // Daftar kategori sederhana
  final List<String> _expenseCategories = ['Food', 'Transport', 'Shopping', 'Bills', 'Entertainment', 'Other'];
  final List<String> _incomeCategories = ['Salary', 'Freelance', 'Gift', 'Investment', 'Other'];

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _handleSave() async {
    if (_amountController.text.isEmpty || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nominal dan Kategori wajib diisi!")),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(transactionServiceProvider).addTransaction(
            type: _selectedType,
            amount: double.parse(_amountController.text),
            category: _selectedCategory!,
            date: _selectedDate,
            note: _noteController.text.trim(),
          );

      if (mounted) {
        Navigator.pop(context); // Tutup halaman setelah berhasil simpan
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Transaksi berhasil ditambahkan!")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = _selectedType == 'Expense' ? _expenseCategories : _incomeCategories;
    final activeColor = _selectedType == 'Expense' ? AppTheme.errorColor : AppTheme.primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transaction'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Segmented Control (Expense / Income)
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(child: _buildTypeButton('Expense', AppTheme.errorColor)),
                  Expanded(child: _buildTypeButton('Income', AppTheme.primaryColor)),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 2. Amount Input
            const Text("Amount", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: activeColor),
              decoration: InputDecoration(
                prefixText: '\$ ',
                prefixStyle: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: activeColor),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: activeColor, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 3. Category Grid (Menggunakan Wrap agar responsif)
            const Text("Category", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  selectedColor: activeColor.withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? activeColor : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (selected) {
                    setState(() => _selectedCategory = selected ? cat : null);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // 4. Date Picker
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text("Date", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}"),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDate(context),
            ),
            const Divider(),

            // 5. Notes
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
              ),
            ),
            const SizedBox(height: 32),

            // 6. Save Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _isLoading ? null : _handleSave,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save Transaction', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeButton(String title, Color color) {
    final isSelected = _selectedType == title;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = title;
          _selectedCategory = null; // Reset kategori saat pindah tab
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }
}