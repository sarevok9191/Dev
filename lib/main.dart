import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.amber,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.black,
          iconTheme: IconThemeData(color: Colors.amber),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.amber,
          foregroundColor: Colors.black,
        ),
        textTheme: TextTheme(
          displayLarge: TextStyle(color: Colors.amber, fontSize: 32),
          bodyLarge: TextStyle(color: Colors.white, fontSize: 16),
          bodyMedium: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        iconTheme: IconThemeData(color: Colors.amber),
        inputDecorationTheme: InputDecorationTheme(
          labelStyle: TextStyle(color: Colors.amber),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.amber),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.amberAccent),
          ),
        ),
      ),
      home: LoginScreen(),
    );
  }
}


class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String loggedInTrainer = '';
  TextEditingController _usernameController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  String errorMessage = '';


  Future<void> _login() async {
    String username = _usernameController.text;
    String password = _passwordController.text;

    if (username == 'Sulo' && password == '123') {
      loggedInTrainer = 'Sulo';
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => TrainerScreen(loggedInTrainer: loggedInTrainer)),
      );
    }
    else if(username == 'Fero' && password == '123') {
      loggedInTrainer = 'Fero';
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => TrainerScreen(loggedInTrainer:loggedInTrainer)),
        );
    }
     else {
      List<Map<String, dynamic>> userCredentials = await getUserCredentials();
      bool loginSuccess = false;

      for (var user in userCredentials) {
        if (username == user['username'] && password == user['password']) {
          loginSuccess = true;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => UserScreen(user)),
          );
          break;
        }
      }

      if (!loginSuccess) {
        setState(() {
          errorMessage = 'Invalid username or password';
        });
      }
    }
  }

  Future<List<Map<String, dynamic>>> getUserCredentials() async {
    List<Map<String, dynamic>> userList = [];
    CollectionReference usersCollection = FirebaseFirestore.instance.collection('users');
    QuerySnapshot snapshot = await usersCollection.get();
    snapshot.docs.forEach((doc) {
      userList.add(doc.data() as Map<String, dynamic>);
    });
    return userList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Password'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _login,
              child: Text('Login'),
            ),
            if (errorMessage.isNotEmpty)
              Text(
                errorMessage,
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }
}



class TrainerScreen extends StatefulWidget {
  final String loggedInTrainer;
  TrainerScreen ({Key? key, required this.loggedInTrainer}) : super(key: key);
 
  @override
  _TrainerScreenState createState() => _TrainerScreenState();
}

class _TrainerScreenState extends State<TrainerScreen> {
  List<Map<String, dynamic>> users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    CollectionReference usersCollection = FirebaseFirestore.instance.collection('users');
    QuerySnapshot snapshot = await usersCollection.get();
    setState(() {
      users = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>}).toList();
    });
  }

  Future<void> _createUser(String username, String password, int sessionCount) async {
    CollectionReference usersCollection = FirebaseFirestore.instance.collection('users');
    await usersCollection.add({
      'username': username,
      'password': password,
      'sessionCount': sessionCount,
    });
    _loadUsers(); // Reload users after creating a new one
  }

  Future<void> _deleteUser(String userId) async {
    CollectionReference usersCollection = FirebaseFirestore.instance.collection('users');
    await usersCollection.doc(userId).delete();
    _loadUsers(); // Reload users after deletion
  }

  Future<void> _editUserSessions(String userId, int sessionCount) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'sessionCount': sessionCount,
    });
    _loadUsers(); // Reload users after editing
  }

  void _showUserCreationDialog() {
    String newUsername = '';
    String newPassword = '';
    int newSessionCount = 0;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Create User'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                onChanged: (value) => newUsername = value,
                decoration: InputDecoration(labelText: 'Username'),
              ),
              TextField(
                onChanged: (value) => newPassword = value,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              TextField(
                onChanged: (value) => newSessionCount = int.tryParse(value) ?? 0,
                decoration: InputDecoration(labelText: 'Session Count'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _createUser(newUsername, newPassword, newSessionCount);
              },
              child: Text('Create'),
            ),
          ],
        );
      },
    );
  }

  void _showEditUserDialog(String userId, int sessionCount) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Edit Sessions'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove),
                        onPressed: () {
                          setState(() {
                            sessionCount = sessionCount > 0 ? sessionCount - 1 : 0;
                          });
                        },
                      ),
                      Text('$sessionCount'),
                      IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () {
                          setState(() {
                            sessionCount++;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _editUserSessions(userId, sessionCount); // Pass the document ID
                  },
                  child: Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text(''),
      actions: [
        Expanded(
          child: Center(
            child: IconButton(
              icon: Icon(Icons.calendar_today),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CalendarScreen(loggedInTrainer: loggedInTrainer)),
                );
              },
            ),
          ),
        ),
      ],
    ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var users = snapshot.data!.docs.map((doc) {
            return {
              'id': doc.id,
              'username': doc['username'],
              'sessionCount': doc['sessionCount'],
            };
          }).toList();

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              var user = users[index];
              return ListTile(
                title: Text(user['username']),
                subtitle: Text('Sessions: ${user['sessionCount']}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () {
                        _showEditUserDialog(user['id'], user['sessionCount']);
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () {
                        _deleteUser(user['id']); // Pass the document ID
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showUserCreationDialog,
        child: Icon(Icons.add),
      ),
    );
  }
}


