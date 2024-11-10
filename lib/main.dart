import 'package:flutter/material.dart';
import 'home_screen.dart'; // Import HomeScreen

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'To-Do List App',
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
