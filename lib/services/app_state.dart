import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ojt_tracking_app/models/time_entry.dart';
import 'dart:async' show unawaited;

class AppState extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  bool _isLoading = false;
  User? _user;
  int _requiredHours = 500;
  int _completedHours = 0;
  List<TimeEntry> _timeEntries = [];

  bool get isLoading => _isLoading;
  User? get user => _user;
  int get requiredHours => _requiredHours;
  int get completedHours => _completedHours;
  List<TimeEntry> get timeEntries => _timeEntries;

  double get progressPercentage {
    if (_requiredHours == 0) return 0;
    double percentage = (_completedHours / _requiredHours) * 100;
    return percentage > 100 ? 100 : percentage;
  }

  AppState() {
    _initializeApp();
  }

  void _initializeApp() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      if (user != null) {
        _fetchUserData();
      } else {
        _timeEntries = [];
        _completedHours = 0;
      }
      notifyListeners();
    });
  }

  Future<void> _fetchUserData() async {
    if (_user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Fetch user profile
      final profileSnapshot =
          await _firestore.collection('users').doc(_user!.uid).get();

      if (profileSnapshot.exists) {
        final data = profileSnapshot.data();
        if (data != null) {
          _requiredHours = data['requiredHours'] ?? 500;
        }
      } else {
        // Create user profile if it doesn't exist
        await _firestore.collection('users').doc(_user!.uid).set({
          'displayName': _user!.displayName,
          'email': _user!.email,
          'requiredHours': 500,
          'completedHours': 0,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // Fetch time entries
      final entriesSnapshot =
          await _firestore
              .collection('users')
              .doc(_user!.uid)
              .collection('timeEntries')
              .orderBy('date', descending: true)
              .get();

      _timeEntries =
          entriesSnapshot.docs
              .map((doc) => TimeEntry.fromJson(doc.data(), doc.id))
              .toList();

      _calculateTotalHours();
    } catch (e) {
      print('Error fetching user data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _calculateTotalHours() {
    _completedHours = 0;
    for (var entry in _timeEntries) {
      // Calculate hours for each entry
      double entryHours = 0;

      // Morning
      if (entry.morningTimeIn != null && entry.morningTimeOut != null) {
        entryHours += _calculateHoursBetween(
          entry.morningTimeIn!,
          entry.morningTimeOut!,
        );
      }

      // Afternoon
      if (entry.afternoonTimeIn != null && entry.afternoonTimeOut != null) {
        entryHours += _calculateHoursBetween(
          entry.afternoonTimeIn!,
          entry.afternoonTimeOut!,
        );
      }

      // Evening
      if (entry.eveningTimeIn != null && entry.eveningTimeOut != null) {
        entryHours += _calculateHoursBetween(
          entry.eveningTimeIn!,
          entry.eveningTimeOut!,
        );
      }

      _completedHours += entryHours.round();
    }

    // Update user profile with completed hours
    if (_user != null) {
      _firestore.collection('users').doc(_user!.uid).update({
        'completedHours': _completedHours,
      });
    }
  }

  double _calculateHoursBetween(TimeOfDay start, TimeOfDay end) {
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    if (endMinutes < startMinutes) {
      // Handle crossing midnight
      return ((24 * 60 - startMinutes) + endMinutes) / 60.0;
    }

    return (endMinutes - startMinutes) / 60.0;
  }

  Future<void> signOut() async {
    try {
      // Immediately clear UI state and notify listeners
      _isLoading = true;
      notifyListeners();
      
      // Clear all local state in one go
      _timeEntries = [];
      _completedHours = 0;
      _requiredHours = 500;
      _user = null;
      
      // Notify UI of state change immediately
      notifyListeners();
      
      // Start network operations in background
      unawaited(_performSignOut());
    } catch (e) {
      print('Error during sign out: $e');
    }
  }

  Future<void> _performSignOut() async {
    try {
      // Perform sign out operations with shorter timeouts
      await Future.wait([
        _auth.signOut().timeout(
          const Duration(seconds: 3),
          onTimeout: () => null,
        ),
        _googleSignIn.isSignedIn().then((signedIn) => 
          signedIn ? _googleSignIn.signOut().timeout(
            const Duration(seconds: 3),
            onTimeout: () => null,
          ) : null
        ),
      ]);
    } catch (e) {
      print('Error during background sign out: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setRequiredHours(int hours) async {
    _requiredHours = hours;
    notifyListeners();

    if (_user != null) {
      await _firestore.collection('users').doc(_user!.uid).update({
        'requiredHours': hours,
      });
    }
  }

  Future<void> addTimeEntry(TimeEntry entry) async {
    if (_user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Add to local state first
      _timeEntries.insert(0, entry);
      _calculateTotalHours();
    } catch (e) {
      print('Error adding time entry: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeTimeEntry(String id) async {
    if (_user == null) return;

    final index = _timeEntries.indexWhere((entry) => entry.id == id);
    if (index != -1) {
      _timeEntries.removeAt(index);
      _calculateTotalHours();
      notifyListeners();
    }
  }

  Future<void> refreshData() async {
    await _fetchUserData();
  }
} 