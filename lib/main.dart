import 'package:flutter/material.dart';
import 'app/app.dart';
import 'app/dependencies.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureAppDependencies();
  runApp(const MyApp());
}