class UserScreen extends StatelessWidget {
  final Map<String, dynamic> user;

  UserScreen(this.user);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Dashboard'),
      ),
      body: Center(
        child: Text(
          'Welcome ${user['username']}\nSessions: ${user['sessionCount']}',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class CalendarScreen extends StatefulWidget {
  final String loggedInTrainer;

  CalendarScreen({Key? key, required this.loggedInTrainer}) : super(key: key);
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  Map<DateTime, List<Map<String, dynamic>>> _schedules = {};
  DateTime _selectedDay = DateTime.now();
  late final ValueNotifier<DateTime> _focusedDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = ValueNotifier<DateTime>(_selectedDay);
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    CollectionReference schedulesCollection = FirebaseFirestore.instance.collection('schedules');
    QuerySnapshot snapshot = await schedulesCollection.get();

    setState(() {
      _schedules = {};
    });

    for (var doc in snapshot.docs) {
      DateTime date = DateTime.parse(doc.id);
      QuerySnapshot eventsSnapshot = await schedulesCollection.doc(doc.id).collection('events').get();

      setState(() {
        if (_schedules[date] == null) _schedules[date] = [];
        for (var event in eventsSnapshot.docs) {
          _schedules[date]?.add({
            'id': event.id, // Store the schedule ID
            'userNames': List<String>.from(event['userNames']),
            'startTime': event['startTime'],
            'endTime': event['endTime'],
          });
        }
      });
    }
  }

 Future<void> _saveSchedule(DateTime date, List<String> userIds, TimeOfDay startTime, TimeOfDay endTime, {String? scheduleId}) async {
  CollectionReference schedulesCollection = FirebaseFirestore.instance.collection('schedules');
  DocumentReference dateDocRef = schedulesCollection.doc(date.toIso8601String());

  // Create the schedule with outline color based on loggedInTrainer
  Color outlineColor;
  if (widget.loggedInTrainer == 'Sulo') {
    outlineColor = Colors.yellow;
  } else if (widget.loggedInTrainer == 'Fero') {
    outlineColor = Colors.red;
  } else {
    outlineColor = Colors.grey; // Default color
  }

  // Proceed with saving logic
  List<String> userNames = [];
  for (String userId in userIds) {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (userDoc.exists) {
      userNames.add(userDoc['username']);
    } else {
      print('User document for $userId does not exist.');
    }
  }

  if (scheduleId != null) {
    // If editing, update the existing schedule
    await dateDocRef.collection('events').doc(scheduleId).update({
      'userNames': userNames,
      'startTime': '${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')}',
      'endTime': '${endTime.hour}:${endTime.minute.toString().padLeft(2, '0')}',
      'outlineColor': outlineColor.value, // Save the outline color
    });
  } else {
    // Otherwise, create a new event
    await dateDocRef.collection('events').add({
      'userNames': userNames,
      'startTime': '${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')}',
      'endTime': '${endTime.hour}:${endTime.minute.toString().padLeft(2, '0')}',
      'outlineColor': outlineColor.value, // Save the outline color
    });
  }

  await _loadSchedules();
  setState(() {
    _selectedDay = date; // Refresh selected day to reflect changes
  });
}


  void _showScheduleEditingDialog(Map<String, dynamic> schedule) async {
  List<Map<String, dynamic>> userList = [];
  QuerySnapshot userSnapshot = await FirebaseFirestore.instance.collection('users').get();
  userSnapshot.docs.forEach((doc) {
    userList.add({
      'id': doc.id,
      'username': doc['username'],
    });
  });

  List<String> selectedUserIds = List<String>.from(schedule['userNames']);
  TimeOfDay startTime = TimeOfDay(
    hour: int.parse(schedule['startTime'].split(':')[0]),
    minute: int.parse(schedule['startTime'].split(':')[1]),
  );
  TimeOfDay endTime = TimeOfDay(
    hour: int.parse(schedule['endTime'].split(':')[0]),
    minute: int.parse(schedule['endTime'].split(':')[1]),
  );

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Colors.black,
            title: Text(
              'Edit Schedule',
              style: TextStyle(color: Colors.amber),
            ),
            content: SingleChildScrollView(  // Allow scrolling
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Select Users:',
                    style: TextStyle(color: Colors.amber),
                  ),
                  Column(
                    children: userList.map((user) {
                      bool isSelected = selectedUserIds.contains(user['id']);
                      return CheckboxListTile(
                        value: isSelected,
                        title: Text(
                          user['username'],
                          style: TextStyle(color: Colors.white),
                        ),
                        onChanged: (bool? checked) {
                          setState(() {
                            if (checked == true) {
                              selectedUserIds.add(user['id']);
                            } else {
                              selectedUserIds.remove(user['id']);
                            }
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: Colors.amber,
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 10),
                  _buildTimePickerRow('Start Time:', startTime, (picked) {
                    if (picked != null) startTime = picked;
                  }),
                  _buildTimePickerRow('End Time:', endTime, (picked) {
                    if (picked != null) endTime = picked;
                  }),
                ],
              ),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _saveSchedule(_selectedDay, selectedUserIds, startTime, endTime, scheduleId: schedule['id']);
                },
                child: Text('Update', style: TextStyle(color: Colors.black)),
              ),
            ],
          );
        },
      );
    },
  );
}


  Future<void> _deleteSchedule(String scheduleId) async {
    CollectionReference schedulesCollection = FirebaseFirestore.instance.collection('schedules');
    DocumentReference dateDocRef = schedulesCollection.doc(_selectedDay.toIso8601String());
    await dateDocRef.collection('events').doc(scheduleId).delete();
    await _loadSchedules(); // Refresh schedule list after deletion
  }

