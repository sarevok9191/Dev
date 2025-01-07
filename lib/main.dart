import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:my_app/push_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.web,);
  FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  ).then((settings) {
    print('User granted permission: ${settings.authorizationStatus}');
  });

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
  String loggedInUser = '';
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
  } else if (username == 'Fero' && password == '123') {
    loggedInTrainer = 'Fero';
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => TrainerScreen(loggedInTrainer: loggedInTrainer)),
    );
  } else {
    List<Map<String, dynamic>> userCredentials = await getUserCredentials();
    bool loginSuccess = false;

    for (var user in userCredentials) {
      if (username == user['username'] && password == user['password']) {
        loginSuccess = true;
        loggedInUser = user['username'];

        // Get FCM token for logged-in user
        String? fcmToken = await FirebaseMessaging.instance.getToken();
        

        // Query Firestore to find the document by username
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('username', isEqualTo: loggedInUser)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          String documentId = querySnapshot.docs.first.id;  // Get the document ID
          
          // Store the FCM token in Firestore
          await FirebaseFirestore.instance.collection('users').doc(documentId).update({
            'fcmToken': fcmToken,
          });
          // Pass 'user' and 'loggedInUser' to UserScreen constructor
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => UserScreen({
                'fcmToken': user['fcmToken'],
                'username': loggedInUser,
                'sessionCount': user['sessionCount'],
                'loggedInTrainer': 'N/A', // Or pass the correct loggedInTrainer if needed
                
              }, loggedInUser),
            ),
          );
          
        }
        print("FCM Token: $fcmToken");
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

  TrainerScreen({Key? key, required this.loggedInTrainer}) : super(key: key);
 
  @override
  _TrainerScreenState createState() => _TrainerScreenState(loggedInTrainer);
}

class _TrainerScreenState extends State<TrainerScreen> {
  List<Map<String, dynamic>> users = [];
  String loggedInTrainer = "";
_TrainerScreenState(this.loggedInTrainer);


