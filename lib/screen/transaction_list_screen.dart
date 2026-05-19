import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/transaction_model.dart';
import '../services/finance_service.dart';
import '../widgets/transaction_visual.dart';
import 'transaction_detail_screen.dart';
import 'transaction_form_screen.dart';

class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({super.key});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  TransactionType? filterType;
  bool newestFirst = true;

  List<TransactionModel> get transactions {
    final all = FinanceService.getTransactions();
    final filtered =
        filterType == null ? all : all.where((t) => t.type == filterType).toList();

    filtered.sort(
      (a, b) => newestFirst
          ? b.date.compareTo(a.date)
          : a.date.compareTo(b.date),
    );

    return filtered;
  }

  Future<void> addTransaction() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TransactionFormScreen(),
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> openTransaction(TransactionModel transaction) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TransactionDetailScreen(transactionId: transaction.id),
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> deleteTransaction(TransactionModel transaction) async {
    await FinanceService.deleteTransaction(transaction);

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<TransactionType?>(
                    initialValue: filterType,
                    decoration: const InputDecoration(
                      labelText: 'Type filter',
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('All')),
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
                      setState(() {
                        filterType = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<bool>(
                    initialValue: newestFirst,
                    decoration: const InputDecoration(
                      labelText: 'Sort by date',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: true,
                        child: Text('Newest first'),
                      ),
                      DropdownMenuItem(
                        value: false,
                        child: Text('Oldest first'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }

                      setState(() {
                        newestFirst = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: transactions.isEmpty
                ? const _TransactionsEmptyState()
                : ListView.builder(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(context).padding.bottom + 96),
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final t = transactions[index];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () => openTransaction(t),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                TransactionVisual(
                                  transaction: t,
                                  size: 50,
                                  borderRadius: 18,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        t.title,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${t.category} • ${dateFormat.format(t.date)}',
                                        style: const TextStyle(
                                          color: Color(0xFFAAB2D5),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${t.isIncome ? '+' : '-'}€${t.amount.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        color: t.isIncome
                                            ? const Color(0xFF14F1FF)
                                            : const Color(0xFFFF2BD6),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.chevron_right_rounded,
                                          color: Color(0xFF6E79A6),
                                        ),
                                        IconButton(
                                          visualDensity: VisualDensity.compact,
                                          icon: const Icon(
                                            Icons.delete_outline_rounded,
                                          ),
                                          onPressed: () => deleteTransaction(t),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addTransaction,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _TransactionsEmptyState extends StatelessWidget {
  const _TransactionsEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF171B31),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0x22FFFFFF)),
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                color: Color(0xFF14F1FF),
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No transactions yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Start by adding your first income or expense entry.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFFAAB2D5)),
            ),
          ],
        ),
      ),
    );
  }
}
