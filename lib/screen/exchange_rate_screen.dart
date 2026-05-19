import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class ExchangeRateScreen extends StatefulWidget {
  const ExchangeRateScreen({super.key});

  @override
  State<ExchangeRateScreen> createState() => _ExchangeRateScreenState();
}

class _ExchangeRateScreenState extends State<ExchangeRateScreen> {
  bool _loading = true;
  String? _error;
  final Map<String, double> _usdRates = {};
  final Map<String, double> _gbpRates = {};
  final TextEditingController _amountController =
      TextEditingController(text: '100');
  List<String> _sortedDates = [];
  String _selected = 'USD';
  String _fromCurrency = 'EUR';
  String _toCurrency = 'USD';

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchRates();
  }

  Future<void> _fetchRates() async {
    setState(() {
      _loading = true;
      _error = null;
      _usdRates.clear();
      _gbpRates.clear();
    });

    try {
      final end = DateTime.now();
      final start = end.subtract(const Duration(days: 30));
      final fmt = DateFormat('yyyy-MM-dd');
      final url =
          'https://api.frankfurter.app/${fmt.format(start)}..${fmt.format(end)}?from=EUR&to=USD,GBP';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) throw Exception('HTTP ${response.statusCode}');

      final data = json.decode(response.body) as Map<String, dynamic>;
      final rates = data['rates'] as Map<String, dynamic>;

      for (final entry in rates.entries) {
        final dayRates = entry.value as Map<String, dynamic>;
        if (dayRates['USD'] != null) {
          _usdRates[entry.key] = (dayRates['USD'] as num).toDouble();
        }
        if (dayRates['GBP'] != null) {
          _gbpRates[entry.key] = (dayRates['GBP'] as num).toDouble();
        }
      }

      _sortedDates = _usdRates.keys.toList()..sort();

      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  double? _rateFromEur(String currency) {
    if (_sortedDates.isEmpty) {
      return null;
    }

    return _rateFromEurOnDate(currency, _sortedDates.last);
  }

  double? _rateFromEurOnDate(String currency, String date) {
    if (currency == 'EUR') {
      return 1;
    }

    switch (currency) {
      case 'USD':
        return _usdRates[date];
      case 'GBP':
        return _gbpRates[date];
      default:
        return null;
    }
  }

  double? _pairRateOnDate(String fromCurrency, String toCurrency, String date) {
    final fromRate = _rateFromEurOnDate(fromCurrency, date);
    final toRate = _rateFromEurOnDate(toCurrency, date);

    if (fromRate == null || toRate == null || fromRate == 0) {
      return null;
    }

    return toRate / fromRate;
  }

  double? _convertedAmount() {
    final amount = double.tryParse(_amountController.text.trim());
    final fromRate = _rateFromEur(_fromCurrency);
    final toRate = _rateFromEur(_toCurrency);

    if (amount == null || fromRate == null || toRate == null) {
      return null;
    }

    final amountInEur = amount / fromRate;
    return amountInEur * toRate;
  }

  Color _currencyColor(String currency) {
    switch (currency) {
      case 'USD':
        return const Color(0xFF14F1FF);
      case 'GBP':
        return const Color(0xFFFF2BD6);
      case 'EUR':
      default:
        return const Color(0xFFFFC857);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exchange Rates')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 48, color: Color(0xFFAAB2D5)),
            const SizedBox(height: 16),
            const Text(
              'Could not load rates',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Check your internet connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFFAAB2D5)),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _fetchRates,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final rates = _selected == 'USD' ? _usdRates : _gbpRates;
    final dates = _sortedDates.where(rates.containsKey).toList();

    if (dates.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    final spots = [
      for (var i = 0; i < dates.length; i++)
        FlSpot(i.toDouble(), rates[dates[i]]!),
    ];

    final minRate = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxRate = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final range = (maxRate - minRate).abs();
    final pad = range == 0 ? 0.005 : range * 0.2;

    final color = _selected == 'USD'
        ? const Color(0xFF14F1FF)
        : const Color(0xFFFF2BD6);
    final convertedAmount = _convertedAmount();
    final converterColor = _currencyColor(_toCurrency);
    final pairDates = _sortedDates
        .where(
          (date) => _pairRateOnDate(_fromCurrency, _toCurrency, date) != null,
        )
        .toList();
    final latestPairRate = pairDates.isEmpty
        ? null
        : _pairRateOnDate(_fromCurrency, _toCurrency, pairDates.last);
    final firstPairRate = pairDates.isEmpty
        ? null
        : _pairRateOnDate(_fromCurrency, _toCurrency, pairDates.first);
    final pairChange = latestPairRate != null && firstPairRate != null
        ? latestPairRate - firstPairRate
        : null;
    final pairChangePct =
        pairChange != null && firstPairRate != null && firstPairRate != 0
            ? (pairChange / firstPairRate) * 100
            : null;
    final pairIsUp = (pairChange ?? 0) >= 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      children: [
        // Header card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF161A30),
                Color(0xFF23143B),
                Color(0xFF0F2548),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: color.withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(
                color: converterColor.withValues(alpha: 0.18),
                blurRadius: 22,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$_fromCurrency → $_toCurrency',
                style: TextStyle(
                  color: converterColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                latestPairRate == null
                    ? 'Rate unavailable'
                    : '1 $_fromCurrency = ${latestPairRate.toStringAsFixed(4)} $_toCurrency',
                style: const TextStyle(
                  color: Color(0xFFF4F7FF),
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Live rate for the selected pair',
                style: const TextStyle(
                  color: Color(0xFFAAB2D5),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    pairIsUp
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    color: pairIsUp
                        ? const Color(0xFF14F1FF)
                        : const Color(0xFFFF2BD6),
                    size: 16,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      pairChange == null || pairChangePct == null
                          ? 'Not enough rate history for this pair yet'
                          : '${pairIsUp ? '+' : ''}${pairChange.toStringAsFixed(4)} (${pairChangePct.toStringAsFixed(2)}%) last 30 days',
                      style: TextStyle(
                        color: pairIsUp
                          ? const Color(0xFF14F1FF)
                          : const Color(0xFFFF2BD6),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'The chart below stays on the EUR market view.',
                style: TextStyle(
                  color: converterColor.withValues(alpha: 0.72),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Currency Converter',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Convert an amount using the latest live rate.',
                  style: TextStyle(color: Color(0xFFAAB2D5), fontSize: 13),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    hintText: 'Enter an amount',
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        key: ValueKey('from-$_fromCurrency'),
                        initialValue: _fromCurrency,
                        decoration: const InputDecoration(
                          labelText: 'From',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'EUR',
                            child: Text('EUR'),
                          ),
                          DropdownMenuItem(
                            value: 'USD',
                            child: Text('USD'),
                          ),
                          DropdownMenuItem(
                            value: 'GBP',
                            child: Text('GBP'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setState(() {
                            _fromCurrency = value;
                            if (_fromCurrency == _toCurrency) {
                              _toCurrency = _toCurrency == 'EUR' ? 'USD' : 'EUR';
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          final previousFrom = _fromCurrency;
                          _fromCurrency = _toCurrency;
                          _toCurrency = previousFrom;
                        });
                      },
                      icon: const Icon(Icons.swap_horiz_rounded),
                      color: const Color(0xFFAAB2D5),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        key: ValueKey('to-$_toCurrency'),
                        initialValue: _toCurrency,
                        decoration: const InputDecoration(
                          labelText: 'To',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'EUR',
                            child: Text('EUR'),
                          ),
                          DropdownMenuItem(
                            value: 'USD',
                            child: Text('USD'),
                          ),
                          DropdownMenuItem(
                            value: 'GBP',
                            child: Text('GBP'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setState(() {
                            _toCurrency = value;
                            if (_toCurrency == _fromCurrency) {
                              _fromCurrency = _fromCurrency == 'EUR' ? 'USD' : 'EUR';
                            }
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF171B31),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: converterColor.withValues(alpha: 0.30),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$_fromCurrency to $_toCurrency',
                        style: TextStyle(
                          color: converterColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        convertedAmount == null
                            ? 'Enter a valid amount'
                            : '${convertedAmount.toStringAsFixed(2)} $_toCurrency',
                        style: const TextStyle(
                          color: Color(0xFFF4F7FF),
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        convertedAmount == null
                            ? 'Numbers only, for example 125.50'
                            : '${_amountController.text.trim()} $_fromCurrency = ${convertedAmount.toStringAsFixed(2)} $_toCurrency',
                        style: const TextStyle(
                          color: Color(0xFFAAB2D5),
                          fontSize: 12,
                        ),
                      ),
                      if (convertedAmount != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Rate: 1 $_fromCurrency = ${((_rateFromEur(_toCurrency) ?? 1) / (_rateFromEur(_fromCurrency) ?? 1)).toStringAsFixed(4)} $_toCurrency',
                          style: const TextStyle(
                            color: Color(0xFF7D88B5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Currency selector
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: _CurrencyTab(
                    label: 'EUR → USD',
                    selected: _selected == 'USD',
                    color: const Color(0xFF14F1FF),
                    onTap: () => setState(() => _selected = 'USD'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _CurrencyTab(
                    label: 'EUR → GBP',
                    selected: _selected == 'GBP',
                    color: const Color(0xFFFF2BD6),
                    onTap: () => setState(() => _selected = 'GBP'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Chart card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EUR / $_selected — Last 30 Days',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Live rates via Frankfurter (ECB data).',
                  style: TextStyle(color: Color(0xFFAAB2D5), fontSize: 13),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 220,
                  child: LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: (spots.length - 1).toDouble(),
                      minY: minRate - pad,
                      maxY: maxRate + pad,
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
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 52,
                            getTitlesWidget: (value, _) => Text(
                              value.toStringAsFixed(3),
                              style: const TextStyle(
                                  color: Color(0xFFAAB2D5), fontSize: 10),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: (spots.length / 3).ceilToDouble(),
                            getTitlesWidget: (value, _) {
                              final idx = value.toInt();
                              if (idx < 0 || idx >= dates.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  DateFormat('dd/MM')
                                      .format(DateTime.parse(dates[idx])),
                                  style: const TextStyle(
                                      color: Color(0xFFAAB2D5), fontSize: 10),
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
                          getTooltipItems: (touchedSpots) =>
                              touchedSpots.map((spot) {
                            final idx = spot.x.toInt();
                            final label = idx < dates.length
                                ? DateFormat('dd MMM')
                                    .format(DateTime.parse(dates[idx]))
                                : '';
                            return LineTooltipItem(
                              '$label\n${spot.y.toStringAsFixed(4)} $_selected',
                              const TextStyle(
                                color: Color(0xFFF4F7FF),
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: color,
                          barWidth: 2.5,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                color.withValues(alpha: 0.22),
                                color.withValues(alpha: 0.0),
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
      ],
    );
  }
}

class _CurrencyTab extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _CurrencyTab({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.13) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.5)
                : const Color(0x22FFFFFF),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? color : const Color(0xFFAAB2D5),
              fontWeight:
                  selected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
