import 'package:flutter/material.dart';
import 'home_screen.dart';

/// The entry point of Husk.
///
/// Initializes the application by running [MyApp].
void main() {
  runApp(MyApp());
}

/// The root widget Husk.
///
/// This widget sets up the [MaterialApp] with a customized theme and specifies
/// the [HomeScreen] as the initial route.
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Husk',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.blue,
        ).copyWith(
          primary: Colors.blue.shade100,
          secondary: Colors.blue.shade100,
          onPrimary: Colors.black,
          onSecondary: Colors.black,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue.shade100,
          foregroundColor: Colors.black,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.blue.shade100,
          foregroundColor: Colors.black,
        ),
      ),
      home: HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
