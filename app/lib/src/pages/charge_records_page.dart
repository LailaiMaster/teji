import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../api.dart';
import '../formatters.dart';
import '../theme/app_style.dart';
import '../utils/dashboard_metrics.dart';
import '../widgets/month_selector.dart';
import '../widgets/panels.dart';
import '../widgets/shell.dart';

class ChargeRecordsPage extends StatefulWidget {
  const ChargeRecordsPage({super.key, required this.api, this.carId});

  final TejiApi api;
  final int? carId;

  @override
  State<ChargeRecordsPage> createState() => _ChargeRecordsPageState();
}

class _ChargeRecordsPageState extends State<ChargeRecordsPage> {
  late Future<List<JsonMap>> _future;
  DateTime _selectedMonth = monthOnly(DateTime.now());

  @override
  void initState() {
    super.initState();
    _future = widget.api.chargingProcesses(limit: 200, carId: widget.carId);
  }

  Future<void> refresh() async {
    setState(
      () => _future = widget.api.chargingProcesses(
        limit: 200,
        carId: widget.carId,
      ),
    );
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return FuturePane<List<JsonMap>>(
      future: _future,
      onRefresh: refresh,
      builder: (context, charges) {
        final monthCharges = rowsInMonth(charges, 'start_date', _selectedMonth);
        return PageShell(
          title: '充电记录',
          subtitle:
              '${DateFormat('yyyy-MM').format(_selectedMonth)} · ${monthCharges.length} 次充电',
          children: [
            MonthSelector(
              month: _selectedMonth,
              availableMonths: dataMonths(
                charges,
                'start_date',
                include: _selectedMonth,
              ),
              onChanged: (month) => setState(() => _selectedMonth = month),
            ),
            const SizedBox(height: 14),
            ChargeSummary(charges: monthCharges),
            const SizedBox(height: 14),
            if (monthCharges.isEmpty)
              const Panel(
                child: Center(
                  child: Text('该月暂无充电记录', style: TextStyle(color: muted)),
                ),
              )
            else
              ...monthCharges.map(
                (charge) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ChargeRecordCard(charge: charge),
                ),
              ),
          ],
        );
      },
    );
  }
}

class ChargeSummary extends StatelessWidget {
  const ChargeSummary({super.key, required this.charges});

  final List<JsonMap> charges;

  @override
  Widget build(BuildContext context) {
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PanelTitle(icon: Icons.bolt, color: amber, title: '月度充电'),
          const SizedBox(height: 16),
          MetricRow(
            items: [
              MetricItem('次数', '${charges.length}', amber),
              MetricItem(
                '充入',
                kwh(sumDouble(charges, 'charge_energy_added')),
                green,
              ),
              MetricItem(
                '耗时',
                minutesShort(sumInt(charges, 'duration_min')),
                text,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ChargeRecordCard extends StatelessWidget {
  const ChargeRecordCard({super.key, required this.charge});

  final JsonMap charge;

  @override
  Widget build(BuildContext context) {
    return Panel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  textValue(charge['location_name'], fallback: '未知地点'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: text,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const DistancePill(text: '慢充'),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            chargeTimeRange(charge),
            style: const TextStyle(color: muted, fontSize: 12),
          ),
          const SizedBox(height: 14),
          MetricRow(
            items: [
              MetricItem('充电量', kwh(charge['charge_energy_added']), green),
              MetricItem('时长', minutesShort(charge['duration_min']), text),
              MetricItem(
                '电池',
                '${percent(charge['start_battery_level'])}→${percent(charge['end_battery_level'])}',
                cyan,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
