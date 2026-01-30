import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ojt_tracking_app/models/time_entry.dart';
import 'package:ojt_tracking_app/services/app_state.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime selectedDate = DateTime.now();
  TimeOfDay? morningTimeIn;
  TimeOfDay? morningTimeOut;
  TimeOfDay? afternoonTimeIn;
  TimeOfDay? afternoonTimeOut;
  TimeOfDay? eveningTimeIn;
  TimeOfDay? eveningTimeOut;
  final TextEditingController requiredHoursController = TextEditingController(
    text: '500',
  );
  final TextEditingController ojtAddressController = TextEditingController();
  final TextEditingController courseController = TextEditingController();
  final TextEditingController morningTaskController = TextEditingController();
  final TextEditingController morningDescriptionController =
      TextEditingController();
  final TextEditingController afternoonTaskController = TextEditingController();
  final TextEditingController afternoonDescriptionController =
      TextEditingController();
  final TextEditingController eveningTaskController = TextEditingController();
  final TextEditingController eveningDescriptionController =
      TextEditingController();
  bool showCalendar = false;
  CalendarFormat calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);
    requiredHoursController.text = appState.requiredHours.toString();
    // Load OJT address and course if available
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .get();

      if (doc.exists) {
        setState(() {
          if (doc.data()!.containsKey('ojtAddress')) {
            ojtAddressController.text = doc.data()!['ojtAddress'];
          }
          if (doc.data()!.containsKey('course')) {
            courseController.text = doc.data()!['course'];
          }
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _saveUserData() async {
    if (ojtAddressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your OJT workplace address.'),
        ),
      );
      return;
    }
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .set({
            'ojtAddress': ojtAddressController.text,
            'course': courseController.text,
          }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Information saved successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save information: $e')));
    }
  }

  Future<void> _selectTime(
    BuildContext context,
    String period,
    String type,
  ) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: Color(0xFF00C853),
              onPrimary: Colors.white,
              surface: Color(0xFF1E1E1E),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: Color(0xFF1E1E1E),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (period == 'morning' && type == 'in') {
          morningTimeIn = picked;
        } else if (period == 'morning' && type == 'out') {
          morningTimeOut = picked;
        } else if (period == 'afternoon' && type == 'in') {
          afternoonTimeIn = picked;
        } else if (period == 'afternoon' && type == 'out') {
          afternoonTimeOut = picked;
        } else if (period == 'evening' && type == 'in') {
          eveningTimeIn = picked;
        } else if (period == 'evening' && type == 'out') {
          eveningTimeOut = picked;
        }
      });
    }
  }

  void _addTimeEntry() {
    // Prevent future date selection
    if (selectedDate.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot select a future date.')),
      );
      return;
    }
    // Check if at least one complete time period (in and out) is entered
    bool morningComplete = morningTimeIn != null && morningTimeOut != null;
    bool afternoonComplete =
        afternoonTimeIn != null && afternoonTimeOut != null;
    bool eveningComplete = eveningTimeIn != null && eveningTimeOut != null;

    if (!morningComplete && !afternoonComplete && !eveningComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in at least one complete time period'),
        ),
      );
      return;
    }

    final newEntry = TimeEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: selectedDate,
      morningTimeIn: morningTimeIn,
      morningTimeOut: morningTimeOut,
      afternoonTimeIn: afternoonTimeIn,
      afternoonTimeOut: afternoonTimeOut,
      eveningTimeIn: eveningTimeIn,
      eveningTimeOut: eveningTimeOut,
      morningTask: morningTaskController.text,
      morningDescription: morningDescriptionController.text,
      afternoonTask: afternoonTaskController.text,
      afternoonDescription: afternoonDescriptionController.text,
      eveningTask: eveningTaskController.text,
      eveningDescription: eveningDescriptionController.text,
    );

    Provider.of<AppState>(context, listen: false).addTimeEntry(newEntry);

    // Save to Firebase
    FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('timeEntries')
        .add(newEntry.toJson())
        .then((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Time entry added successfully')),
          );
          // Reset form
          setState(() {
            morningTimeIn = null;
            morningTimeOut = null;
            afternoonTimeIn = null;
            afternoonTimeOut = null;
            eveningTimeIn = null;
            eveningTimeOut = null;
            morningTaskController.clear();
            morningDescriptionController.clear();
            afternoonTaskController.clear();
            afternoonDescriptionController.clear();
            eveningTaskController.clear();
            eveningDescriptionController.clear();
            showCalendar = false;
          });
        })
        .catchError((error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add time entry: $error')),
          );
        });
  }

  String _formatTimeOfDay(TimeOfDay? tod) {
    if (tod == null) return '--:-- --';
    final hour = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
    final minute = tod.minute.toString().padLeft(2, '0');
    final period = tod.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  double _calculateHoursBetween(TimeOfDay? start, TimeOfDay? end) {
    if (start == null || end == null) return 0;

    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    if (endMinutes < startMinutes) {
      // Handle crossing midnight
      return ((24 * 60 - startMinutes) + endMinutes) / 60.0;
    }

    return (endMinutes - startMinutes) / 60.0;
  }

  Widget _buildCalendar() {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.now(),
            focusedDay: selectedDate,
            calendarFormat: calendarFormat,
            selectedDayPredicate: (day) {
              return isSameDay(selectedDate, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                selectedDate = selectedDay;
                showCalendar = false; // Hide calendar after selection
              });
            },
            onFormatChanged: (format) {
              setState(() {
                calendarFormat = format;
              });
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Color(0xFF00C853),
                shape: BoxShape.circle,
              ),
              defaultTextStyle: TextStyle(color: Colors.white),
              weekendTextStyle: TextStyle(color: Colors.white),
              outsideTextStyle: TextStyle(color: Colors.grey),
              todayTextStyle: TextStyle(color: Colors.white),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(color: Colors.white, fontSize: 16),
              leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
              rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(color: Colors.white),
              weekendStyle: TextStyle(color: Colors.white),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  child: Text('Clear', style: TextStyle(color: Colors.blue)),
                  onPressed: () {
                    setState(() {
                      selectedDate = DateTime.now();
                    });
                  },
                ),
                TextButton(
                  child: Text('Today', style: TextStyle(color: Colors.blue)),
                  onPressed: () {
                    setState(() {
                      selectedDate = DateTime.now();
                      showCalendar = false;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(AppState appState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'OJT Progress',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 150,
                    width: 150,
                    child: CircularProgressIndicator(
                      value: appState.completedHours / appState.requiredHours,
                      strokeWidth: 10,
                      backgroundColor: Colors.grey[800],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF00C853),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(appState.progressPercentage).toInt()}%',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00C853),
                        ),
                      ),
                      const Text(
                        'Complete',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${appState.completedHours} hours completed'),
                Text('${appState.requiredHours} hours required'),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Total Required Hours:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: requiredHoursController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'Total hours needed'),
              onChanged: (value) {
                if (value.isNotEmpty) {
                  appState.setRequiredHours(int.parse(value));
                }
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'OJT Address:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: ojtAddressController,
              decoration: const InputDecoration(
                hintText: 'Enter your OJT workplace address',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            const Text(
              'Course:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: courseController,
              decoration: const InputDecoration(
                hintText: 'Enter your course',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _saveUserData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF00C853),
                ),

                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('Save Information'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskSection(
    String period,
    TextEditingController taskController,
    TextEditingController descriptionController,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          '$period Tasks:',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: taskController,
          decoration: InputDecoration(
            hintText: 'Enter $period task',
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: descriptionController,
          decoration: InputDecoration(
            hintText: 'Enter $period task description',
            border: const OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildTimeEntryForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Record Time Entry',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: const [
                Icon(Icons.calendar_today, size: 16),
                SizedBox(width: 8),
                Text('Date'),
              ],
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () {
                setState(() {
                  showCalendar = !showCalendar;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                    const Icon(Icons.calendar_today),
                  ],
                ),
              ),
            ),
            if (showCalendar) ...[const SizedBox(height: 8), _buildCalendar()],
            const SizedBox(height: 16),
            // Morning Time
            Row(
              children: const [
                Icon(Icons.access_time, size: 16),
                SizedBox(width: 8),
                Text('Morning'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectTime(context, 'morning', 'in'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatTimeOfDay(morningTimeIn)),
                          const Icon(Icons.access_time),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectTime(context, 'morning', 'out'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatTimeOfDay(morningTimeOut)),
                          const Icon(Icons.access_time),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Time In',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Time Out',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ),
              ],
            ),
            _buildTaskSection(
              'Morning',
              morningTaskController,
              morningDescriptionController,
            ),
            const SizedBox(height: 16),
            // Afternoon Time
            Row(
              children: const [
                Icon(Icons.access_time, size: 16),
                SizedBox(width: 8),
                Text('Afternoon'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectTime(context, 'afternoon', 'in'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatTimeOfDay(afternoonTimeIn)),
                          const Icon(Icons.access_time),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectTime(context, 'afternoon', 'out'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatTimeOfDay(afternoonTimeOut)),
                          const Icon(Icons.access_time),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Time In',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Time Out',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ),
              ],
            ),
            _buildTaskSection(
              'Afternoon',
              afternoonTaskController,
              afternoonDescriptionController,
            ),
            const SizedBox(height: 16),
            // Evening Time (Optional)
            Row(
              children: const [
                Icon(Icons.access_time, size: 16),
                SizedBox(width: 8),
                Text('Evening (Optional)'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectTime(context, 'evening', 'in'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatTimeOfDay(eveningTimeIn)),
                          const Icon(Icons.access_time),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectTime(context, 'evening', 'out'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatTimeOfDay(eveningTimeOut)),
                          const Icon(Icons.access_time),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Time In',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Time Out',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ),
              ],
            ),
            _buildTaskSection(
              'Evening',
              eveningTaskController,
              eveningDescriptionController,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _addTimeEntry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C853),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Add Time Entry',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeEntryHistory(AppState appState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Time Entry History',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            appState.timeEntries.isEmpty
                ? Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.access_time, color: Colors.grey),
                      SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'No time entries yet. Add your first entry using the form above.',
                        ),
                      ),
                    ],
                  ),
                )
                : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: appState.timeEntries.length,
                  separatorBuilder:
                      (context, index) =>
                          Divider(color: Colors.grey[800], height: 1),
                  itemBuilder: (context, index) {
                    final entry = appState.timeEntries[index];
                    final morningHours = _calculateHoursBetween(
                      entry.morningTimeIn,
                      entry.morningTimeOut,
                    );
                    final afternoonHours = _calculateHoursBetween(
                      entry.afternoonTimeIn,
                      entry.afternoonTimeOut,
                    );
                    final eveningHours = _calculateHoursBetween(
                      entry.eveningTimeIn,
                      entry.eveningTimeOut,
                    );
                    final totalHours =
                        morningHours + afternoonHours + eveningHours;

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date and total hours in separate rows
                          Text(
                            DateFormat('EEEE, MMMM d, yyyy').format(entry.date),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${totalHours.toStringAsFixed(2)} hours',
                            style: const TextStyle(
                              color: Color(0xFF2196F3),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1, color: Colors.grey),
                          const SizedBox(height: 12),

                          // Time periods
                          if (morningHours > 0)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Morning:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${_formatTimeOfDay(entry.morningTimeIn)} - ${_formatTimeOfDay(entry.morningTimeOut)} (${morningHours.toStringAsFixed(2)} hrs)',
                                  ),
                                  if (entry.morningTask?.isNotEmpty ==
                                      true) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Task: ${entry.morningTask}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                  if (entry.morningDescription?.isNotEmpty ==
                                      true) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'Description: ${entry.morningDescription}',
                                    ),
                                  ],
                                ],
                              ),
                            ),

                          if (afternoonHours > 0)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Afternoon:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${_formatTimeOfDay(entry.afternoonTimeIn)} - ${_formatTimeOfDay(entry.afternoonTimeOut)} (${afternoonHours.toStringAsFixed(2)} hrs)',
                                  ),
                                  if (entry.afternoonTask?.isNotEmpty ==
                                      true) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Task: ${entry.afternoonTask}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                  if (entry.afternoonDescription?.isNotEmpty ==
                                      true) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'Description: ${entry.afternoonDescription}',
                                    ),
                                  ],
                                ],
                              ),
                            ),

                          if (eveningHours > 0)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Evening:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${_formatTimeOfDay(entry.eveningTimeIn)} - ${_formatTimeOfDay(entry.eveningTimeOut)} (${eveningHours.toStringAsFixed(2)} hrs)',
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton(
                              onPressed: () {
                                // Delete entry logic
                                FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(FirebaseAuth.instance.currentUser!.uid)
                                    .collection('timeEntries')
                                    .doc(entry.id)
                                    .delete()
                                    .then((_) {
                                      appState.removeTimeEntry(entry.id);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Time entry deleted'),
                                        ),
                                      );
                                    });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD32F2F),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Delete'),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600; // Threshold for mobile layout

    return Scaffold(
      appBar: AppBar(
        title: const Text('OJT Hours Tracker'),
        actions: [
          // Logout button
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              // Show confirmation dialog
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
                          onPressed: () async {
                            Navigator.of(context).pop();
                            try {
                              // Show loading indicator
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (BuildContext context) {
                                  return Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFF00C853),
                                      ),
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
                                Navigator.of(context).pushNamedAndRemoveUntil(
                                  '/login',
                                  (route) => false,
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                // Close loading dialog
                                Navigator.of(context).pop();
                                // Show error message
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error signing out: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
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
                  appState.user?.email ?? 'User',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

          // User avatar with initial
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: CircleAvatar(
              backgroundColor: Colors.grey[800],
              child: Text(
                (appState.user?.displayName?.isNotEmpty == true)
                    ? appState.user!.displayName![0].toUpperCase()
                    : (appState.user?.email?.isNotEmpty == true)
                    ? appState.user!.email![0].toUpperCase()
                    : 'U',
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
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Use Column instead of Row for mobile layout
                isMobile
                    ? Column(
                      children: [
                        _buildProgressSection(appState),
                        const SizedBox(height: 16),
                        _buildTimeEntryForm(),
                      ],
                    )
                    : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildProgressSection(appState)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTimeEntryForm()),
                      ],
                    ),
                const SizedBox(height: 16),
                // Time Entry History
                _buildTimeEntryHistory(appState),

                // Add extra padding at the bottom to ensure the footer doesn't overlap content
                const SizedBox(height: 40),
              ],
            ),
          ),

          // Developer footer
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: Colors.black,
              child: const Text(
                'Built with Flutter + Firebase',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
