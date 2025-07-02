import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../services/database_helper.dart';

class AddEntryScreen extends StatefulWidget {
  final int initialTabIndex;
  
  const AddEntryScreen({super.key, this.initialTabIndex = 0});

  @override
  State<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends State<AddEntryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final _formKey = GlobalKey<FormState>();

  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  List<Category> _incomeCategories = [];
  List<Category> _expenseCategories = [];

  Category? _selectedIncomeCategory;
  Category? _selectedExpenseCategory;
  DateTime _selectedDate = DateTime.now();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Dashboard and AddEntryScreen now have same tab order
    // Both: 0=Expenses, 1=Income
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTabIndex);
    _loadCategories();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final incomeCategories = await _dbHelper.getCategories(type: 'income', enabledOnly: true);
    final expenseCategories = await _dbHelper.getCategories(type: 'expense', enabledOnly: true);

    setState(() {
      _incomeCategories = incomeCategories.cast<Category>();
      _expenseCategories = expenseCategories.cast<Category>();
      
      if (_incomeCategories.isNotEmpty && _selectedIncomeCategory == null) {
        _selectedIncomeCategory = _incomeCategories.first;
      }
      if (_expenseCategories.isNotEmpty && _selectedExpenseCategory == null) {
        _selectedExpenseCategory = _expenseCategories.first;
      }
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    final isIncome = _tabController.index == 1; // Tab 0 = Expense, Tab 1 = Income
    final selectedCategory = isIncome ? _selectedIncomeCategory : _selectedExpenseCategory;

    if (selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final transaction = Transaction(
        type: isIncome ? 'income' : 'expense',
        amount: double.parse(_amountController.text), // Parse as double but input is whole number
        categoryId: selectedCategory.id!,
        date: _selectedDate,
        note: _noteController.text.isEmpty ? null : _noteController.text,
      );

      await _dbHelper.insertTransaction(transaction);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${isIncome ? 'Income' : 'Expense'} added successfully!',
            ),
            backgroundColor: isIncome ? Colors.green : Colors.red,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Entry'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.onPrimary,
          unselectedLabelColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
          indicatorColor: Theme.of(context).colorScheme.onPrimary,
          tabs: const [
            Tab(icon: Icon(Icons.trending_down), text: 'Expense'),
            Tab(icon: Icon(Icons.trending_up), text: 'Income'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEntryForm(false), // Expense
          _buildEntryForm(true), // Income
        ],
      ),
    );
  }

  Widget _buildEntryForm(bool isIncome) {
    final categories = isIncome ? _incomeCategories : _expenseCategories;
    final selectedCategory = isIncome ? _selectedIncomeCategory : _selectedExpenseCategory;
    final color = isIncome ? Colors.green : Colors.red;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isIncome ? Icons.trending_up : Icons.trending_down,
                          color: color,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Add ${isIncome ? 'Income' : 'Expense'}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Amount Field
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Amount (whole numbers only)',
                        border: const OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money, color: color),
                        hintText: 'Enter amount without decimals',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an amount';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Please enter a valid whole number';
                        }
                        if (int.parse(value) <= 0) {
                          return 'Amount must be greater than 0';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Category Dropdown
                    DropdownButtonFormField<Category>(
                      value: selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        border: const OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category, color: color),
                      ),
                      items: categories.map((Category category) {
                        return DropdownMenuItem<Category>(
                          value: category,
                          child: Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: Color(category.colorValue),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(category.name),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (Category? newValue) {
                        setState(() {
                          if (isIncome) {
                            _selectedIncomeCategory = newValue;
                          } else {
                            _selectedExpenseCategory = newValue;
                          }
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a category';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Date Picker
                    InkWell(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Date',
                          border: const OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today, color: color),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
                            Icon(Icons.arrow_drop_down, color: color),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Note Field (Optional)
                    TextFormField(
                      controller: _noteController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Note (Optional)',
                        border: const OutlineInputBorder(),
                        prefixIcon: Icon(Icons.note, color: color),
                        hintText: 'Add a note about this transaction...',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Save Button
            ElevatedButton(
              onPressed: _isLoading ? null : _saveTransaction,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Save ${isIncome ? 'Income' : 'Expense'}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            
            // Clear Button
            OutlinedButton(
              onPressed: _isLoading ? null : _clearForm,
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Clear Form',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _clearForm() {
    _amountController.clear();
    _noteController.clear();
    setState(() {
      _selectedDate = DateTime.now();
      if (_incomeCategories.isNotEmpty) {
        _selectedIncomeCategory = _incomeCategories.first;
      }
      if (_expenseCategories.isNotEmpty) {
        _selectedExpenseCategory = _expenseCategories.first;
      }
    });
  }
} 