  @override
  void initState() {
    super.initState();
    _loadUsers();
  }




// Save session and handle document not found gracefully
/*Future<void> saveSession(String userId, Map<String, dynamic> sessionData) async {
  try {
    await FirebaseFirestore.instance
        .collection('sessions')
        .doc(userId)
        .update(sessionData);
    debugPrint("Session updated successfully.");
  } catch (e) {
    debugPrint("Error updating session in Firestore: $e");
    if (e.toString().contains('not-found')) {
      debugPrint("Document not found for user $userId. Ensure the document exists.");
    }
  }
}*/


  
  



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
      'fcmToken': '',
    });
    _loadUsers(); // Reload users after creating a new one
  }

  void _showUserCreationDialog() {
    String newUsername = '';
    String newPassword = '';
    int newSessionCount = 0;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Crecdate User'),
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

  Future<void> _deleteUser(String userId) async {
    CollectionReference usersCollection = FirebaseFirestore.instance.collection('users');
    await usersCollection.doc(userId).delete();
    _loadUsers(); // Reload users after deletion
  }



Future<void> sendNotificationAfterEditingSession(String userId) async {
  try {
    // Fetch user document
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();

        if (userDoc.exists) {
  final fcmToken = userDoc['fcmToken']; // Ensure this matches the exact Firestore field name
  if (fcmToken != null && fcmToken.isNotEmpty) {
    debugPrint("FCM Token fetched: $fcmToken");
    // Continue with sending the notification
  } else {
    debugPrint("FCM Token is missing or empty for user $userId.");
  }
} else {
  debugPrint("User document does not exist for ID: $userId.");
}

    if (userDoc.exists) {
      final sessionCount = userDoc['sessionCount'] ?? 0;
      final fcmToken = userDoc['fcmToken'];

      if (fcmToken != null && fcmToken.isNotEmpty) {
        try {
          // Ensure proper private key formatting
          await PushNotificationService.sendNotification(
            deviceToken: fcmToken,
            title: "Session Updated",
            body: "Your session count is now $sessionCount.",
          );
          debugPrint("Notification sent successfully to $userId.");
        } catch (e) {
          debugPrint("Error in sendNotification: $e");
        }
      } else {
        debugPrint("No FCM token found for user $userId.");
      }
    } else {
      debugPrint("User document does not exist for ID $userId.");
    }
  } catch (e) {
    debugPrint("Error fetching user data: $e");
  }
}


Future<void> _editUserSessions(String userId, int sessionCount) async {
  // Update the session count in Firestore
  await FirebaseFirestore.instance.collection('users').doc(userId).update({
    'sessionCount': sessionCount,
    
  });
  

  _loadUsers(); // Reload users after editing
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
                onPressed: ()async {
                  Navigator.pop(context);
                  _editUserSessions(userId, sessionCount); // Save session changes
                 // _updateSessionInFirestore(userId, sessionCount); // Update Firestore and set notification flag
                  await sendNotificationAfterEditingSession(userId);
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
                  MaterialPageRoute(builder: (context) => CalendarScreen(loggedInTrainer:loggedInTrainer)),
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
  final Map<String, dynamic> user; // The user data map
  final String loggedInUser; // The username of the logged-in user

  UserScreen(this.user, this.loggedInUser); // Constructor with two positional arguments

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center, // Center IconButton horizontally
          children: [
            IconButton(
              icon: Icon(Icons.calendar_today),
              onPressed: () {
                // Navigate to CalendarScreen and pass the 'loggedInUser' for filtering
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserCalendarScreen(username: loggedInUser),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: CustomPaint(
          size: Size(200, 200), // Specify the size of the circle
          painter: StrokedGlowCirclePainter(),
          child: Container(
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Remaining Sessions:',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  '${user['sessionCount']}', // Displays the session count in digital font
                  style: TextStyle(
                    fontSize: 70,
                    fontFamily: 'Digital', // Ensure this matches your font name in pubspec.yaml
                    color: Colors.amber, // Example color
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class StrokedGlowCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 4;

    // Draw the stroked glow
    final Paint glowStrokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12.0 // Width of the glow stroke
      ..color = Colors.yellow.withOpacity(0.5) // Glow color with transparency
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 15); // Glow blur

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2), // Center of the circle
      radius - glowStrokePaint.strokeWidth / 2, // Adjust radius for stroke alignment
      glowStrokePaint,
    );

    // Draw the stroked circle
    final Paint strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..color = Colors.yellow;

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2), // Center of the circle
      radius - strokePaint.strokeWidth, // Adjust radius for the top stroke
      strokePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}







class CalendarScreen extends StatefulWidget {

 final String? username; // Optional username parameter for filtering
  final String loggedInTrainer;


  CalendarScreen({Key? key,this.username, required this.loggedInTrainer}) : super(key: key);

  @override
  _CalendarScreenState createState() => _CalendarScreenState(loggedInTrainer);
}

class _CalendarScreenState extends State<CalendarScreen> {
  Map<DateTime, List<Map<String, dynamic>>> _schedules = {};
  DateTime _selectedDay = DateTime.now();
  late final ValueNotifier<DateTime> _focusedDay;
  String loggedInTrainer = "";
  String type = '';
_CalendarScreenState(this.loggedInTrainer);

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
        Map<String, dynamic>? eventData = event.data() as Map<String, dynamic>?;
        String loggedInTrainer = eventData?.containsKey('createdBy') == true
            ? event['createdBy']
            : 'Unknown Trainer'; // Default value in case the field is missing

        // Ensure that the 'type' field is properly retrieved here
        String type = eventData?['type'] ?? 'Unknown'; // Retrieve type from event data

        _schedules[date]?.add({
          'id': event.id, // Store the schedule ID
          'userNames': List<String>.from(event['userNames']),
          'startTime': event['startTime'],
          'endTime': event['endTime'],
          'createdBy': loggedInTrainer,
          'type': type, // Store the 'type' field from Firestore
        });
      }
    });
  }
}


