import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../models/account_model.dart';
import '../models/transaction_model.dart';
import '../services/finance_service.dart';
import 'accounts_screen.dart';
import 'exchange_rate_screen.dart';
import 'statistics_screen.dart';
import 'transaction_form_screen.dart';
import 'transaction_list_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _showCashFlowPanel = true;
  final nameController = TextEditingController();
  final balanceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _seedPreviewData();
  }

  @override
  void dispose() {
    nameController.dispose();
    balanceController.dispose();
    super.dispose();
  }

  Future<void> _seedPreviewData() async {
    final didSeed = await FinanceService.seedPreviewDataIfNeeded();

    if (didSeed && mounted) {
      setState(() {});
    }
  }

  Future<void> setOverviewAccount(String? accountId) async {
    await FinanceService.setSelectedAccountId(accountId);

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> openScreen(Widget screen) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> clearPreviewData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear preview data'),
          content: const Text(
            'Remove the demo accounts and sample transactions that were added for previewing the app?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final removedAnything = await FinanceService.clearPreviewData();

    if (!mounted) {
      return;
    }

    Navigator.of(context).maybePop();
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          removedAnything
              ? 'Preview data removed.'
              : 'There was no preview data to remove.',
        ),
      ),
    );
  }

  Future<void> showQuickActions() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          decoration: const BoxDecoration(
            color: Color(0xFF111426),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Quick Add',
                  style: TextStyle(
                    color: Color(0xFFF4F7FF),
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'What would you like to record?',
                  style: TextStyle(color: Color(0xFFAAB2D5), fontSize: 13),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _QuickAddCard(
                        icon: Icons.arrow_downward_rounded,
                        label: 'Income',
                        color: const Color(0xFF14F1FF),
                        onTap: () async {
                          Navigator.pop(context);
                          await openScreen(const TransactionFormScreen(
                            initialType: TransactionType.income,
                          ));
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickAddCard(
                        icon: Icons.arrow_upward_rounded,
                        label: 'Expense',
                        color: const Color(0xFFFF2BD6),
                        onTap: () async {
                          Navigator.pop(context);
                          await openScreen(const TransactionFormScreen(
                            initialType: TransactionType.expense,
                          ));
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _QuickActionTile(
                  icon: Icons.account_balance_wallet_rounded,
                  title: 'New Account',
                  subtitle: 'Create a new account to track separately',
                  onTap: () async {
                    Navigator.pop(context);
                    await addAccountDialog();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> addPreviewData() async {
    final added = await FinanceService.seedPreviewDataIfNeeded();

    if (!mounted) {
      return;
    }

    Navigator.of(context).maybePop();
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          added
              ? 'Preview accounts and transactions added.'
              : 'Preview data is already available.',
        ),
      ),
    );
  }

  Future<void> addAccountDialog() async {
    nameController.clear();
    balanceController.clear();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New Account'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Account name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: balanceController,
                decoration: const InputDecoration(labelText: 'Starting balance'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final balance = double.tryParse(balanceController.text) ?? 0;
                if (name.isEmpty) return;
                await FinanceService.addAccount(
                  AccountModel(
                    id: const Uuid().v4(),
                    name: name,
                    balance: balance,
                  ),
                );
                if (!mounted) return;
                Navigator.of(this.context).pop();
                setState(() {});
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> editAccountDialog(AccountModel account) async {
    nameController.text = account.name;
    balanceController.text = account.balance.toStringAsFixed(2);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Account Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Account name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: balanceController,
                decoration: const InputDecoration(labelText: 'Available balance'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final balance = double.tryParse(balanceController.text) ?? 0;

                if (name.isEmpty) {
                  return;
                }

                await FinanceService.updateAccount(
                  AccountModel(
                    id: account.id,
                    name: name,
                    balance: balance,
                  ),
                );

                if (!mounted) return;
                Navigator.of(this.context).pop();
                setState(() {});
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> deleteAccount(AccountModel account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete account'),
          content: Text(
            'Delete ${account.name}? Linked transactions will stay, but they will no longer belong to this account.',
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

    await FinanceService.deleteAccount(account);

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounts = FinanceService.getAccounts();
    final selectedAccount = FinanceService.selectedAccount;
    final selectedAccountId = FinanceService.selectedAccountId;
    final income = selectedAccount == null
        ? FinanceService.totalIncome
        : FinanceService.incomeForAccount(selectedAccount.id);
    final expenses = selectedAccount == null
        ? FinanceService.totalExpenses
        : FinanceService.expensesForAccount(selectedAccount.id);
    final balance =
        selectedAccount?.balance ?? FinanceService.totalAccountBalance;
    final monthLabel = DateFormat('MMMM yyyy').format(DateTime.now());
    final screenTitle = selectedAccount?.name ?? 'All Accounts';
    final recentTransactions = selectedAccount == null
        ? FinanceService.getTransactions().take(3).toList()
        : FinanceService.getTransactions()
            .where((transaction) => transaction.accountId == selectedAccount.id)
            .take(3)
            .toList();
    final expenseTransactions = selectedAccount == null
        ? FinanceService.getTransactions()
            .where((transaction) => transaction.isExpense)
            .toList()
        : FinanceService.getTransactions()
            .where((transaction) =>
                transaction.accountId == selectedAccount.id &&
                transaction.isExpense)
            .toList();
    final expenseBreakdown = _buildExpenseBreakdown(expenseTransactions);
    final accountChartData = selectedAccount == null
        ? const <_AccountBalancePoint>[]
        : _buildAccountBalanceHistory(
            FinanceService.getTransactions()
                .where((transaction) => transaction.accountId == selectedAccount.id)
                .toList(),
            selectedAccount.balance,
          );
    final accountPeriodChange = accountChartData.length < 2
        ? 0.0
        : accountChartData.last.value - accountChartData.first.value;

    return Scaffold(
      bottomNavigationBar: BottomAppBar(
        color: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Container(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1020),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0x2214F1FF)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x3314F1FF),
                  blurRadius: 18,
                  offset: Offset(0, 0),
                ),
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 24,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: _BottomNavItem(
                    icon: Icons.home_rounded,
                    label: 'Home',
                    isActive: true,
                    onTap: () {},
                  ),
                ),
                Expanded(
                  child: _BottomNavItem(
                    icon: Icons.receipt_long_rounded,
                    label: 'Transact.',
                    onTap: () => openScreen(const TransactionListScreen()),
                  ),
                ),
                GestureDetector(
                  onTap: showQuickActions,
                  child: Container(
                    width: 50,
                    height: 50,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF2BD6),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF2BD6).withValues(alpha: 0.45),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
                Expanded(
                  child: _BottomNavItem(
                    icon: Icons.account_balance_wallet_rounded,
                    label: 'Accounts',
                    onTap: () => openScreen(const AccountsScreen()),
                  ),
                ),
                Expanded(
                  child: _BottomNavItem(
                    icon: Icons.query_stats_rounded,
                    label: 'Stats',
                    onTap: () => openScreen(const StatisticsScreen()),
                  ),
                ),
                Expanded(
                  child: _BottomNavItem(
                    icon: Icons.currency_exchange_rounded,
                    label: 'Rates',
                    onTap: () => openScreen(const ExchangeRateScreen()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              screenTitle,
              style: const TextStyle(
                color: Color(0xFFF4F7FF),
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            if (selectedAccount == null)
              const Text(
                'All accounts overview',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFFAAB2D5),
                  fontWeight: FontWeight.w500,
                ),
              )
            else
              const Text(
                'Focused account overview',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF14F1FF),
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 104),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF161A30),
                  Color(0xFF23143B),
                  Color(0xFF0F2548),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: const Color(0xFF14F1FF).withValues(alpha: 0.35),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x5514F1FF),
                  blurRadius: 22,
                  offset: Offset(0, 0),
                ),
                BoxShadow(
                  color: Color(0x33FF2BD6),
                  blurRadius: 28,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      monthLabel,
                      style: const TextStyle(
                        color: Color(0xFFAAB2D5),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (selectedAccount == null
                                ? const Color(0xFFFFC857)
                                : const Color(0xFF14F1FF))
                            .withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: (selectedAccount == null
                                  ? const Color(0xFFFFC857)
                                  : const Color(0xFF14F1FF))
                              .withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        selectedAccount == null ? 'ALL ACCOUNTS' : 'FOCUSED',
                        style: TextStyle(
                          color: selectedAccount == null
                              ? const Color(0xFFFFC857)
                              : const Color(0xFF14F1FF),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.9,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'Current balance',
                  style: TextStyle(
                    color: Color(0xFFAAB2D5),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '€${balance.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Color(0xFFF4F7FF),
                    fontSize: 38,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF14F1FF).withValues(alpha: 0.0),
                        const Color(0xFF14F1FF).withValues(alpha: 0.3),
                        const Color(0xFFFF2BD6).withValues(alpha: 0.3),
                        const Color(0xFFFF2BD6).withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF14F1FF).withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF14F1FF).withValues(alpha: 0.22),
                        ),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Color(0xFF14F1FF),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Viewing',
                            style: TextStyle(
                              color: Color(0xFFAAB2D5),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.8,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Choose the account shown on this dashboard',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Color(0xFF7D88B5),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  key: ValueKey(selectedAccountId),
                  initialValue: selectedAccountId,
                  dropdownColor: const Color(0xFF1A1F38),
                  style: const TextStyle(
                    color: Color(0xFFF4F7FF),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF14F1FF),
                  ),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.folder_open_rounded,
                      color: Color(0xFF14F1FF),
                      size: 20,
                    ),
                    filled: true,
                    fillColor: const Color(0xFF14F1FF).withValues(alpha: 0.08),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(
                        color: const Color(0xFF14F1FF).withValues(alpha: 0.24),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(
                        color: const Color(0xFF14F1FF).withValues(alpha: 0.55),
                        width: 1.5,
                      ),
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All Accounts'),
                    ),
                    ...accounts.map((account) {
                      return DropdownMenuItem<String?>(
                        value: account.id,
                        child: Text(account.name),
                      );
                    }),
                  ],
                  selectedItemBuilder: (context) {
                    return [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'All Accounts',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      ...accounts.map(
                        (account) => Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            account.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ];
                  },
                  onChanged: (value) => setOverviewAccount(value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _CashFlowCard(
            income: income,
            expenses: expenses,
            selectedAccountName: selectedAccount?.name,
            accountCount: accounts.length,
            recentTransactions: recentTransactions,
            showCashFlowPanel: _showCashFlowPanel,
            onPanelChanged: (showCashFlow) {
              setState(() {
                _showCashFlowPanel = showCashFlow;
              });
            },
            onOpenTransactions: () => openScreen(const TransactionListScreen()),
          ),
          if (selectedAccount != null) ...[
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${selectedAccount.name} Activity',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Two-month balance trend and quick account actions.',
                                style: TextStyle(color: Color(0xFFAAB2D5)),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0x22FFC857),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${accountPeriodChange >= 0 ? '+' : '-'}€${accountPeriodChange.abs().toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Color(0xFFFFC857),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 220,
                      child: LineChart(
                        LineChartData(
                          minX: accountChartData.first.x,
                          maxX: accountChartData.last.x,
                          minY: _minAccountChartValue(accountChartData),
                          maxY: _maxAccountChartValue(accountChartData),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (value) {
                              return FlLine(
                                color: const Color(0x18FFFFFF),
                                strokeWidth: 0.8,
                              );
                            },
                          ),
                          titlesData: FlTitlesData(
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 44,
                                interval: _accountChartInterval(accountChartData),
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    _compactChartCurrency(value),
                                    style: const TextStyle(
                                      color: Color(0xFFAAB2D5),
                                      fontSize: 10,
                                    ),
                                  );
                                },
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 15,
                                getTitlesWidget: (value, meta) {
                                  final label =
                                      _labelForAccountXAxis(value, accountChartData);
                                  if (label == null) {
                                    return const SizedBox.shrink();
                                  }

                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      label,
                                      style: const TextStyle(
                                        color: Color(0xFFAAB2D5),
                                        fontSize: 10,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          lineTouchData: LineTouchData(
                            handleBuiltInTouches: true,
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipColor: (_) => const Color(0xFF111426),
                              tooltipBorder: const BorderSide(
                                color: Color(0x22FFFFFF),
                              ),
                              getTooltipItems: (touchedSpots) {
                                return touchedSpots.map((spot) {
                                  return LineTooltipItem(
                                    '€${spot.y.toStringAsFixed(2)}',
                                    const TextStyle(
                                      color: Color(0xFFF4F7FF),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  );
                                }).toList();
                              },
                            ),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              isCurved: true,
                              color: const Color(0xFFFFC857),
                              barWidth: 4,
                              isStrokeCapRound: true,
                              dotData: FlDotData(
                                show: true,
                                checkToShowDot: (spot, barData) {
                                  final x = spot.x.roundToDouble();
                                  return x ==
                                          accountChartData.first.x
                                              .roundToDouble() ||
                                      x ==
                                          accountChartData.last.x
                                              .roundToDouble();
                                },
                                getDotPainter: (spot, percent, bar, index) {
                                  return FlDotCirclePainter(
                                    radius: 3.6,
                                    color: const Color(0xFFFFC857),
                                    strokeWidth: 2,
                                    strokeColor: const Color(0xFF111426),
                                  );
                                },
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    const Color(0xFFFFC857).withValues(alpha: 0.24),
                                    const Color(0xFFFFC857).withValues(alpha: 0.02),
                                  ],
                                ),
                              ),
                              spots: [
                                for (final point in accountChartData)
                                  FlSpot(point.x, point.value),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Expense Categories',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Where this account is spending the most.',
                      style: TextStyle(color: Color(0xFFAAB2D5)),
                    ),
                    const SizedBox(height: 16),
                    if (expenseBreakdown.isEmpty)
                      const _RecentEmptyState()
                    else
                      Row(
                        children: [
                          Expanded(
                            flex: 5,
                            child: SizedBox(
                              height: 190,
                              child: PieChart(
                                PieChartData(
                                  centerSpaceRadius: 42,
                                  sectionsSpace: 2,
                                  startDegreeOffset: -90,
                                  sections: [
                                    for (final item in expenseBreakdown)
                                      PieChartSectionData(
                                        color: item.color,
                                        value: item.amount,
                                        radius: 22,
                                        title: '',
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 6,
                            child: Column(
                              children: [
                                for (final item in expenseBreakdown)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: _CategoryLegendTile(item: item),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
          if (selectedAccount == null) ...[
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Expense Categories',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'A quick look at where your money is going.',
                      style: TextStyle(color: Color(0xFFAAB2D5)),
                    ),
                    const SizedBox(height: 16),
                    if (expenseBreakdown.isEmpty)
                      const _RecentEmptyState()
                    else
                      Row(
                        children: [
                          Expanded(
                            flex: 5,
                            child: SizedBox(
                              height: 190,
                              child: PieChart(
                                PieChartData(
                                  centerSpaceRadius: 42,
                                  sectionsSpace: 2,
                                  startDegreeOffset: -90,
                                  sections: [
                                    for (final item in expenseBreakdown)
                                      PieChartSectionData(
                                        color: item.color,
                                        value: item.amount,
                                        radius: 22,
                                        title: '',
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 6,
                            child: Column(
                              children: [
                                for (final item in expenseBreakdown)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: _CategoryLegendTile(item: item),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<_CategoryExpense> _buildExpenseBreakdown(
    List<TransactionModel> transactions,
  ) {
    if (transactions.isEmpty) {
      return [];
    }

    final totals = <String, double>{};
    for (final transaction in transactions) {
      totals.update(
        transaction.category,
        (value) => value + transaction.amount,
        ifAbsent: () => transaction.amount,
      );
    }

    final totalSpent =
        totals.values.fold<double>(0, (sum, value) => sum + value);
    final colors = [
      const Color(0xFF14F1FF),
      const Color(0xFFFF2BD6),
      const Color(0xFFFFB347),
      const Color(0xFF8BFF5C),
      const Color(0xFF9D7CFF),
      const Color(0xFFFF5B7F),
    ];

    final sortedEntries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return [
      for (var i = 0; i < sortedEntries.length; i++)
        _CategoryExpense(
          category: sortedEntries[i].key,
          amount: sortedEntries[i].value,
          percentage:
              totalSpent == 0 ? 0 : (sortedEntries[i].value / totalSpent) * 100,
          color: colors[i % colors.length],
        ),
    ];
  }

  List<_AccountBalancePoint> _buildAccountBalanceHistory(
    List<TransactionModel> transactions,
    double currentBalance,
  ) {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 60));
    final normalizedStartDate = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );
    final normalizedNow = DateTime(now.year, now.month, now.day);

    final visibleTransactions = transactions
        .where((transaction) => !transaction.date.isBefore(normalizedStartDate))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    double openingBalance = currentBalance;
    for (final transaction in visibleTransactions) {
      if (transaction.isIncome) {
        openingBalance -= transaction.amount;
      } else {
        openingBalance += transaction.amount;
      }
    }

    final points = <_AccountBalancePoint>[
      _AccountBalancePoint(
        x: 0,
        date: normalizedStartDate,
        value: openingBalance,
      ),
    ];
    var runningBalance = openingBalance;

    for (final transaction in visibleTransactions) {
      if (transaction.isIncome) {
        runningBalance += transaction.amount;
      } else {
        runningBalance -= transaction.amount;
      }

      final normalizedTransactionDate = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );
      points.add(
        _AccountBalancePoint(
          x: normalizedTransactionDate
              .difference(normalizedStartDate)
              .inDays
              .toDouble(),
          date: normalizedTransactionDate,
          value: runningBalance,
        ),
      );
    }

    final lastPoint = points.last;
    final endX = normalizedNow.difference(normalizedStartDate).inDays.toDouble();
    if (lastPoint.x != endX) {
      points.add(
        _AccountBalancePoint(
          x: endX,
          date: normalizedNow,
          value: runningBalance,
        ),
      );
    }

    return points;
  }

  String? _labelForAccountXAxis(
    double value,
    List<_AccountBalancePoint> chartData,
  ) {
    final rounded = value.roundToDouble();
    final firstX = chartData.first.x.roundToDouble();
    final lastX = chartData.last.x.roundToDouble();
    final midX = ((firstX + lastX) / 2).roundToDouble();

    if (rounded != firstX && rounded != midX && rounded != lastX) {
      return null;
    }

    final match = chartData.firstWhere(
      (point) => point.x.roundToDouble() == rounded,
      orElse: () => chartData.last,
    );

    return DateFormat('dd MMM').format(match.date);
  }

  double _minAccountChartValue(List<_AccountBalancePoint> chartData) {
    final minValue = chartData
        .map((point) => point.value)
        .reduce((current, next) => current < next ? current : next);
    final maxValue = chartData
        .map((point) => point.value)
        .reduce((current, next) => current > next ? current : next);
    final range = (maxValue - minValue).abs();

    if (range == 0) {
      return minValue <= 50 ? 0 : minValue - 50;
    }

    return minValue - (range * 0.15);
  }

  double _maxAccountChartValue(List<_AccountBalancePoint> chartData) {
    final minValue = chartData
        .map((point) => point.value)
        .reduce((current, next) => current < next ? current : next);
    final maxValue = chartData
        .map((point) => point.value)
        .reduce((current, next) => current > next ? current : next);
    final range = (maxValue - minValue).abs();

    if (range == 0) {
      return maxValue + 50;
    }

    return maxValue + (range * 0.15);
  }

  double _accountChartInterval(List<_AccountBalancePoint> chartData) {
    final minValue = _minAccountChartValue(chartData);
    final maxValue = _maxAccountChartValue(chartData);
    final range = (maxValue - minValue).abs();

    if (range <= 100) {
      return 25;
    }

    final rawStep = range / 4;
    final magnitude = math.pow(10, (math.log(rawStep) / math.ln10).floor());
    final normalized = rawStep / magnitude;

    double step;
    if (normalized <= 1) {
      step = 1;
    } else if (normalized <= 2) {
      step = 2;
    } else if (normalized <= 2.5) {
      step = 2.5;
    } else if (normalized <= 5) {
      step = 5;
    } else {
      step = 10;
    }

    return step * magnitude;
  }

  String _compactChartCurrency(double value) {
    final absolute = value.abs();

    if (absolute >= 10000) {
      return '€${(value / 1000).toStringAsFixed(0)}k';
    }

    if (absolute >= 1000) {
      return '€${(value / 1000).toStringAsFixed(1)}k';
    }

    return '€${value.toStringAsFixed(0)}';
  }
}

class _AccountBalancePoint {
  final double x;
  final DateTime date;
  final double value;

  const _AccountBalancePoint({
    required this.x,
    required this.date,
    required this.value,
  });
}

class _CashFlowCard extends StatelessWidget {
  final double income;
  final double expenses;
  final String? selectedAccountName;
  final int accountCount;
  final List<TransactionModel> recentTransactions;
  final bool showCashFlowPanel;
  final ValueChanged<bool> onPanelChanged;
  final VoidCallback onOpenTransactions;

  const _CashFlowCard({
    required this.income,
    required this.expenses,
    required this.selectedAccountName,
    required this.accountCount,
    required this.recentTransactions,
    required this.showCashFlowPanel,
    required this.onPanelChanged,
    required this.onOpenTransactions,
  });

  @override
  Widget build(BuildContext context) {
    final largestValue = [income, expenses, 1.0].reduce(
      (current, next) => current > next ? current : next,
    );
    final incomeRatio = income / largestValue;
    final expenseRatio = expenses / largestValue;
    final net = income - expenses;
    final isPositive = net >= 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        showCashFlowPanel ? 'Cash Flow' : 'Recent Transactions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        showCashFlowPanel
                            ? (selectedAccountName == null
                                ? 'Income and expenses across all accounts.'
                                : 'Income and expenses for $selectedAccountName.')
                            : (selectedAccountName == null
                                ? 'Latest entries across all accounts.'
                                : 'Latest entries for $selectedAccountName.'),
                        style: const TextStyle(color: Color(0xFFAAB2D5)),
                      ),
                    ],
                  ),
                ),
                if (showCashFlowPanel)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isPositive
                          ? const Color(0x2214F1FF)
                          : const Color(0x22FF2BD6),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${isPositive ? '+' : '-'}€${net.abs().toStringAsFixed(2)}',
                      style: TextStyle(
                        color: isPositive
                            ? const Color(0xFF14F1FF)
                            : const Color(0xFFFF2BD6),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            _PanelSwitch(
              showCashFlowPanel: showCashFlowPanel,
              onPanelChanged: onPanelChanged,
            ),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: showCashFlowPanel
                  ? _CashFlowPanel(
                      key: const ValueKey('cash-flow-panel'),
                      income: income,
                      expenses: expenses,
                      incomeRatio: incomeRatio,
                      expenseRatio: expenseRatio,
                      selectedAccountName: selectedAccountName,
                      accountCount: accountCount,
                    )
                  : _RecentTransactionsPanel(
                      key: const ValueKey('recent-transactions'),
                      recentTransactions: recentTransactions,
                      selectedAccountName: selectedAccountName,
                      onOpenTransactions: onOpenTransactions,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CashFlowPanel extends StatelessWidget {
  final double income;
  final double expenses;
  final double incomeRatio;
  final double expenseRatio;
  final String? selectedAccountName;
  final int accountCount;

  const _CashFlowPanel({
    super.key,
    required this.income,
    required this.expenses,
    required this.incomeRatio,
    required this.expenseRatio,
    required this.selectedAccountName,
    required this.accountCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _FlowMetricTile(
          label: 'Income',
          amount: income,
          ratio: incomeRatio,
          color: const Color(0xFF138A6D),
          trackColor: const Color(0x1A138A6D),
          icon: Icons.south_west_rounded,
        ),
        const SizedBox(height: 14),
        _FlowMetricTile(
          label: 'Expenses',
          amount: expenses,
          ratio: expenseRatio,
          color: const Color(0xFFD64550),
          trackColor: const Color(0x1AD64550),
          icon: Icons.north_east_rounded,
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _InsightTile(
                label: 'Focus',
                value: selectedAccountName ?? 'All accounts',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _InsightTile(
                label: 'Tracked',
                value: '$accountCount accounts',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PanelSwitch extends StatelessWidget {
  final bool showCashFlowPanel;
  final ValueChanged<bool> onPanelChanged;

  const _PanelSwitch({
    required this.showCashFlowPanel,
    required this.onPanelChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1020),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x22FFFFFF)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SwitchOption(
              label: 'Recent',
              isSelected: !showCashFlowPanel,
              onTap: () => onPanelChanged(false),
            ),
          ),
          Expanded(
            child: _SwitchOption(
              label: 'Cash Flow',
              isSelected: showCashFlowPanel,
              onTap: () => onPanelChanged(true),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwitchOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SwitchOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1D2442) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x4414F1FF),
                    blurRadius: 14,
                    offset: Offset(0, 0),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected
                ? const Color(0xFF14F1FF)
                : const Color(0xFFAAB2D5),
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _QuickAddCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAddCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF171B31),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0x22FFFFFF)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFF0E1326),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: const Color(0xFF14F1FF)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFFF4F7FF),
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFFAAB2D5),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF6E79A6)),
          ],
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    this.isActive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor =
        isActive ? const Color(0xFFFFB347) : const Color(0xFF8C96BE);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: activeColor, size: 19),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: activeColor,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightTile extends StatelessWidget {
  final String label;
  final String value;

  const _InsightTile({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF171B31),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x22FFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFAAB2D5),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFF4F7FF),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FlowMetricTile extends StatelessWidget {
  final String label;
  final double amount;
  final double ratio;
  final Color color;
  final Color trackColor;
  final IconData icon;

  const _FlowMetricTile({
    required this.label,
    required this.amount,
    required this.ratio,
    required this.color,
    required this.trackColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF171B31),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x22FFFFFF)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF0E1326),
                borderRadius: BorderRadius.circular(14),
              ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: Color(0xFFF4F7FF),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '€${amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 9,
                    value: ratio.clamp(0.0, 1.0),
                    backgroundColor: trackColor,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentTransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback onTap;

  const _RecentTransactionTile({
    required this.transaction,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF171B31),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0x22FFFFFF)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF0E1326),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                transaction.isIncome
                    ? Icons.south_west_rounded
                    : Icons.north_east_rounded,
                color: transaction.isIncome
                    ? const Color(0xFF14F1FF)
                    : const Color(0xFFFF2BD6),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.title,
                    style: const TextStyle(
                      color: Color(0xFFF4F7FF),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    transaction.category,
                    style: const TextStyle(
                      color: Color(0xFFAAB2D5),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${transaction.isIncome ? '+' : '-'}€${transaction.amount.toStringAsFixed(2)}',
              style: TextStyle(
                color: transaction.isIncome
                    ? const Color(0xFF14F1FF)
                    : const Color(0xFFFF2BD6),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentTransactionsPanel extends StatelessWidget {
  final List<TransactionModel> recentTransactions;
  final String? selectedAccountName;
  final VoidCallback onOpenTransactions;

  const _RecentTransactionsPanel({
    super.key,
    required this.recentTransactions,
    required this.selectedAccountName,
    required this.onOpenTransactions,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          selectedAccountName == null
              ? 'Latest entries across all accounts.'
              : 'Latest entries for $selectedAccountName.',
          style: const TextStyle(color: Color(0xFFAAB2D5)),
        ),
        const SizedBox(height: 16),
        if (recentTransactions.isEmpty)
          const _RecentEmptyState()
        else
          ...recentTransactions.map((transaction) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RecentTransactionTile(
                transaction: transaction,
                onTap: onOpenTransactions,
              ),
            );
          }),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: onOpenTransactions,
            child: const Text('See all transactions'),
          ),
        ),
      ],
    );
  }
}

class _RecentEmptyState extends StatelessWidget {
  const _RecentEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF171B31),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x22FFFFFF)),
      ),
      child: const Text(
        'No recent transactions yet.',
        style: TextStyle(color: Color(0xFFAAB2D5)),
      ),
    );
  }
}

class _CategoryExpense {
  final String category;
  final double amount;
  final double percentage;
  final Color color;

  const _CategoryExpense({
    required this.category,
    required this.amount,
    required this.percentage,
    required this.color,
  });
}

class _CategoryLegendTile extends StatelessWidget {
  final _CategoryExpense item;

  const _CategoryLegendTile({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF171B31),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x22FFFFFF)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: item.color,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.category,
                  style: const TextStyle(
                    color: Color(0xFFF4F7FF),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '€${item.amount.toStringAsFixed(2)} • ${item.percentage.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: Color(0xFFAAB2D5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
