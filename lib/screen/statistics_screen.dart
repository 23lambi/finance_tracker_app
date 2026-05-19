import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/account_model.dart';
import '../models/transaction_model.dart';
import '../services/finance_service.dart';
import 'exchange_rate_screen.dart';

enum _StatsSeriesFilter {
  both,
  incomeOnly,
  expensesOnly,
}

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  String? selectedAccountId;
  _StatsSeriesFilter selectedSeries = _StatsSeriesFilter.both;

  @override
  void initState() {
    super.initState();
    selectedAccountId = FinanceService.selectedAccountId;
  }

  @override
  Widget build(BuildContext context) {
    final accounts = FinanceService.getAccounts();
    final selectedAccount = selectedAccountId == null
        ? null
        : FinanceService.accountBox.get(selectedAccountId);
    final transactions = _transactionsForSelection(selectedAccountId);
    final income = transactions
        .where((transaction) => transaction.isIncome)
        .fold<double>(0, (sum, transaction) => sum + transaction.amount);
    final expenses = transactions
        .where((transaction) => transaction.isExpense)
        .fold<double>(0, (sum, transaction) => sum + transaction.amount);
    final balance =
        selectedAccount?.balance ?? FinanceService.totalAccountBalance;
    final monthlyStats = _buildMonthlyStats(transactions);
    final yearlyStats = _buildYearlyStats(transactions);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
        children: [
          Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ExchangeRateScreen(),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF14F1FF).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.currency_exchange_rounded,
                        color: Color(0xFF14F1FF),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'EUR Exchange Rates',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Live EUR → USD & GBP rates with 30-day chart.',
                            style: TextStyle(
                              color: Color(0xFFAAB2D5),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF6E79A6),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Statistics Filter',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    selectedAccount == null
                        ? 'Showing data for all accounts.'
                        : 'Showing data for ${selectedAccount.name}.',
                    style: const TextStyle(
                      color: Color(0xFFAAB2D5),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String?>(
                    initialValue: selectedAccountId,
                    decoration: const InputDecoration(
                      labelText: 'Account scope',
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All accounts'),
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
                  DropdownButtonFormField<_StatsSeriesFilter>(
                    initialValue: selectedSeries,
                    decoration: const InputDecoration(
                      labelText: 'Chart display',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: _StatsSeriesFilter.both,
                        child: Text('Income and expenses'),
                      ),
                      DropdownMenuItem(
                        value: _StatsSeriesFilter.incomeOnly,
                        child: Text('Income only'),
                      ),
                      DropdownMenuItem(
                        value: _StatsSeriesFilter.expensesOnly,
                        child: Text('Expenses only'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }

                      setState(() {
                        selectedSeries = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  label: 'Income',
                  value: '€${income.toStringAsFixed(2)}',
                  accent: const Color(0xFFFFC857),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  label: 'Expenses',
                  value: '€${expenses.toStringAsFixed(2)}',
                  accent: const Color(0xFFFF8A3D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SummaryCard(
            label: 'Balance',
            value: '€${balance.toStringAsFixed(2)}',
            accent:
                balance >= 0 ? const Color(0xFFFFC857) : const Color(0xFFFF8A3D),
          ),
          const SizedBox(height: 18),
          _ChartSection(
            title: 'Monthly Overview',
            subtitle: 'Income and expenses for the last 6 months',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (selectedSeries != _StatsSeriesFilter.expensesOnly)
                      const _ChartLegend(
                        color: Color(0xFFFFC857),
                        label: 'Income',
                      ),
                    if (selectedSeries != _StatsSeriesFilter.expensesOnly &&
                        selectedSeries != _StatsSeriesFilter.incomeOnly)
                      const SizedBox(width: 14),
                    if (selectedSeries != _StatsSeriesFilter.incomeOnly)
                      const _ChartLegend(
                        color: Color(0xFFFF8A3D),
                        label: 'Expenses',
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 260,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: _maxChartValue(monthlyStats),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: const Color(0x22FFFFFF),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      borderData: FlBorderData(show: false),
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
                            reservedSize: 42,
                            interval: _yAxisInterval(monthlyStats),
                            getTitlesWidget: (value, meta) {
                              return Text(
                                _compactCurrency(value),
                                style: const TextStyle(
                                  color: Color(0xFFAAB2D5),
                                  fontSize: 11,
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= monthlyStats.length) {
                                return const SizedBox.shrink();
                              }

                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  monthlyStats[index].label,
                                  style: const TextStyle(
                                    color: Color(0xFFAAB2D5),
                                    fontSize: 11,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups: [
                        for (var i = 0; i < monthlyStats.length; i++)
                          BarChartGroupData(
                            x: i,
                            barsSpace: 6,
                            barRods: [
                              if (selectedSeries !=
                                  _StatsSeriesFilter.expensesOnly)
                                BarChartRodData(
                                  toY: monthlyStats[i].income,
                                  color: const Color(0xFFFFC857),
                                  width: 10,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              if (selectedSeries !=
                                  _StatsSeriesFilter.incomeOnly)
                                BarChartRodData(
                                  toY: monthlyStats[i].expense,
                                  color: const Color(0xFFFF8A3D),
                                  width: 10,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _ChartSection(
            title: 'Yearly Totals',
            subtitle: 'Year-by-year comparison with clearer totals',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (selectedSeries != _StatsSeriesFilter.expensesOnly)
                      const _ChartLegend(
                        color: Color(0xFFFFC857),
                        label: 'Income',
                      ),
                    if (selectedSeries != _StatsSeriesFilter.expensesOnly &&
                        selectedSeries != _StatsSeriesFilter.incomeOnly)
                      const SizedBox(width: 14),
                    if (selectedSeries != _StatsSeriesFilter.incomeOnly)
                      const _ChartLegend(
                        color: Color(0xFFFF8A3D),
                        label: 'Expenses',
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 240,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: _maxChartValue(yearlyStats),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: const Color(0x22FFFFFF),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      borderData: FlBorderData(show: false),
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
                            reservedSize: 42,
                            interval: _yAxisInterval(yearlyStats),
                            getTitlesWidget: (value, meta) {
                              return Text(
                                _compactCurrency(value),
                                style: const TextStyle(
                                  color: Color(0xFFAAB2D5),
                                  fontSize: 11,
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= yearlyStats.length) {
                                return const SizedBox.shrink();
                              }

                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  yearlyStats[index].label,
                                  style: const TextStyle(
                                    color: Color(0xFFAAB2D5),
                                    fontSize: 11,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups: [
                        for (var i = 0; i < yearlyStats.length; i++)
                          BarChartGroupData(
                            x: i,
                            barsSpace: 6,
                            barRods: [
                              if (selectedSeries !=
                                  _StatsSeriesFilter.expensesOnly)
                                BarChartRodData(
                                  toY: yearlyStats[i].income,
                                  color: const Color(0xFFFFC857),
                                  width: 14,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              if (selectedSeries !=
                                  _StatsSeriesFilter.incomeOnly)
                                BarChartRodData(
                                  toY: yearlyStats[i].expense,
                                  color: const Color(0xFFFF8A3D),
                                  width: 14,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<_PeriodStat> _buildMonthlyStats(List<TransactionModel> transactions) {
    final now = DateTime.now();
    final stats = <_PeriodStat>[];

    for (var i = 5; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final monthTransactions = transactions.where((transaction) {
        return transaction.date.year == date.year &&
            transaction.date.month == date.month;
      });

      double income = 0;
      double expense = 0;

      for (final transaction in monthTransactions) {
        if (transaction.isIncome) {
          income += transaction.amount;
        } else {
          expense += transaction.amount;
        }
      }

      stats.add(
        _PeriodStat(
          label: DateFormat('MMM').format(date),
          income: income,
          expense: expense,
        ),
      );
    }

    return stats;
  }

  List<_PeriodStat> _buildYearlyStats(List<TransactionModel> transactions) {
    if (transactions.isEmpty) {
      return [
        _PeriodStat(
          label: DateTime.now().year.toString(),
          income: 0,
          expense: 0,
        ),
      ];
    }

    final years = transactions
        .map((transaction) => transaction.date.year)
        .toSet()
        .toList()
      ..sort();

    return years.map((year) {
      final yearTransactions = transactions.where(
        (transaction) => transaction.date.year == year,
      );

      double income = 0;
      double expense = 0;

      for (final transaction in yearTransactions) {
        if (transaction.isIncome) {
          income += transaction.amount;
        } else {
          expense += transaction.amount;
        }
      }

      return _PeriodStat(
        label: year.toString(),
        income: income,
        expense: expense,
      );
    }).toList();
  }

  double _maxChartValue(List<_PeriodStat> stats) {
    final values = [
      for (final stat in stats) stat.income,
      for (final stat in stats) stat.expense,
    ];

    final max = values.fold<double>(0, (current, value) {
      return value > current ? value : current;
    });

    return max == 0 ? 100 : max * 1.2;
  }

  double _yAxisInterval(List<_PeriodStat> stats) {
    final max = _maxChartValue(stats);
    return max <= 100 ? 25 : max / 4;
  }

  String _compactCurrency(double value) {
    if (value >= 1000) {
      return '€${(value / 1000).toStringAsFixed(1)}k';
    }

    return '€${value.toStringAsFixed(0)}';
  }

  List<TransactionModel> _transactionsForSelection(String? accountId) {
    if (accountId == null) {
      return FinanceService.getTransactions();
    }

    return FinanceService.getTransactions()
        .where((transaction) => transaction.accountId == accountId)
        .toList();
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFFAAB2D5),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                color: accent,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  final Color color;
  final String label;

  const _ChartLegend({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFAAB2D5),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ChartSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _ChartSection({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(color: Color(0xFFAAB2D5)),
            ),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}

class _PeriodStat {
  final String label;
  final double income;
  final double expense;

  const _PeriodStat({
    required this.label,
    required this.income,
    required this.expense,
  });
}
