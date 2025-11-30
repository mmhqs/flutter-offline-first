import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart'; 

import 'screens/task_list_screen.dart';

Future<void> main() async {
  // Garante que o Flutter esteja inicializado
  WidgetsFlutterBinding.ensureInitialized();

  // VERIFICA A WEB PRIMEIRO!
  if (kIsWeb) {
    // Configura o factory para a web
    databaseFactory = databaseFactoryFfiWeb;
  } 
  // Se NÃO FOR web, checa se é desktop
  else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    // Configura o factory para desktop
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  // Se não for nem web nem desktop (Android/iOS), 
  // o sqflite padrão é usado automaticamente.

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Manager Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        cardTheme: const CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          filled: true,
          fillColor: Color(0xFFF5F5F5),
        ),
      ),
      home: const TaskListScreen(),
    );
  }
}