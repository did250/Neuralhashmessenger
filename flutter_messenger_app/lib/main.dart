import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_messenger_app/src/pages/Login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = new MyHttpOverrides();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyHttpOverrides extends HttpOverrides{
  @override
  HttpClient createHttpClient(SecurityContext? context){
    return super.createHttpClient(context)..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          title: 'Messenger',
          themeMode: currentMode,
          theme: ThemeData(
            primarySwatch: Colors.blue,
            canvasColor: Colors.white,
            primaryColor: Colors.black,
            primaryColorLight: Colors.grey,
            primaryColorDark: Colors.grey,
            primaryColorBrightness: Brightness.light,
            brightness: Brightness.light,
            indicatorColor: Colors.black,
            appBarTheme: AppBarTheme(brightness: Brightness.light),
          ),
          darkTheme: ThemeData(
            canvasColor: Colors.black,
            primaryColor: Colors.white,
            primaryColorLight: Colors.white,
            primaryColorDark: Colors.white,
            primaryColorBrightness: Brightness.dark,
            brightness: Brightness.dark,
            indicatorColor: Colors.white,
            appBarTheme: AppBarTheme(brightness: Brightness.dark),
          ),
          debugShowCheckedModeBanner: false,
          home: LoginScreen(),
        );
      },
    );
  }
}