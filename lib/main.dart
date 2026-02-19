import 'package:flutter/material.dart';

import 'db/dummy_repository.dart';
import 'widgets/app_data_scope.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppDataScope(
      repository: DummyRepository(),
      child: MaterialApp(
        title: 'こどもぎんこう',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFFF8C00), // warm orange
            brightness: Brightness.light,
          ),
        ),
        home: const Scaffold(
          body: Center(
            child: Text('こどもぎんこう'),
          ),
        ),
      ),
    );
  }
}
