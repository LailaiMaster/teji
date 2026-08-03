import 'package:flutter/material.dart';

import '../theme/app_style.dart';

class TopBar extends StatelessWidget {
  const TopBar({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onSettings,
  });

  final String title;
  final String subtitle;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: muted, fontSize: 13),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          onPressed: onSettings,
          icon: const Icon(Icons.tune),
          style: IconButton.styleFrom(
            backgroundColor: panel2,
            foregroundColor: text,
          ),
        ),
      ],
    );
  }
}

class PageShell extends StatelessWidget {
  const PageShell({
    super.key,
    required this.title,
    this.subtitle,
    required this.children,
    this.action,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
        children: [
          SafeArea(
            bottom: false,
            child: Row(
              children: [
                IconButton.filledTonal(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                  style: IconButton.styleFrom(backgroundColor: panel2),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: const TextStyle(color: muted, fontSize: 13),
                        ),
                    ],
                  ),
                ),
                if (action != null) action!,
              ],
            ),
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }
}

class FuturePane<T> extends StatelessWidget {
  const FuturePane({
    super.key,
    required this.future,
    required this.builder,
    this.onRefresh,
    this.errorAction,
  });

  final Future<T> future;
  final Widget Function(BuildContext context, T data) builder;
  final Future<void> Function()? onRefresh;
  final Widget? errorAction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<T>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final child = ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 160),
                const Icon(Icons.cloud_off, color: red, size: 46),
                const SizedBox(height: 16),
                const Text(
                  '连不上数据服务',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: text,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  snapshot.error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: muted, fontSize: 13),
                ),
                if (errorAction != null) ...[
                  const SizedBox(height: 18),
                  Center(child: errorAction!),
                ],
              ],
            );
            return onRefresh == null
                ? child
                : RefreshIndicator(onRefresh: onRefresh!, child: child);
          }
          final data = snapshot.data;
          if (data == null) return const Center(child: Text('暂无数据'));
          return builder(context, data);
        },
      ),
    );
  }
}
