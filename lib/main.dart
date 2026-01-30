import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ojt_tracking_app/screens/home_screen.dart';
// import 'package:ojt_tracking_app/screens/home_screen.dart';
import 'package:ojt_tracking_app/screens/loading_screen.dart';
import 'package:ojt_tracking_app/screens/login_screen.dart';
import 'package:ojt_tracking_app/screens/role_choice.dart';
import 'package:ojt_tracking_app/screens/teacher_screen.dart';
import 'package:ojt_tracking_app/services/app_state.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    print('Error initializing Firebase: $e');
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppState(),
      child: MaterialApp(
        title: 'OJT Hours Tracker',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: Colors.black,
          appBarTheme: AppBarTheme(backgroundColor: Colors.black, elevation: 0),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: Colors.grey[900],
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF00C853),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          cardTheme: CardTheme(
            color: Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        routes: {
          '/login': (context) => LoginScreen(),
        },
        home: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            // Handle auth stream errors
            if (snapshot.hasError) {
              return Scaffold(
                backgroundColor: Colors.black,
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, color: Colors.red, size: 48),
                      SizedBox(height: 16),
                      Text('Authentication error occurred.', 
                          style: TextStyle(color: Colors.white)),
                      SizedBox(height: 8),
                      Text(snapshot.error.toString(), 
                          style: TextStyle(color: Colors.red, fontSize: 12)),
                      SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => 
                            Provider.of<AppState>(context, listen: false).signOut(),
                        child: Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return LoadingScreen();
            }

            if (!snapshot.hasData || snapshot.data == null) {
              return LoginScreen();
            }

            // User is logged in, check role with timeout
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(snapshot.data!.uid)
                  .get()
                  .timeout(
                    const Duration(seconds: 10),
                    onTimeout: () => throw TimeoutException('Failed to load user data'),
                  ),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return LoadingScreen();
                }

                // If there's an error or no data, and user is authenticated, show role choice
                if (userSnapshot.hasError || !userSnapshot.hasData || !userSnapshot.data!.exists) {
                  // Only show role choice if user is actually authenticated
                  if (snapshot.data != null) {
                    return RoleChoiceScreen();
                  }
                  // If not authenticated, go to login
                  return LoginScreen();
                }

                try {
                  final data = userSnapshot.data!.data() as Map<String, dynamic>?;
                  if (data == null) {
                    // If no data but user is authenticated, show role choice
                    if (snapshot.data != null) {
                      return RoleChoiceScreen();
                    }
                    return LoginScreen();
                  }

                  final role = data['role'] as String?;
                  // Only proceed with role-based navigation if user is authenticated
                  if (snapshot.data != null) {
                    if (role == 'student') {
                      return HomeScreen();
                    } else if (role == 'teacher') {
                      return TeacherScreen();
                    } else {
                      // No valid role but authenticated
                      return RoleChoiceScreen();
                    }
                  }
                  // Not authenticated, show login
                  return LoginScreen();
                } catch (e) {
                  print('Error processing user data: $e');
                  // If error occurs but user is authenticated, show role choice
                  if (snapshot.data != null) {
                    return RoleChoiceScreen();
                  }
                  return LoginScreen();
                }
              },
            );
          },
        ),
      ),
    );
  }
}
