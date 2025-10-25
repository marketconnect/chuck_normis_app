import 'package:flutter/material.dart';

/// Экран настроек приложения.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 1,
            color: theme.colorScheme.surfaceContainerHighest,
            child: const ListTile(
              leading: Icon(Icons.person),
              title: Text('Аккаунт'),
              subtitle: Text('Будет добавлено позже'),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 1,
            child: SwitchListTile(
              secondary: const Icon(Icons.notifications),
              title: const Text('Уведомления'),
              value: true,
              onChanged: (bool value) {
                // TODO: сохранить настройку уведомлений
              },
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 1,
            color: theme.colorScheme.surfaceContainerHighest,
            child: const ListTile(
              leading: Icon(Icons.palette),
              title: Text('Тема'),
              subtitle: Text('Следовать системным настройкам'),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 1,
            child: const ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('О приложении'),
              subtitle: Text('Версия и сведения будут добавлены позже'),
            ),
          ),
        ],
      ),
    );
  }
}
