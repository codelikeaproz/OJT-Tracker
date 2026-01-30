import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ojt_tracking_app/screens/role_choice.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ojt_tracking_app/screens/home_screen.dart';
import 'package:ojt_tracking_app/screens/teacher_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeUserState();
  }

  Future<void> _initializeUserState() async {
    try {
      _user = _auth.currentUser;
      setState(() {
        _isInitialized = true;
      });
      print('User initialized: \\${_user?.uid}');
      if (_user != null && mounted) {
        // Wait for Firestore doc to exist before navigating
        final userDoc = await waitForUserDoc(_user!.uid);
        final data = userDoc?.data() as Map<String, dynamic>?;
        if (data == null || data['role'] == null) {
          _navigateToRoleChoice();
        }
      }
    } catch (e) {
      print('Error initializing user state: $e');
      setState(() {
        _isInitialized = true;
      });
    }
  }

  void _navigateToRoleChoice() {
    Future.microtask(() {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => RoleChoiceScreen()),
        );
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // No navigation here to avoid race conditions
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snapshot.data;
        if (user != null) {
          // Check user's role in Firestore and navigate accordingly
          Future.microtask(() async {
            final userDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();
            
            if (!mounted) return;
            
            if (!userDoc.exists || userDoc.data()?['role'] == null) {
              // New user or no role set - navigate to role choice
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => RoleChoiceScreen()),
            );
            } else {
              // Existing user with role - navigate to appropriate screen
              final role = userDoc.data()?['role'];
              if (role == 'student') {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => HomeScreen()),
                );
              } else if (role == 'teacher') {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => TeacherScreen()),
                );
              }
            }
          });
          return Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        // Not signed in, show sign-in button
        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Center(child: _buildSignInButton()),
          ),
        );
      },
    );
  }

  Widget _buildSignInButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          Text(
            'OJT Tracker',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 30),
          Text(
            'Sign in to your google account to continue',
            style: TextStyle(color: Colors.grey[400]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 30),
          _isLoading
              ? CircularProgressIndicator()
              : Container(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    final userCredential = await signInWithGoogle();
                    if (userCredential != null) {
                      setState(() {
                        _user = userCredential.user;
                      });
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey),
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/google.png', height: 24, width: 24),
                      SizedBox(width: 12),
                      Text('Continue with Google'),
                    ],
                  ),
                ),
              ),
          const Spacer(flex: 4),
          // Add Developer credit at the bottom
          Padding(
            padding: EdgeInsets.only(bottom: 16.0),
            child: Text(
              'Developed by: Ralph BSIT-3A',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfile() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'You are signed in',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 20),
        if (_user?.photoURL != null)
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: NetworkImage(_user!.photoURL!),
                fit: BoxFit.cover,
              ),
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        SizedBox(height: 20),
        Text(
          _user?.displayName ?? 'User',
          style: TextStyle(fontSize: 20, color: Colors.white),
        ),
        if (_user != null)
          if (MediaQuery.of(context).size.width > 400)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: Text(
                  _user!.email!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        SizedBox(height: 30),
        ElevatedButton(
          onPressed: () async {
            await signOut();
            setState(() {
              _user = null;
            });
          },
          child: Text('Sign Out'),
        ),
      ],
    );
  }

  // Helper to wait for Firestore user doc to exist
  Future<DocumentSnapshot?> waitForUserDoc(String uid, {int retries = 10}) async {
    final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);
    for (int i = 0; i < retries; i++) {
      final doc = await userDoc.get();
      if (doc.exists) return doc;
      await Future.delayed(Duration(milliseconds: 500));
    }
    return null;
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      // Check if user document exists and has a role
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        // New user - create document without role
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'displayName': userCredential.user!.displayName,
          'email': userCredential.user!.email,
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => RoleChoiceScreen()),
          );
        }
      } else if (userDoc.data()?['role'] == null) {
        // Existing user but no role - navigate to role choice
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => RoleChoiceScreen()),
          );
        }
      } else {
        // Existing user with role - navigate to appropriate screen
        final role = userDoc.data()?['role'];
        if (mounted) {
          if (role == 'student') {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => HomeScreen()),
          );
          } else if (role == 'teacher') {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => TeacherScreen()),
            );
          }
        }
      }

      return userCredential;
    } catch (e) {
      print('Google Sign-In Error: $e');

      if (e.toString().contains('ApiException: 10')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please add your app\'s SHA-1 certificate to Firebase',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign in failed: $e')),
        );
      }
      return null;
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();
    } catch (e) {
      print('Error signing out: $e');
    }
  }
}

