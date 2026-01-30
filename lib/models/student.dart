import 'package:cloud_firestore/cloud_firestore.dart';

class Student {
  final String id;
  final String name;
  final String email;
  final int requiredHours;
  final int completedHours;
  final String? photoUrl;
  final String? ojtAddress;
  final String? role;
  final String? course;

  Student({
    required this.id,
    required this.name,
    required this.email,
    required this.requiredHours,
    required this.completedHours,
    this.photoUrl,
    this.ojtAddress,
    this.role,
    this.course,
  });

  double get progressPercentage {
    if (requiredHours == 0) return 0;
    double percentage = (completedHours / requiredHours) * 100;
    return percentage > 100 ? 100 : percentage;
  }

  factory Student.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Student(
      id: doc.id,
      name: data['displayName'] ?? 'Unknown Student',
      email: data['email'] ?? '',
      requiredHours: data['requiredHours'] ?? 500,
      completedHours: data['completedHours'] ?? 0,
      photoUrl: data['photoUrl'],
      ojtAddress: data['ojtAddress'],
      role: data['role'],
      course: data['course'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': name,
      'email': email,
      'requiredHours': requiredHours,
      'completedHours': completedHours,
      'photoUrl': photoUrl,
      'ojtAddress': ojtAddress,
      'role': role,
      'course': course,
    };
  }
} 