Future<void> _saveSchedule({
  required DateTime date,
  required List<String> selectedUserIds,
  required TimeOfDay startTime,
  required TimeOfDay endTime,
  required String createdBy, // Existing parameter for the creator
  String? scheduleId,         // Optional schedule ID
  required String type,       // Type parameter
}) async {
    CollectionReference schedulesCollection = FirebaseFirestore.instance.collection('schedules');
    DocumentReference dateDocRef = schedulesCollection.doc(date.toIso8601String());

    // Check if the document for this date exists, and create it if not
    DocumentSnapshot dateDoc = await dateDocRef.get();
    if (!dateDoc.exists) {
      await dateDocRef.set({'placeholder': true}); // Creates the doc with a placeholder field
    }

    // Proceed to add event in the 'events' subcollection of the date document
    CollectionReference eventsCollection = dateDocRef.collection('events');

    List<String> userNames = [];
    for (String userId in selectedUserIds) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (userDoc.exists) {
        userNames.add(userDoc['username']);
      } else {
        print('User document for $userId does not exist.');
      }
    }

    if (scheduleId != null) {
      // If editing, update the existing schedule
      await eventsCollection.doc(scheduleId).update({
        'userNames': userNames,
        'startTime': '${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')}',
        'endTime': '${endTime.hour}:${endTime.minute.toString().padLeft(2, '0')}',
        'createdBy': loggedInTrainer,
        'type' :type
      });
    } else {
      // Otherwise, create a new event
      await eventsCollection.add({
        'userNames': userNames,
        'startTime': '${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')}',
        'endTime': '${endTime.hour}:${endTime.minute.toString().padLeft(2, '0')}',
        'createdBy': loggedInTrainer,
        'type' :type
      });
    }

    // Reload schedules after saving
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
                  if (type.isNotEmpty) {
                    type = type.substring(0, type.length - 2); // Remove trailing comma and space
                  }
                  
                  Navigator.pop(context);
                  _saveSchedule(
                    date: _selectedDay,
                    selectedUserIds: selectedUserIds,
                    startTime: startTime,
                    endTime: endTime,
                    createdBy: loggedInTrainer,
                    type: type,
                  );
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


  Future<void> _deleteSchedule(String scheduleId) async {
    CollectionReference schedulesCollection = FirebaseFirestore.instance.collection('schedules');
    DocumentReference dateDocRef = schedulesCollection.doc(_selectedDay.toIso8601String());
    await dateDocRef.collection('events').doc(scheduleId).delete();
    await _loadSchedules(); // Refresh schedule list after deletion
  }

