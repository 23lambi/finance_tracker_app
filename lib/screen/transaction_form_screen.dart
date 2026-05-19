import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../models/account_model.dart';
import '../models/transaction_model.dart';
import '../services/finance_service.dart';

class TransactionFormScreen extends StatefulWidget {
  final TransactionModel? initialTransaction;
  final TransactionType? initialType;

  const TransactionFormScreen({
    super.key,
    this.initialTransaction,
    this.initialType,
  });

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final amountController = TextEditingController();
  final customCategoryController = TextEditingController();

  late TransactionType selectedType;
  String selectedCategory = 'Food';
  DateTime selectedDate = DateTime.now();
  String? selectedAccountId;
  String? selectedPhotoPath;

  final imagePicker = ImagePicker();

  final categories = [
    'Food',
    'Transport',
    'Bills',
    'Shopping',
    'Salary',
    'Entertainment',
    'Health',
    'Other',
  ];

  bool get isEditing => widget.initialTransaction != null;
  bool get isOtherCategorySelected => selectedCategory == 'Other';

  @override
  void initState() {
    super.initState();
    selectedType = widget.initialTransaction?.type ??
        widget.initialType ??
        TransactionType.expense;
    final transaction = widget.initialTransaction;

    if (transaction != null) {
      titleController.text = transaction.title;
      amountController.text = transaction.amount.toStringAsFixed(2);
      selectedType = transaction.type;
      selectedDate = transaction.date;
      selectedAccountId = transaction.accountId;
      selectedPhotoPath = transaction.photoPath;

      if (categories.contains(transaction.category)) {
        selectedCategory = transaction.category;
      } else {
        selectedCategory = 'Other';
        customCategoryController.text = transaction.category;
      }
    }
  }

  Future<void> pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (date != null) {
      setState(() {
        selectedDate = date;
      });
    }
  }

  Future<void> pickImage(ImageSource source) async {
    final image = await imagePicker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1600,
    );

    if (image == null) {
      return;
    }

    setState(() {
      selectedPhotoPath = image.path;
    });
  }

  void removeImage() {
    setState(() {
      selectedPhotoPath = null;
    });
  }

  Future<void> saveTransaction() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    final transaction = TransactionModel(
      id: widget.initialTransaction?.id ?? const Uuid().v4(),
      title: titleController.text.trim(),
      amount: double.parse(amountController.text),
      type: selectedType,
      category: isOtherCategorySelected
          ? customCategoryController.text.trim()
          : selectedCategory,
      date: selectedDate,
      photoPath: selectedPhotoPath,
      accountId: selectedAccountId,
    );

    if (isEditing) {
      await FinanceService.updateTransaction(transaction);
    } else {
      await FinanceService.addTransaction(transaction);
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    amountController.dispose();
    customCategoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accounts = FinanceService.getAccounts();

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Transaction' : 'Add Transaction'),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
        child: Form(
          key: formKey,
          child: ListView(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEditing ? 'Update Entry' : 'New Entry',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Add an income or expense and connect it to an account if needed.',
                        style: TextStyle(color: Color(0xFFAAB2D5)),
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter a title';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: amountController,
                        decoration: const InputDecoration(
                          labelText: 'Amount',
                          prefixText: '€ ',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          final amount = double.tryParse(value ?? '');

                          if (amount == null || amount <= 0) {
                            return 'Enter valid amount';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<TransactionType>(
                        initialValue: selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Type',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: TransactionType.income,
                            child: Text('Income'),
                          ),
                          DropdownMenuItem(
                            value: TransactionType.expense,
                            child: Text('Expense'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }

                          setState(() {
                            selectedType = value;
                            selectedCategory =
                                value == TransactionType.income ? 'Salary' : 'Food';
                            customCategoryController.clear();
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                        ),
                        items: categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }

                          setState(() {
                            selectedCategory = value;
                            if (value != 'Other') {
                              customCategoryController.clear();
                            }
                          });
                        },
                      ),
                      if (isOtherCategorySelected) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: customCategoryController,
                          decoration: const InputDecoration(
                            labelText: 'Custom category',
                            hintText: 'Write the category name',
                          ),
                          validator: (value) {
                            if (!isOtherCategorySelected) {
                              return null;
                            }

                            if (value == null || value.trim().isEmpty) {
                              return 'Enter the custom category';
                            }

                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String?>(
                        initialValue: selectedAccountId,
                        decoration: const InputDecoration(
                          labelText: 'Account',
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('No account'),
                          ),
                          ...accounts.map((AccountModel account) {
                            return DropdownMenuItem<String?>(
                              value: account.id,
                              child: Text(account.name),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedAccountId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      Card(
                        color: const Color(0xFF171B31),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          title: const Text('Date'),
                          subtitle: Text(
                            '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                          ),
                          trailing: const Icon(Icons.calendar_month_rounded),
                          onTap: pickDate,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF171B31),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0x22FFFFFF)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Photo',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Optional receipt or transaction image.',
                              style: TextStyle(color: Color(0xFFAAB2D5)),
                            ),
                            const SizedBox(height: 14),
                            if (selectedPhotoPath != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: Image.file(
                                  File(selectedPhotoPath!),
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 180,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0E1326),
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      child: const Text(
                                        'Unable to load image preview',
                                        style: TextStyle(
                                          color: Color(0xFFAAB2D5),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              )
                            else
                              Container(
                                height: 180,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF161A30),
                                      Color(0xFF23143B),
                                      Color(0xFF0F2548),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _categoryPreviewIcon(selectedCategory),
                                      color: Colors.white,
                                      size: 40,
                                    ),
                                    const SizedBox(height: 10),
                                    const Text(
                                      'Default category visual',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                FilledButton.icon(
                                  onPressed: () => pickImage(ImageSource.camera),
                                  icon: const Icon(Icons.camera_alt_rounded),
                                  label: const Text('Camera'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () => pickImage(ImageSource.gallery),
                                  icon: const Icon(Icons.photo_library_rounded),
                                  label: const Text('Gallery'),
                                ),
                                if (selectedPhotoPath != null)
                                  TextButton.icon(
                                    onPressed: removeImage,
                                    icon: const Icon(Icons.delete_outline_rounded),
                                    label: const Text('Remove'),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: saveTransaction,
                icon: const Icon(Icons.save_rounded),
                label: Text(
                  isEditing ? 'Update Transaction' : 'Save Transaction',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _categoryPreviewIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant_rounded;
      case 'transport':
        return Icons.directions_car_filled_rounded;
      case 'bills':
        return Icons.receipt_long_rounded;
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'salary':
        return Icons.payments_rounded;
      case 'entertainment':
        return Icons.movie_rounded;
      case 'health':
        return Icons.favorite_rounded;
      default:
        return selectedType == TransactionType.income
            ? Icons.south_west_rounded
            : Icons.north_east_rounded;
    }
  }
}
