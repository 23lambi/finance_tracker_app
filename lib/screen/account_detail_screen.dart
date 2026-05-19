import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/account_model.dart';
import '../models/transaction_model.dart';
import '../services/finance_service.dart';

class AccountDetailScreen extends StatefulWidget {
  final String accountId;

  const AccountDetailScreen({
    super.key,
    required this.accountId,
  });

  @override
  State<AccountDetailScreen> createState() => _AccountDetailScreenState();
}

class _AccountDetailScreenState extends State<AccountDetailScreen> {
  final nameController = TextEditingController();
  final balanceController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    balanceController.dispose();
    super.dispose();
  }

  Future<void> editAccount(AccountModel account) async {
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

                if (!mounted) {
                  return;
                }

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
            'Delete ${account.name}? Linked transactions will stay in the app but they will be unassigned.',
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
      Navigator.pop(context, true);
    }
  }

  List<_BalancePoint> _buildBalanceHistory(
    List<TransactionModel> transactions,
    double currentBalance,
  ) {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 60));
    final normalizedNow = DateTime(now.year, now.month, now.day);

    final visible = transactions
        .where((t) => !t.date.isBefore(startDate))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    double openingBalance = currentBalance;
    for (final t in visible) {
      if (t.isIncome) {
        openingBalance -= t.amount;
      } else {
        openingBalance += t.amount;
      }
    }

    final points = <_BalancePoint>[
      _BalancePoint(x: 0, date: startDate, value: openingBalance),
    ];
    var running = openingBalance;

    for (final t in visible) {
      if (t.isIncome) {
        running += t.amount;
      } else {
        running -= t.amount;
      }
      final d = DateTime(t.date.year, t.date.month, t.date.day);
      points.add(_BalancePoint(
        x: d.difference(startDate).inDays.toDouble(),
        date: d,
        value: running,
      ));
    }

    final endX = normalizedNow.difference(startDate).inDays.toDouble();
    if (points.last.x != endX) {
      points.add(_BalancePoint(x: endX, date: normalizedNow, value: running));
    }

    return points;
  }

  double _minY(List<_BalancePoint> points) {
    final min = points.map((p) => p.value).reduce((a, b) => a < b ? a : b);
    final max = points.map((p) => p.value).reduce((a, b) => a > b ? a : b);
    final range = (max - min).abs();
    if (range == 0) return min - 50;
    return min - (range * 0.15);
  }

  double _maxY(List<_BalancePoint> points) {
    final min = points.map((p) => p.value).reduce((a, b) => a < b ? a : b);
    final max = points.map((p) => p.value).reduce((a, b) => a > b ? a : b);
    final range = (max - min).abs();
    if (range == 0) return max + 50;
    return max + (range * 0.15);
  }

  double _interval(List<_BalancePoint> points) {
    final range = (_maxY(points) - _minY(points)).abs();
    if (range <= 100) return 25;
    return range / 4;
  }

  String _compact(double value) {
    if (value.abs() >= 1000) {
      return '€${(value / 1000).toStringAsFixed(1)}k';
    }
    return '€${value.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final account = FinanceService.accountBox.get(widget.accountId);
    final isOverviewAccount =
        FinanceService.selectedAccountId == widget.accountId;

    if (account == null) {
      return const Scaffold(
        body: Center(child: Text('Account not found')),
      );
    }

    final allTransactions = FinanceService.getTransactions()
        .where((t) => t.accountId == widget.accountId)
        .toList();
    final chartPoints =
        _buildBalanceHistory(allTransactions, account.balance);

    return Scaffold(
      appBar: AppBar(
        title: Text(account.name),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
        children: [
          // Balance card
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF171B31),
                  Color(0xFF24153E),
                  Color(0xFF0E203C),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: const Color(0x22FFFFFF)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isOverviewAccount
                      ? 'This account is currently active in the overview.'
                      : 'Select this account in the overview to see its insights.',
                  style: const TextStyle(
                    color: Color(0xFFAAB2D5),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Available Balance',
                  style: TextStyle(color: Color(0xFFAAB2D5), fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  '€${account.balance.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 2-month balance chart
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Balance History',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Two-month balance evolution for this account.',
                    style: TextStyle(color: Color(0xFFAAB2D5)),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 220,
                    child: LineChart(
                      LineChartData(
                        minX: chartPoints.first.x,
                        maxX: chartPoints.last.x,
                        minY: _minY(chartPoints),
                        maxY: _maxY(chartPoints),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (_) => FlLine(
                            color: const Color(0x18FFFFFF),
                            strokeWidth: 0.8,
                          ),
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
                              reservedSize: 48,
                              interval: _interval(chartPoints),
                              getTitlesWidget: (value, _) => Text(
                                _compact(value),
                                style: const TextStyle(
                                  color: Color(0xFFAAB2D5),
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 15,
                              getTitlesWidget: (value, _) {
                                final rounded = value.roundToDouble();
                                final firstX =
                                    chartPoints.first.x.roundToDouble();
                                final lastX =
                                    chartPoints.last.x.roundToDouble();
                                final midX =
                                    ((firstX + lastX) / 2).roundToDouble();
                                if (rounded != firstX &&
                                    rounded != midX &&
                                    rounded != lastX) {
                                  return const SizedBox.shrink();
                                }
                                final match = chartPoints.firstWhere(
                                  (p) => p.x.roundToDouble() == rounded,
                                  orElse: () => chartPoints.last,
                                );
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    DateFormat('dd MMM').format(match.date),
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
                            tooltipBorder:
                                const BorderSide(color: Color(0x22FFFFFF)),
                            getTooltipItems: (spots) => spots
                                .map((s) => LineTooltipItem(
                                      '€${s.y.toStringAsFixed(2)}',
                                      const TextStyle(
                                        color: Color(0xFFF4F7FF),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: chartPoints
                                .map((p) => FlSpot(p.x, p.value))
                                .toList(),
                            isCurved: true,
                            color: const Color(0xFF14F1FF),
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: FlDotData(
                              show: true,
                              checkToShowDot: (spot, _) {
                                final x = spot.x.roundToDouble();
                                return x ==
                                        chartPoints.first.x.roundToDouble() ||
                                    x == chartPoints.last.x.roundToDouble();
                              },
                              getDotPainter: (spot, percent, barData, index) =>
                                  FlDotCirclePainter(
                                radius: 3.6,
                                color: const Color(0xFF14F1FF),
                                strokeWidth: 2,
                                strokeColor: const Color(0xFF111426),
                              ),
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  const Color(0xFF14F1FF).withValues(alpha: 0.22),
                                  const Color(0xFF14F1FF).withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Account settings
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Account Settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Edit this account or remove it from your tracker.',
                    style: TextStyle(color: Color(0xFFAAB2D5)),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => editAccount(account),
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('Edit Account'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => deleteAccount(account),
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Delete Account'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BalancePoint {
  final double x;
  final DateTime date;
  final double value;

  const _BalancePoint({
    required this.x,
    required this.date,
    required this.value,
  });
}
