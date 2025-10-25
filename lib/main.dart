import 'package:dynamic_color/dynamic_color.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart';
import 'package:chuck_normis_app/application/agent_entry_notifier.dart';
import 'package:chuck_normis_app/conf.dart';
import 'package:chuck_normis_app/data/datasources/database_helper.dart';

import 'package:chuck_normis_app/data/repositories/chat_repository_impl.dart';
import 'package:chuck_normis_app/data/repositories/workout_repository_impl.dart';
import 'package:chuck_normis_app/data/services/vosk_service.dart';
import 'package:chuck_normis_app/data/services/websocket_service.dart';
import 'package:chuck_normis_app/domain/repositories/chat_repository.dart';
import 'package:chuck_normis_app/domain/repositories/workout_repository.dart';
import 'package:flutter/material.dart';
import 'presentation/workouts_screen.dart';
import 'package:chuck_normis_app/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  String? clientId = prefs.getString('client_id');
  if (clientId == null) {
    clientId = const Uuid().v4();
    await prefs.setString('client_id', clientId);
  }
  runApp(AppWrapper(clientId: clientId));
}

class AppWrapper extends StatelessWidget {
  final String clientId;
  const AppWrapper({super.key, required this.clientId});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<DatabaseHelper>(create: (_) => DatabaseHelper.instance),
        Provider<WebSocketService>(
          create: (_) => WebSocketService(Conf.baseUrl, clientId),
          dispose: (_, service) => service.dispose(),
        ),
        Provider<VoskService>(
          create: (_) {
            final service = VoskService.instance;
            service.initialize('assets/models/vosk-model-small-ru-0.22.zip');
            return service;
          },
          dispose: (_, service) => service.dispose(),
        ),
        ProxyProvider<DatabaseHelper, WorkoutRepository>(
          update: (_, dbHelper, _) => WorkoutRepositoryImpl(dbHelper),
        ),
        ProxyProvider2<WebSocketService, DatabaseHelper, ChatRepository>(
          update: (_, ws, db, _) => ChatRepositoryImpl(ws, db),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              AgentEntryNotifier(context.read<ChatRepository>()),
        ),
      ],
      child: const App(),
    );
  }
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        final (ThemeData lightTheme, ThemeData darkTheme) =
            AppTheme.fromDynamic(lightDynamic, darkDynamic);

        return MaterialApp(
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: ThemeMode.system,
          home: const WorkoutsScreen(),
        );
      },
    );
  }
}
