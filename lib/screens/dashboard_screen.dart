import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../services/database_helper.dart';
import '../config/app_config.dart';
import 'add_entry_screen.dart';
import 'category_manager_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  late TabController _tabController;
  
  String _selectedMonth = 'All';
  String _selectedYear = 'All';
  
  List<Transaction> _allTransactions = [];
  List<Category> _categories = [];
  
  // Overview data
  List<Transaction> _overviewTransactions = [];
  String _currencySymbol = '\$';

  // Month and year options
  final List<String> _months = [
    'All',
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  List<String> _years = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      // Update the FAB when tab changes
      setState(() {});
    });
    _initializeFilters();
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initializeFilters() {
    final now = DateTime.now();
    
    // Set default to current month and year
    _selectedMonth = _months[now.month]; // Current month
    _selectedYear = now.year.toString(); // Current year
    
    // Generate year options (current year - 5 to current year + 1)
    _years = ['All'];
    for (int year = now.year - 5; year <= now.year + 1; year++) {
      _years.add(year.toString());
    }
  }

  Future<void> _loadData() async {
    await _loadCategories();
    await _loadTransactions();
    await _loadOverviewData();
    await _loadCurrencySettings();
  }

  Future<void> _loadCategories() async {
    // Load all categories (including disabled) to show correct names in transaction lists
    final categories = await _dbHelper.getCategories();
    setState(() {
      _categories = categories.cast<Category>();
    });
  }

  Future<void> _loadTransactions() async {
    DateTime? startDate;
    DateTime? endDate;
    
    final now = DateTime.now();
    
    // Handle year filtering
    int? filterYear;
    if (_selectedYear != 'All') {
      filterYear = int.parse(_selectedYear);
    }
    
    // Handle month filtering
    int? filterMonth;
    if (_selectedMonth != 'All') {
      filterMonth = _months.indexOf(_selectedMonth);
    }
    
    // Set date range based on filters
    if (filterYear != null && filterMonth != null) {
      // Specific month and year
      startDate = DateTime(filterYear, filterMonth, 1);
      endDate = DateTime(filterYear, filterMonth + 1, 0, 23, 59, 59);
    } else if (filterYear != null && filterMonth == null) {
      // Entire year
      startDate = DateTime(filterYear, 1, 1);
      endDate = DateTime(filterYear, 12, 31, 23, 59, 59);
    } else if (filterYear == null && filterMonth != null) {
      // Specific month of current year
      final currentYear = now.year;
      startDate = DateTime(currentYear, filterMonth, 1);
      endDate = DateTime(currentYear, filterMonth + 1, 0, 23, 59, 59);
    }
    // If both are 'All', startDate and endDate remain null (show all data)

    final transactions = await _dbHelper.getTransactions(
      startDate: startDate,
      endDate: endDate,
    );

    setState(() {
      _allTransactions = transactions.cast<Transaction>();
    });
  }

  Future<void> _loadOverviewData() async {
    // Load all transactions for overview (no filtering)
    final transactions = await _dbHelper.getTransactions();
    setState(() {
      _overviewTransactions = transactions.cast<Transaction>();
    });
  }

  Future<void> _loadCurrencySettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currencySymbol = prefs.getString('currency_symbol') ?? '\$';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MoneyTrail'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.category),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CategoryManagerScreen(),
                ),
              );
              _loadData();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.onPrimary,
          unselectedLabelColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
          indicatorColor: Theme.of(context).colorScheme.onPrimary,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.trending_down), text: 'Expenses'),
            Tab(icon: Icon(Icons.trending_up), text: 'Income'),
            Tab(icon: Icon(Icons.settings), text: 'Settings'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Shared filter section (only for Expenses and Income tabs)
          if (_tabController.index == 1 || _tabController.index == 2)
            _buildCompactFilterSection(),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildExpenseTab(),
                _buildIncomeTab(),
                _buildSettingsTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildCompactFilterSection() {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            const Icon(Icons.filter_list, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Filter:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedMonth,
                      decoration: const InputDecoration(
                        labelText: 'Month',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: _months.map((String month) {
                        return DropdownMenuItem<String>(
                          value: month,
                          child: Text(
                            month,
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedMonth = newValue;
                          });
                          _loadData();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedYear,
                      decoration: const InputDecoration(
                        labelText: 'Year',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: _years.map((String year) {
                        return DropdownMenuItem<String>(
                          value: year,
                          child: Text(
                            year,
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedYear = newValue;
                          });
                          _loadData();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseTab() {
    final expenseTransactions = _allTransactions.where((t) => t.type == 'expense').toList();
    final expenseCategoryTotals = _calculateCategoryTotals(expenseTransactions);
    
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (expenseTransactions.isNotEmpty) ...[
              _buildSmallPieChart('Expenses by Category', expenseCategoryTotals, Colors.red),
              const SizedBox(height: 20),
              _buildTransactionsList(expenseTransactions, 'Expense', Colors.red),
            ] else
              _buildEmptyState('No expenses found', Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeTab() {
    final incomeTransactions = _allTransactions.where((t) => t.type == 'income').toList();
    final incomeCategoryTotals = _calculateCategoryTotals(incomeTransactions);
    
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (incomeTransactions.isNotEmpty) ...[
              _buildSmallPieChart('Income by Category', incomeCategoryTotals, Colors.green),
              const SizedBox(height: 20),
              _buildTransactionsList(incomeTransactions, 'Income', Colors.green),
            ] else
              _buildEmptyState('No income found', Colors.green),
          ],
        ),
      ),
    );
  }

  Map<String, double> _calculateCategoryTotals(List<Transaction> transactions) {
    Map<String, double> categoryTotals = {};
    
    for (final transaction in transactions) {
      final category = _categories.firstWhere(
        (cat) => cat.id == transaction.categoryId,
        orElse: () => Category(name: 'Unknown', type: transaction.type),
      );
      
      categoryTotals[category.name] = 
          (categoryTotals[category.name] ?? 0) + transaction.amount;
    }
    
    return categoryTotals;
  }

  Widget _buildSmallPieChart(String title, Map<String, double> data, Color baseColor) {
    if (data.isEmpty) return const SizedBox.shrink();

    final sortedData = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24), // Increased padding above pie chart
            SizedBox(
              height: 150, // Smaller chart
              child: PieChart(
                PieChartData(
                  sections: _buildPieChartSections(sortedData, baseColor),
                  sectionsSpace: 2,
                  centerSpaceRadius: 30, // Smaller center
                ),
              ),
            ),
            const SizedBox(height: 20), // Increased padding above legend
            _buildCompactLegend(sortedData, baseColor),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsList(List<Transaction> transactions, String type, Color color) {
    // Sort transactions by date in descending order (latest first)
    transactions.sort((a, b) => b.date.compareTo(a.date));
    final total = transactions.fold(0.0, (sum, t) => sum + t.amount);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$type Transactions',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Total: ${NumberFormat.currency(symbol: _currencySymbol, decimalDigits: 0).format(total)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transactions.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final transaction = transactions[index];
                final category = _categories.firstWhere(
                  (cat) => cat.id == transaction.categoryId,
                  orElse: () => Category(name: 'Unknown', type: transaction.type),
                );
                
                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(category.colorValue),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      type == 'Income' ? Icons.trending_up : Icons.trending_down,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    category.name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(DateFormat('MMM dd, yyyy').format(transaction.date)),
                      if (transaction.note != null && transaction.note!.isNotEmpty)
                        Text(
                          transaction.note!,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                    ],
                  ),
                  trailing: Text(
                    NumberFormat.currency(symbol: _currencySymbol, decimalDigits: 0).format(transaction.amount),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.pie_chart_outline,
                size: 64,
                color: color.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Text(
                _getNoDataMessage(),
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getNoDataMessage() {
    if (_selectedMonth == 'All' && _selectedYear == 'All') {
      return 'Tap the + button to add your first transaction';
    } else {
      return 'No transactions found for ${_getFilterDisplayText().replaceAll('(', '').replaceAll(')', '')}\nTry selecting different filters or add new transactions';
    }
  }

  String _getFilterDisplayText() {
    if (_selectedMonth == 'All' && _selectedYear == 'All') {
      return '(All Time)';
    } else if (_selectedMonth == 'All' && _selectedYear != 'All') {
      return '($_selectedYear)';
    } else if (_selectedMonth != 'All' && _selectedYear == 'All') {
      return '($_selectedMonth ${DateTime.now().year})';
    } else {
      return '($_selectedMonth $_selectedYear)';
    }
  }

  Widget? _buildFloatingActionButton() {
    // Only show FAB for Expenses and Income tabs
    if (_tabController.index == 1 || _tabController.index == 2) {
      final isExpenseTab = _tabController.index == 1;
      final color = isExpenseTab ? Colors.red : Colors.green;
      final icon = isExpenseTab ? Icons.remove : Icons.add;
      final label = isExpenseTab ? 'Add Expense' : 'Add Income';

      return FloatingActionButton.extended(
        onPressed: () async {
          // Convert dashboard tab index to AddEntryScreen tab index
          // Dashboard: 1=Expenses (0 in AddEntry), 2=Income (1 in AddEntry)
          final addEntryTabIndex = _tabController.index == 1 ? 0 : 1;
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddEntryScreen(initialTabIndex: addEntryTabIndex),
            ),
          );
          _loadData();
        },
        backgroundColor: color,
        foregroundColor: Colors.white,
        icon: Icon(icon),
        label: Text(label),
      );
    }
    return null; // No FAB for Overview and Settings tabs
  }

  List<PieChartSectionData> _buildPieChartSections(
    List<MapEntry<String, double>> data, 
    Color baseColor
  ) {
    final total = data.fold(0.0, (sum, entry) => sum + entry.value);
    
    return data.asMap().entries.map((entry) {
      final index = entry.key;
      final dataEntry = entry.value;
      final percentage = (dataEntry.value / total * 100);
      
      return PieChartSectionData(
        color: _generateColor(baseColor, index, data.length),
        value: dataEntry.value,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 60, // Smaller radius
        titleStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Color _generateColor(Color baseColor, int index, int total) {
    final hue = HSLColor.fromColor(baseColor).hue;
    final saturation = 0.7;
    final lightness = 0.5 + (index / total) * 0.3;
    
    return HSLColor.fromAHSL(1.0, hue + (index * 30), saturation, lightness).toColor();
  }

  Widget _buildCompactLegend(List<MapEntry<String, double>> data, Color baseColor) {
    // Show only top 4 categories to keep it compact
    final displayData = data.take(4).toList();
    
    return Padding(
      padding: const EdgeInsets.only(top: 8.0), // Add top padding to the legend
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: displayData.asMap().entries.map((entry) {
        final index = entry.key;
        final dataEntry = entry.value;
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _generateColor(baseColor, index, data.length).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _generateColor(baseColor, index, data.length),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _generateColor(baseColor, index, data.length),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                dataEntry.key,
                style: const TextStyle(fontSize: 10),
              ),
            ],
          ),
        );
      }).toList(),
      ),
    );
  }

  Widget _buildOverviewTab() {
    final totalIncome = _overviewTransactions
        .where((t) => t.type == 'income')
        .fold(0.0, (sum, t) => sum + t.amount);
    final totalExpense = _overviewTransactions
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);
    final balance = totalIncome - totalExpense;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Message
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'Welcome to ${AppConfig.appName}!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Track your finances with ease',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            
            // Summary Cards
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Total Income',
                    totalIncome,
                    Colors.green,
                    Icons.trending_up,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryCard(
                    'Total Expense',
                    totalExpense,
                    Colors.red,
                    Icons.trending_down,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryCard(
                    'Balance',
                    balance,
                    balance >= 0 ? Colors.green : Colors.red,
                    balance >= 0 ? Icons.account_balance_wallet : Icons.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // 12-Month Chart
            _buildMonthlyChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, double amount, Color color, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
                          Text(
                NumberFormat.currency(symbol: _currencySymbol, decimalDigits: 0).format(amount),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyChart() {
    final monthlyData = _calculateMonthlyData();
    
    if (monthlyData.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.bar_chart,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                const Text(
                  'No data for chart',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Add some transactions to see the monthly overview',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Calculate maximum value from all data points
    double maxValue = 0;
    for (final data in monthlyData) {
      final income = data['income'] as double;
      final expense = data['expense'] as double;
      if (income > maxValue) maxValue = income;
      if (expense > maxValue) maxValue = expense;
    }
    
    // Add padding to the top - smart padding based on the value range
    double chartMaxY;
    if (maxValue <= 1000) {
      chartMaxY = maxValue + 200; // Add 200 for small amounts
    } else if (maxValue <= 10000) {
      chartMaxY = maxValue + 2000; // Add 2K for medium amounts
    } else if (maxValue <= 100000) {
      chartMaxY = maxValue + 20000; // Add 20K for larger amounts
    } else {
      chartMaxY = maxValue * 1.2; // Add 20% padding for very large amounts
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Last 12 Months Overview',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  maxY: chartMaxY, // Set custom maximum Y value with padding
                  gridData: FlGridData(show: true, drawVerticalLine: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            NumberFormat.compact().format(value),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= monthlyData.length) return const Text('');
                          return Text(
                            monthlyData[index]['month'],
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  barGroups: monthlyData.asMap().entries.map((entry) {
                    final index = entry.key;
                    final data = entry.value;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: data['income'],
                          color: Colors.green,
                          width: 12,
                          borderRadius: BorderRadius.zero,
                        ),
                        BarChartRodData(
                          toY: data['expense'],
                          color: Colors.red,
                          width: 12,
                          borderRadius: BorderRadius.zero,
                        ),
                      ],
                      barsSpace: 4,
                    );
                  }).toList(),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (group) => Colors.blueGrey.withOpacity(0.8),
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final isIncome = rodIndex == 0;
                        final type = isIncome ? 'Income' : 'Expense';
                        final month = monthlyData[groupIndex]['month'];
                        return BarTooltipItem(
                          '$type\n$month\n${NumberFormat.currency(symbol: _currencySymbol, decimalDigits: 0).format(rod.toY)}',
                          const TextStyle(color: Colors.white, fontSize: 12),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 16,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 4),
                    const Text('Income', style: TextStyle(fontSize: 12)),
                  ],
                ),
                const SizedBox(width: 20),
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 16,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 4),
                    const Text('Expense', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _calculateMonthlyData() {
    final now = DateTime.now();
    final monthlyData = <Map<String, dynamic>>[];
    
    // Generate last 12 months
    for (int i = 11; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthStart = DateTime(month.year, month.month, 1);
      final monthEnd = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
      
      final monthTransactions = _overviewTransactions.where((t) =>
        t.date.isAfter(monthStart.subtract(const Duration(days: 1))) &&
        t.date.isBefore(monthEnd.add(const Duration(days: 1)))
      ).toList();
      
      final income = monthTransactions
          .where((t) => t.type == 'income')
          .fold(0.0, (sum, t) => sum + t.amount);
      final expense = monthTransactions
          .where((t) => t.type == 'expense')
          .fold(0.0, (sum, t) => sum + t.amount);
      
      monthlyData.add({
        'month': DateFormat('MMM').format(month),
        'income': income,
        'expense': expense,
      });
    }
    
    return monthlyData;
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Currency Settings
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.attach_money, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 8),
                      const Text(
                        'Currency Settings',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _currencySymbol,
                    decoration: const InputDecoration(
                      labelText: 'Currency Symbol',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.monetization_on),
                    ),
                    items: const [
                      DropdownMenuItem(value: '\$', child: Text('\$ - US Dollar')),
                      DropdownMenuItem(value: '€', child: Text('€ - Euro')),
                      DropdownMenuItem(value: '£', child: Text('£ - British Pound')),
                      DropdownMenuItem(value: '¥', child: Text('¥ - Japanese Yen')),
                      DropdownMenuItem(value: '₹', child: Text('₹ - Indian Rupee')),
                      DropdownMenuItem(value: '₦', child: Text('₦ - Nigerian Naira')),
                      DropdownMenuItem(value: 'R', child: Text('R - South African Rand')),
                      DropdownMenuItem(value: '¢', child: Text('¢ - Cents')),
                      DropdownMenuItem(value: 'Rs', child: Text('Rs - Pakistan')),
                    ],
                    onChanged: (String? newValue) async {
                      if (newValue != null) {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString('currency_symbol', newValue);
                        setState(() {
                          _currencySymbol = newValue;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // App Info Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 8),
                      const Text(
                        'App Information',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // App Version
                  _buildInfoRow(Icons.app_registration, 'App Version', AppConfig.appVersion),
                  const SizedBox(height: 12),
                  
                  // Developer Name
                  _buildInfoRow(Icons.person, 'Developer', AppConfig.developerName),
                  const SizedBox(height: 12),
                  
                  // Email
                  InkWell(
                    onTap: () => _launchEmail(),
                    child: _buildInfoRow(Icons.email, 'Email', AppConfig.developerEmail, isClickable: true),
                  ),
                  const SizedBox(height: 12),
                  
                  // WhatsApp
                  InkWell(
                    onTap: () => _launchWhatsApp(),
                    child: _buildInfoRow(Icons.chat, 'WhatsApp', AppConfig.whatsappNumber, isClickable: true),
                  ),
                ],
              ),
            ),
          ),
          // Data Management section is hidden as requested
        ],
      ),
    );
  }

  // Helper method to build info rows
  Widget _buildInfoRow(IconData icon, String label, String value, {bool isClickable = false}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: isClickable ? Theme.of(context).primaryColor : Colors.black87,
                  fontWeight: FontWeight.w500,
                  decoration: isClickable ? TextDecoration.underline : null,
                ),
              ),
            ],
          ),
        ),
        if (isClickable)
          Icon(
            Icons.open_in_new,
            size: 16,
            color: Theme.of(context).primaryColor,
          ),
      ],
    );
  }

  // Launch email client
  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: AppConfig.developerEmail,
      query: 'subject=MoneyTrail App Feedback',
    );
    
    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not launch email client. Email: ${AppConfig.developerEmail}'),
              action: SnackBarAction(
                label: 'Copy',
                onPressed: () {
                  // You could implement clipboard copy here if needed
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error launching email: ${AppConfig.developerEmail}')),
        );
      }
    }
  }

  // Launch WhatsApp
  Future<void> _launchWhatsApp() async {
    final String whatsappUrl = 'https://wa.me/${AppConfig.whatsappNumber.replaceAll('+', '')}?text=Hi, I am using MoneyTrail app and would like to get in touch.';
    final Uri whatsappUri = Uri.parse(whatsappUrl);
    
    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not launch WhatsApp. Number: ${AppConfig.whatsappNumber}'),
              action: SnackBarAction(
                label: 'Copy',
                onPressed: () {
                  // You could implement clipboard copy here if needed
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error launching WhatsApp: ${AppConfig.whatsappNumber}')),
        );
      }
    }
  }

  // CSV import/export methods removed since Data Management card is hidden
} 