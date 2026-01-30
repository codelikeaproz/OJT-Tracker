import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ojt_tracking_app/models/student.dart';
import 'package:ojt_tracking_app/services/app_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:ojt_tracking_app/screens/login_screen.dart';
// import 'package:ojt_tracking_app/screens/splash_screen.dart';
// import 'package:ojt_tracking_app/screens/role_choice_screen.dart';

class TeacherScreen extends StatelessWidget {
  const TeacherScreen({super.key});

  Future<void> _deleteStudent(BuildContext context, Student student) async {
    // Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Student'),
          content: Text(
            'Are you sure you want to delete ${student.name}? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        // Delete the student document
        await FirebaseFirestore.instance
            .collection('users')
            .doc(student.id)
            .delete();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Student deleted successfully'),
            backgroundColor: Color.fromARGB(255, 255, 255, 255),
          ),
        );
      } catch (e) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting student: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Add this method to handle the logout process completely
  Future<void> _handleLogout(BuildContext context) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00C853)),
            ),
          );
        },
      );

      // Perform logout
      await FirebaseAuth.instance.signOut();

      if (context.mounted) {
        // Close loading dialog
        Navigator.of(context).pop();
        // Navigate to login screen and clear all previous routes
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            // Close the dialog
                            Navigator.of(context).pop();
                            // Call the logout handler
                            _handleLogout(context);
                          },
                          child: const Text('Logout'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                        ),
                      ],
                    ),
              );
            },
          ),
          // Display user email (if space allows)
          if (MediaQuery.of(context).size.width > 400)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: Text(
                  appState.user?.email ?? 'Teacher',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: CircleAvatar(
              backgroundColor: Colors.grey[800],
              child: Text(
                (appState.user?.displayName?.isNotEmpty == true)
                    ? appState.user!.displayName![0].toUpperCase()
                    : (appState.user?.email?.isNotEmpty == true)
                    ? appState.user!.email![0].toUpperCase()
                    : 'T',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('users')
                .where('role', isEqualTo: 'student')
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: TextStyle(color: Colors.red),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00C853)),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 80, color: Colors.grey[600]),
                  SizedBox(height: 16),
                  Text(
                    'No students found',
                    style: TextStyle(fontSize: 20, color: Colors.grey[400]),
                  ),
                ],
              ),
            );
          }

          List<Student> students =
              snapshot.data!.docs
                  .map((doc) => Student.fromFirestore(doc))
                  .toList();

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index];
              return Card(
                margin: EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.grey[800],
                            backgroundImage:
                                student.photoUrl != null
                                    ? NetworkImage(student.photoUrl!)
                                    : null,
                            child:
                                student.photoUrl == null
                                    ? Text(
                                      // Fix potential empty name error
                                      student.name.isNotEmpty
                                          ? student.name[0].toUpperCase()
                                          : '?',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                    : null,
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  student.name,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (student.email.isNotEmpty)
                                  Text(
                                    student.email,
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 12,
                                    ),
                                  ),
                                if (student.role != null &&
                                    student.role!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2.0),
                                    child: Text(
                                      student.role!.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            student.role == 'teacher'
                                                ? Colors.red
                                                : Colors.green,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ),
                                if (student.ojtAddress != null &&
                                    student.ojtAddress!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6.0),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.location_on,
                                          color: Color(0xFF00C853),
                                          size: 18,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'OJT Location:',
                                          style: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            student.ojtAddress!,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (student.course != null &&
                                    student.course!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6.0),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.school,
                                          color: Color(0xFF00C853),
                                          size: 18,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Course:',
                                          style: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            student.course!,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _deleteStudent(context, student),
                            tooltip: 'Delete student',
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Progress',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(height: 4),
                                LinearProgressIndicator(
                                  value: student.progressPercentage / 100,
                                  backgroundColor: Colors.grey[800],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF00C853),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '${student.progressPercentage.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    color: Color(0xFF00C853),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 24),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Hours',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '${student.completedHours}/${student.requiredHours}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
