import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config.dart';
import 'pages/home_page.dart';
import 'theme/app_style.dart';

class TejiApp extends StatefulWidget {
  const TejiApp({super.key});

  @override
  State<TejiApp> createState() => _TejiAppState();
}

class _TejiAppState extends State<TejiApp> {
  String _apiBaseUrl = defaultApiBaseUrl;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(apiBaseUrlKey);
    final normalized = normalizeApiBaseUrl(saved);
    if (saved != normalized) {
      await prefs.setString(apiBaseUrlKey, normalized);
    }
    setState(() {
      _apiBaseUrl = normalized;
      _ready = true;
    });
  }

  Future<void> _saveApiBaseUrl(String value) async {
    final normalized = value.trim().replaceAll(RegExp(r'/+$'), '');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(apiBaseUrlKey, normalized);
    setState(() => _apiBaseUrl = normalized);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '特迹',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: _ready
          ? HomePage(apiBaseUrl: _apiBaseUrl, onSaveApiBaseUrl: _saveApiBaseUrl)
          : const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}
