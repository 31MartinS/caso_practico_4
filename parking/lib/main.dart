import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'controllers/availability_controller.dart';
import 'controllers/entry_controller.dart';
import 'controllers/exit_controller.dart';
import 'controllers/plate_scan_controller.dart';
import 'controllers/history_controller.dart';
import 'controllers/auth_controller.dart';
import 'controllers/reserve_controller.dart';
import 'views/home_view.dart';
import 'views/availability_view.dart';
import 'views/entry_view.dart';
import 'views/exit_view.dart';
import 'views/plate_scan_view.dart';
import 'views/history_view.dart';
import 'views/login_view.dart';
import 'views/register_view.dart';
import 'views/reserve_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "AIzaSyA9m25gxvz3-4z0TjXHtdRHYP2Uv2yzGGw",
      authDomain: "parkin-nuevo.firebaseapp.com",
      projectId: "parkin-nuevo",
      storageBucket: "parkin-nuevo.firebasestorage.app",
      messagingSenderId: "711752851817",
      appId: "1:711752851817:web:bd0dec74fc6b83a01dddf8",
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => ReserveController()),
        ChangeNotifierProvider(create: (_) => AvailabilityController()),
        ChangeNotifierProvider(create: (_) => EntryController()),
        ChangeNotifierProvider(create: (_) => ExitController()),
        ChangeNotifierProvider(create: (_) => PlateScanController()),
        ChangeNotifierProvider(create: (_) => HistoryController()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Sistema de Parqueadero",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: AuthChecker(),
      routes: {
        "/home": (context) => HomeView(),
        "/availability": (context) => AvailabilityView(),
        "/entry": (context) => EntryView(),
        "/exit": (context) => ExitView(),
        "/scan-plate": (context) => PlateScanView(),
        "/history": (context) => HistoryView(),
        "/login": (context) => LoginScreen(),
        "/register": (context) => RegisterScreen(),
        "/reserve": (context) => ReserveView(),
      },
    );
  }
}

class AuthChecker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasData) {
          return HomeView();
        } else {
          return LoginScreen();
        }
      },
    );
  }
}
