import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/account_model.dart';
import '../models/transaction_model.dart';
import '../services/finance_service.dart';
import '../widgets/transaction_visual.dart';
import 'transaction_form_screen.dart';

class TransactionDetailScreen extends StatefulWidget {
  final String transactionId;

  const TransactionDetailScreen({
    super.key,
    required this.transactionId,
  });

  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  TransactionModel? get transaction =>
      FinanceService.transactionBox.get(widget.transactionId);

  AccountModel? get account {
    final currentTransaction = transaction;
    if (currentTransaction?.accountId == null) {
      return null;
    }

    return FinanceService.accountBox.get(currentTransaction!.accountId);
  }

  Future<void> editTransaction() async {
    final currentTransaction = transaction;
    if (currentTransaction == null) {
      return;
    }

    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TransactionFormScreen(
          initialTransaction: currentTransaction,
        ),
      ),
    );

    if (updated == true && mounted) {
      setState(() {});
    }
  }

  Future<void> deleteTransaction() async {
    final currentTransaction = transaction;
    if (currentTransaction == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete transaction'),
          content: const Text(
            'This will permanently remove the transaction from your tracker.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await FinanceService.deleteTransaction(currentTransaction);

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTransaction = transaction;

    if (currentTransaction == null) {
      return const Scaffold(
        body: Center(
          child: Text('Transaction not found'),
        ),
      );
    }

    final dateFormat = DateFormat('dd MMMM yyyy');
    final linkedAccount = account;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Details'),
        actions: [
          IconButton(
            onPressed: editTransaction,
            icon: const Icon(Icons.edit_rounded),
          ),
          IconButton(
            onPressed: deleteTransaction,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  TransactionVisual(
                    transaction: currentTransaction,
                    size: 64,
                    borderRadius: 22,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentTransaction.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${currentTransaction.isIncome ? '+' : '-'}€${currentTransaction.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: currentTransaction.isIncome
                                ? const Color(0xFF14F1FF)
                                : const Color(0xFFFF2BD6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _DetailRow(
                    label: 'Type',
                    value: currentTransaction.isIncome ? 'Income' : 'Expense',
                  ),
                  const SizedBox(height: 14),
                  _DetailRow(
                    label: 'Category',
                    value: currentTransaction.category,
                  ),
                  const SizedBox(height: 14),
                  _DetailRow(
                    label: 'Date',
                    value: dateFormat.format(currentTransaction.date),
                  ),
                  const SizedBox(height: 14),
                  _DetailRow(
                    label: 'Account',
                    value: linkedAccount?.name ?? 'No account selected',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: editTransaction,
            icon: const Icon(Icons.edit_rounded),
            label: const Text('Edit Transaction'),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFFAAB2D5),
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
