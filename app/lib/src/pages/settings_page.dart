import 'package:flutter/material.dart';

import '../api.dart';
import '../formatters.dart';
import '../theme/app_style.dart';
import '../widgets/car_selector.dart';
import '../widgets/panels.dart';
import '../widgets/shell.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.apiBaseUrl,
    required this.onSave,
    required this.cars,
    required this.selectedCarId,
    required this.onSelectCar,
  });

  final String apiBaseUrl;
  final Future<void> Function(String value) onSave;
  final List<JsonMap> cars;
  final int? selectedCarId;
  final ValueChanged<int> onSelectCar;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController controller;
  late int? selectedCarId;
  String? message;
  bool checking = false;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.apiBaseUrl);
    selectedCarId = widget.selectedCarId;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> check() async {
    setState(() {
      checking = true;
      message = null;
    });
    try {
      final data = await TejiApi(controller.text).health();
      setState(() => message = '连接正常 ${dateTimeShort(data['checked_at'])}');
    } on Object catch (error) {
      setState(() => message = '连接失败 $error');
    } finally {
      if (mounted) setState(() => checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageShell(
      title: '设置',
      children: [
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PanelTitle(
                icon: Icons.directions_car,
                color: blue,
                title: '车辆',
              ),
              const SizedBox(height: 12),
              CarSelector(
                cars: widget.cars,
                selectedId: selectedCarId,
                onSelected: (id) {
                  setState(() => selectedCarId = id);
                  widget.onSelectCar(id);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PanelTitle(icon: Icons.link, color: cyan, title: '数据服务'),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'API 地址',
                  filled: true,
                  fillColor: bg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: line),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: checking ? null : check,
                      child: const Text('测试'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () async {
                        await widget.onSave(controller.text);
                        if (context.mounted) Navigator.of(context).pop();
                      },
                      child: const Text('保存'),
                    ),
                  ),
                ],
              ),
              if (message != null) ...[
                const SizedBox(height: 12),
                Text(message!, style: const TextStyle(color: muted)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