void _showScheduleCreationDialog(String loggedInTrainer) async {
  List<Map<String, dynamic>> userList = [];
  List<Map<String, dynamic>> filteredUsers = [];
  TextEditingController searchController = TextEditingController();

  bool isFSelected = false;
  bool isSSelected = false;
  bool isPSelected = false;

  // Load users from Firestore
  QuerySnapshot userSnapshot = await FirebaseFirestore.instance.collection('users').get();
  userSnapshot.docs.forEach((doc) {
    userList.add({'id': doc.id, 'username': doc['username']});
  });

  filteredUsers = List.from(userList); // Initially show all users
  List<String> selectedUserIds = []; // Correct variable name
  TimeOfDay startTime = TimeOfDay.now();
  TimeOfDay endTime = TimeOfDay.now();

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          void filterUsers(String query) {
            setState(() {
              filteredUsers = userList.where((user) {
                return user['username'].toLowerCase().contains(query.toLowerCase());
              }).toList();
            });
          }

          return AlertDialog(
            backgroundColor: Colors.black,
            title: Text(
              'Create Schedule',
              style: TextStyle(color: Colors.amber),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // F, S, P selection in a row (moved before Start Time)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // F selection
                      Row(
                        children: [
                          Text(
                            "F",
                            style: TextStyle(color: Colors.white),
                          ),
                          Checkbox(
                            value: isFSelected,
                            onChanged: (bool? value) {
                              setState(() {
                                isFSelected = value ?? false;
                              });
                            },
                            activeColor: Colors.amber,
                          ),
                        ],
                      ),
                      // S selection
                      Row(
                        children: [
                          Text(
                            "S",
                            style: TextStyle(color: Colors.white),
                          ),
                          Checkbox(
                            value: isSSelected,
                            onChanged: (bool? value) {
                              setState(() {
                                isSSelected = value ?? false;
                              });
                            },
                            activeColor: Colors.amber,
                          ),
                        ],
                      ),
                      // P selection
                      Row(
                        children: [
                          Text(
                            "P",
                            style: TextStyle(color: Colors.white),
                          ),
                          Checkbox(
                            value: isPSelected,
                            onChanged: (bool? value) {
                              setState(() {
                                isPSelected = value ?? false;
                              });
                            },
                            activeColor: Colors.amber,
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  // Time Pickers
                  _buildTimePickerRow('Start Time:', startTime, (picked) {
                    if (picked != null) setState(() => startTime = picked);
                  }),
                  _buildTimePickerRow('End Time:', endTime, (picked) {
                    if (picked != null) setState(() => endTime = picked);
                  }),
                  // Search Bar for Users
                  TextField(
                    controller: searchController,
                    onChanged: filterUsers,
                    decoration: InputDecoration(
                      hintText: 'Search users',
                      hintStyle: TextStyle(color: Colors.white54),
                      prefixIcon: Icon(Icons.search, color: Colors.amber),
                      enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.amber)),
                      focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.amber)),
                    ),
                    style: TextStyle(color: Colors.white),
                  ),
                  SizedBox(height: 10),
                  // User Selection with Checkboxes
                  Column(
                    children: filteredUsers.map((user) {
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
                ],
              ),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                ),
                onPressed: () {
                  String type = '';
                  if (isFSelected) type += 'F, ';
                  if (isSSelected) type += 'S, ';
                  if (isPSelected) type += 'P, ';
                  if (type.isNotEmpty) {
                    type = type.substring(0, type.length - 2); // Remove trailing comma and space
                  }

                  Navigator.pop(context);
                  _saveSchedule(
                    date: _selectedDay,
                    selectedUserIds: selectedUserIds,
                    startTime: startTime,
                    endTime: endTime,
                    createdBy: loggedInTrainer,
                    type: type, // Added type here
                  );
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
              
              // Determine the border color based on the createdBy field
              Color borderColor = Colors.grey; // Default color
              String createdBy = schedule['createdBy'] ?? 'Unknown';
              //String type = schedule['type'] ?? 'Unknown';

              if (createdBy == 'Sulo') {
                borderColor = Colors.yellow;
              } else if (createdBy == 'Fero') {
                borderColor = Colors.red;
              }

              return Card(
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: borderColor, width: 2), // Set border color here
                  borderRadius: BorderRadius.circular(8), // Optional: set border radius for rounded corners
                ),
                child: ListTile(
                  title: Text('${schedule['userNames'].join(', ')}'),
                  subtitle: Text('Time: ${schedule['startTime']} - ${schedule['endTime']} - ${schedule['type'] ?? 'No Type'}'),
 // Added type after endTime
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



  Widget _buildTimePickerRow(String label, TimeOfDay time, Function(TimeOfDay?) onTimeChanged) {
  return Row(
    children: [
      Text(
        label,
        style: TextStyle(color: Colors.amber),
      ),
      IconButton(
        icon: Icon(Icons.access_time, color: Colors.amber),
        onPressed: () async {
          TimeOfDay? picked = await showTimePicker(
            context: context,
            initialTime: time,
          );
          if (picked != null) onTimeChanged(picked);
        },
      ),
      Text(
        time.format(context),
        style: TextStyle(color: Colors.amber),
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
            onPressed: () {
    _showScheduleCreationDialog(loggedInTrainer); // Executes inside the anonymous function
  },
            child: Text('Create Schedule'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
          ),
          _buildScheduleList(),
        ],
      ),
    );
  }
}

class UserCalendarScreen extends StatefulWidget {
  final String? username; // Optional username parameter for filtering

  UserCalendarScreen({Key? key, this.username}) : super(key: key);

  @override
  _UserCalendarScreenState createState() => _UserCalendarScreenState();
}

class _UserCalendarScreenState extends State<UserCalendarScreen> {
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
          Map<String, dynamic>? eventData = event.data() as Map<String, dynamic>?;

          // Filter based on the logged-in user's username
          List<String> userNames = List<String>.from(event['userNames']);
          if (userNames.contains(widget.username)) { // Only include if username matches
            String loggedInTrainer = eventData?.containsKey('createdBy') == true
                ? event['createdBy']
                : 'Unknown Trainer';

            _schedules[date]?.add({
              'id': event.id, // Store the schedule ID
              'userNames': userNames,
              'startTime': event['startTime'],
              'endTime': event['endTime'],
              'createdBy': loggedInTrainer
              
            });
          }
        }
      });
    }
  }

  Widget _buildScheduleList() {
    return Expanded(
      child: _schedules[_selectedDay]?.isNotEmpty == true
          ? ListView.builder(
              itemCount: _schedules[_selectedDay]?.length ?? 0,
              itemBuilder: (context, index) {
                final schedule = _schedules[_selectedDay]![index];
                
                // Determine the border color based on the createdBy field
                Color borderColor = Colors.grey; // Default color
                String createdBy = schedule['createdBy'] ?? 'Unknown';
                

                if (createdBy == 'Sulo') {
                  borderColor = Colors.yellow;
                } else if (createdBy == 'Fero') {
                  borderColor = Colors.red;
                }

                return Card(
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: borderColor, width: 2), // Set border color here
                    borderRadius: BorderRadius.circular(8), // Optional: set border radius for rounded corners
                  ),
                  child: ListTile(
                    title: Text('${schedule['userNames'].join(', ')}'),
                    subtitle: Text(
                      'Time: ${schedule['startTime']} - ${schedule['endTime']}',
                    ),
                  ),
                );
              },
            )
          : Center(child: Text('No schedules for this day')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('User Calendar')),
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
          _buildScheduleList(),
        ],
      ),
    );
  }
}