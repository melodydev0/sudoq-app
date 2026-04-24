import 'package:flutter/material.dart';
import 'features/settings/presentation/screens/icon_export_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _ExportApp());
}

class _ExportApp extends StatelessWidget {
  const _ExportApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Icon Export Tool',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1a1a2e),
      ),
      home: const IconExportScreen(),
    );
  }
}
