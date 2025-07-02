import 'package:flutter/material.dart';
import '../models/category.dart';
import '../services/database_helper.dart';

class CategoryManagerScreen extends StatefulWidget {
  const CategoryManagerScreen({super.key});

  @override
  State<CategoryManagerScreen> createState() => _CategoryManagerScreenState();
}

class _CategoryManagerScreenState extends State<CategoryManagerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<Category> _incomeCategories = [];
  List<Category> _expenseCategories = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCategories();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final incomeCategories = await _dbHelper.getCategories(type: 'income');
    final expenseCategories = await _dbHelper.getCategories(type: 'expense');

    setState(() {
      _incomeCategories = incomeCategories.cast<Category>();
      _expenseCategories = expenseCategories.cast<Category>();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Categories'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'restore_defaults') {
                _restoreDefaultCategories();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'restore_defaults',
                child: ListTile(
                  leading: Icon(Icons.restore),
                  title: Text('Restore Default Categories'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.onPrimary,
          unselectedLabelColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
          indicatorColor: Theme.of(context).colorScheme.onPrimary,
          tabs: const [
            Tab(icon: Icon(Icons.trending_up), text: 'Income'),
            Tab(icon: Icon(Icons.trending_down), text: 'Expense'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCategoryList(_incomeCategories, 'income'),
          _buildCategoryList(_expenseCategories, 'expense'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCategoryDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryList(List<Category> categories, String type) {
    if (categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.category_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No ${type} categories yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to add a new category',
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8.0),
          color: category.isEnabled ? null : Colors.grey[100],
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: category.isEnabled 
                    ? Color(category.colorValue) 
                    : Color(category.colorValue).withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                type == 'income' ? Icons.trending_up : Icons.trending_down,
                color: Colors.white,
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    category.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: category.isEnabled ? null : Colors.grey[600],
                      decoration: category.isEnabled ? null : TextDecoration.lineThrough,
                    ),
                  ),
                ),
                if (!category.isEnabled)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'DISABLED',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[800],
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Text(
              '${type.toUpperCase()} Category',
              style: TextStyle(
                color: category.isEnabled 
                    ? (type == 'income' ? Colors.green : Colors.red)
                    : Colors.grey[500],
                fontSize: 12,
              ),
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditCategoryDialog(category);
                } else if (value == 'toggle') {
                  _toggleCategoryStatus(category);
                } else if (value == 'delete') {
                  _showDeleteConfirmationDialog(category);
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit),
                    title: Text('Edit'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'toggle',
                  child: ListTile(
                    leading: Icon(
                      category.isEnabled ? Icons.visibility_off : Icons.visibility,
                      color: category.isEnabled ? Colors.orange : Colors.green,
                    ),
                    title: Text(
                      category.isEnabled ? 'Disable' : 'Enable',
                      style: TextStyle(
                        color: category.isEnabled ? Colors.orange : Colors.green,
                      ),
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                if (!category.isEnabled) // Only show delete for disabled categories
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete, color: Colors.red),
                      title: Text('Delete', style: TextStyle(color: Colors.red)),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddCategoryDialog() {
    final isIncome = _tabController.index == 0;
    final type = isIncome ? 'income' : 'expense';
    
    showDialog(
      context: context,
      builder: (context) => CategoryDialog(
        type: type,
        onSave: (category) async {
          await _dbHelper.insertCategory(category);
          _loadCategories();
        },
      ),
    );
  }

  void _showEditCategoryDialog(Category category) {
    showDialog(
      context: context,
      builder: (context) => CategoryDialog(
        category: category,
        type: category.type,
        onSave: (updatedCategory) async {
          await _dbHelper.updateCategory(updatedCategory);
          _loadCategories();
        },
      ),
    );
  }

  void _toggleCategoryStatus(Category category) async {
    try {
      final newStatus = !category.isEnabled;
      await _dbHelper.toggleCategoryStatus(category.id!, newStatus);
      _loadCategories();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${category.name} ${newStatus ? 'enabled' : 'disabled'} successfully',
            ),
            backgroundColor: newStatus ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating category: $e')),
        );
      }
    }
  }

  void _showDeleteConfirmationDialog(Category category) async {
    // Check if category has transactions
    final hasTransactions = await _dbHelper.hasCategoryTransactions(category.id!);
    
    if (hasTransactions) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cannot Delete Category'),
          content: Text(
            'Cannot delete "${category.name}" because it has existing transactions.\n\n'
            'You can disable it instead to hide it from the dropdown menus.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _toggleCategoryStatus(category);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.orange),
              child: const Text('Disable Instead'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text(
          'Are you sure you want to delete "${category.name}"?\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await _dbHelper.deleteCategory(category.id!);
                _loadCategories();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${category.name} deleted successfully'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting category: $e')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _restoreDefaultCategories() async {
    try {
      await _dbHelper.recreateDefaultCategories();
      _loadCategories();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Default categories restored successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error restoring categories: $e')),
        );
      }
    }
  }
}

class CategoryDialog extends StatefulWidget {
  final Category? category;
  final String type;
  final Function(Category) onSave;

  const CategoryDialog({
    super.key,
    this.category,
    required this.type,
    required this.onSave,
  });

  @override
  State<CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<CategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  
  int _selectedColorValue = 0xFF2196F3;
  bool _isLoading = false;

  final List<int> _colorOptions = [
    0xFF2196F3, // Blue
    0xFF4CAF50, // Green
    0xFFFF5722, // Red
    0xFFFF9800, // Orange
    0xFF9C27B0, // Purple
    0xFFF44336, // Deep Red
    0xFF607D8B, // Blue Grey
    0xFF795548, // Brown
    0xFFE91E63, // Pink
    0xFF3F51B5, // Indigo
    0xFF009688, // Teal
    0xFFFFEB3B, // Yellow
  ];

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
      _selectedColorValue = widget.category!.colorValue;
    } else {
      // Set default color based on type
      _selectedColorValue = widget.type == 'income' ? 0xFF4CAF50 : 0xFFFF5722;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.category != null;
    final color = widget.type == 'income' ? Colors.green : Colors.red;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Category' : 'Add Category'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Category Name',
                border: const OutlineInputBorder(),
                prefixIcon: Icon(Icons.category, color: color),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a category name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Choose Color:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _colorOptions.map((colorValue) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColorValue = colorValue;
                    });
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(colorValue),
                      shape: BoxShape.circle,
                      border: _selectedColorValue == colorValue
                          ? Border.all(color: Colors.black, width: 3)
                          : null,
                    ),
                    child: _selectedColorValue == colorValue
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveCategory,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(isEditing ? 'Update' : 'Add'),
        ),
      ],
    );
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final category = Category(
        id: widget.category?.id,
        name: _nameController.text.trim(),
        type: widget.type,
        colorValue: _selectedColorValue,
        isEnabled: widget.category?.isEnabled ?? true, // Keep existing status or default to enabled
      );

      widget.onSave(category);
      Navigator.of(context).pop();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${category.name} ${widget.category != null ? 'updated' : 'added'} successfully!',
            ),
            backgroundColor: widget.type == 'income' ? Colors.green : Colors.red,
          ),
        );
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
} 