void _showScheduleCreationDialog() async {
  List<Map<String, dynamic>> userList = [];
  QuerySnapshot userSnapshot = await FirebaseFirestore.instance.collection('users').get();
  userSnapshot.docs.forEach((doc) {
    userList.add({
      'id': doc.id,
      'username': doc['username'],
    });
  });

  List<String> selectedUserIds = [];
  TimeOfDay startTime = TimeOfDay.now();
  TimeOfDay endTime = TimeOfDay.now();

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Colors.black,
            title: Text(
              'Create Schedule',
              style: TextStyle(color: Colors.amber),
            ),
            content: SingleChildScrollView(  // Allow scrolling
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Select Users:',
                    style: TextStyle(color: Colors.amber),
                  ),
                  Column(
                    children: userList.map((user) {
                      bool isSelected = selectedUserIds.contains(user['id']);
                      return CheckboxListTile(
                        value: isSelected,
                        title: Text(
                          user['username'],
                          style: TextStyle(color: Colors.white),
                        ),
                        onChanged: (bool? checked) {
                          setState(() {
                            if (checked == true) {
                              selectedUserIds.add(user['id']);
                            } else {
                              selectedUserIds.remove(user['id']);
                            }
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: Colors.amber,
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 10),
                  _buildTimePickerRow('Start Time:', startTime, (picked) {
                    if (picked != null) startTime = picked;
                  }),
                  _buildTimePickerRow('End Time:', endTime, (picked) {
                    if (picked != null) endTime = picked;
                  }),
                ],
              ),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _saveSchedule(_selectedDay, selectedUserIds, startTime, endTime);
                },
                child: Text('Create', style: TextStyle(color: Colors.black)),
              ),
            ],
          );
        },
      );
    },
  );
}

  Widget _buildScheduleList() {
  return Expanded(
    child: _schedules[_selectedDay]?.isNotEmpty == true
        ? ListView.builder(
            itemCount: _schedules[_selectedDay]?.length ?? 0,
            itemBuilder: (context, index) {
              final schedule = _schedules[_selectedDay]![index];
              Color outlineColor = Color(schedule['outlineColor']); // Retrieve the outline color
              return Card(
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: outlineColor, width: 2), // Set the outline color
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ListTile(
                  title: Text('${schedule['userNames'].join(', ')}'),
                  subtitle: Text(
                    'Time: ${schedule['startTime']} - ${schedule['endTime']}',
                  ),
                  onTap: () => _showScheduleEditingDialog(schedule),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => _deleteSchedule(schedule['id']),
                  ),
                ),
              );
            },
          )
        : Center(child: Text('No schedules for this day')),
  );
}


  Widget _buildTimePickerRow(String label, TimeOfDay time, Function(TimeOfDay?) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.amber)),
        TextButton(
          onPressed: () async {
            final TimeOfDay? picked = await showTimePicker(
              context: context,
              initialTime: time,
              builder: (BuildContext context, Widget? child) {
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
                  child: child ?? const SizedBox(),
                );
              },
            );
            onChanged(picked);
          },
          child: Text('${time.hour}:${time.minute.toString().padLeft(2, '0')}', style: TextStyle(color: Colors.amber)),
        ),
      ],
    );
  }

  @override
    Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Calendar')),
      body: Column(
        children: [
          TableCalendar(
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            focusedDay: _focusedDay.value,
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 1, 1),
            eventLoader: (day) => _schedules[day] ?? [],
            selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay.value = focusedDay;
              });
            },
            calendarStyle: CalendarStyle(
              selectedDecoration: BoxDecoration(
                color: Colors.amber, // Change to your desired color
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Colors.blueAccent,
                shape: BoxShape.circle,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _showScheduleCreationDialog,
            child: Text('Create Schedule'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
          ),
          _buildScheduleList(),
        ],
      ),
    );
  }
}