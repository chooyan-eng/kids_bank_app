import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'db/sqlite_repository.dart';
import 'screens/home_screen.dart';
import 'widgets/app_data_scope.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ja');
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppDataScope(
      repository: SqliteRepository(),
      child: const NeumorphicApp(
        title: 'こどもぎんこう',
        themeMode: ThemeMode.light,
        theme: NeumorphicThemeData(
          baseColor: Color(0xFFE8ECF0),
          lightSource: LightSource.topLeft,
          depth: 8,
          intensity: 0.7,
        ),
        home: HomeScreen(),
      ),
    );
  }
}
