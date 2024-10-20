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
  TextEditingController _usernameController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  String errorMessage = '';

  Future<void> _login() async {
    String username = _usernameController.text;
    String password = _passwordController.text;

    if (username == 'Sulo' && password == '123') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => TrainerScreen()),
      );
    } else {
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
        title: Text('Trainer Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CalendarScreen()),
              );
            },
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
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  Map<DateTime, List<Map<String, dynamic>>> _schedules = {};
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
  CollectionReference schedulesCollection = FirebaseFirestore.instance.collection('schedules');
  QuerySnapshot snapshot = await schedulesCollection.get();
  setState(() {
    _schedules = {};
    snapshot.docs.forEach((doc) {
      DateTime date = DateTime.parse(doc.id); // Assuming doc ID is the date
      if (_schedules[date] == null) _schedules[date] = [];
      _schedules[date]?.add({
        'userName': doc['userName'],
        'startTime': doc['startTime'],
        'endTime': doc['endTime'],
      });
    });
  });
}


  Future<void> _saveSchedule(DateTime date, String userId, TimeOfDay startTime, TimeOfDay endTime) async {
  CollectionReference schedulesCollection = FirebaseFirestore.instance.collection('schedules');
  DocumentReference scheduleDoc = schedulesCollection.doc(date.toIso8601String());
  DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
  String userName = userDoc['username'];

  await scheduleDoc.set({
    'userName': userName,
    'startTime': '${startTime.hour}:${startTime.minute}',
    'endTime': '${endTime.hour}:${endTime.minute}',
  });

  _loadSchedules(); // Reload after saving
}


  void _showScheduleCreationDialog() async {
  // Fetch users from Firestore
  List<Map<String, dynamic>> userList = [];
  QuerySnapshot userSnapshot = await FirebaseFirestore.instance.collection('users').get();
  userSnapshot.docs.forEach((doc) {
    userList.add({
      'id': doc.id,
      'username': doc['username'],
    });
  });

  // Variables for schedule creation
  String selectedUserId = userList.isNotEmpty ? userList[0]['id'] : '';
  TimeOfDay startTime = TimeOfDay.now();
  TimeOfDay endTime = TimeOfDay.now();

  // Show dialog for creating a schedule
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Create Schedule'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButton<String>(
              value: selectedUserId,
              onChanged: (String? newValue) {
                setState(() {
                  selectedUserId = newValue!;
                });
              },
              items: userList.map<DropdownMenuItem<String>>((user) {
                return DropdownMenuItem<String>(
                  value: user['id'],
                  child: Text(user['username']),
                );
              }).toList(),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Start Time:'),
                IconButton(
                  icon: Icon(Icons.access_time),
                  onPressed: () async {
                    startTime = (await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    ))!;
                  },
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('End Time:'),
                IconButton(
                  icon: Icon(Icons.access_time),
                  onPressed: () async {
                    endTime = (await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    ))!;
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
              _saveSchedule(_selectedDay, selectedUserId, startTime, endTime);
            },
            child: Text('Save'),
          ),
        ],
      );
    },
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Calendar'),
      ),
      body: Column(
        children: [
          TableCalendar(
            focusedDay: _selectedDay,
            firstDay: DateTime(2020),
            lastDay: DateTime(2030),
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
              });
            },
            eventLoader: (day) => _schedules[day] ?? [],
          ),
          if (_schedules[_selectedDay] != null)
            ..._schedules[_selectedDay]!.map((schedule) {
              return ListTile(
                title: Text('${schedule['userName']}'),
                subtitle: Text('Start: ${schedule['startTime']} - End: ${schedule['endTime']}'),
              );
            }).toList(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showScheduleCreationDialog,
        child: Icon(Icons.add),
      ),
    );
  }
}
