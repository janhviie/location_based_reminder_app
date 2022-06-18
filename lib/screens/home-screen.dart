import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:location_based_reminder/models/user_model.dart';
import 'package:location_based_reminder/screens/addNote.dart';
import 'package:location_based_reminder/screens/login-screen.dart';
import 'dart:math';
import 'package:location/location.dart';
import 'package:location_based_reminder/screens/view-note.dart';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  static const String idScreen = "homescreen";

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// find locatiob

class LocationService {
  late UserLocation _currentLocation;

  var location = Location();
  StreamController<UserLocation> _locationController =
      StreamController<UserLocation>();

  Stream<UserLocation> get locationStream => _locationController.stream;

  LocationService() {
    // Request permission to use location
    location.requestPermission().then((permissionStatus) {
      if (permissionStatus == PermissionStatus.granted) {
        // If granted listen to the onLocationChanged stream and emit over our controller
        location.onLocationChanged.listen((locationData) {
          if (locationData != null) {
            _locationController.add(UserLocation(
              latitude: locationData.latitude!,
              longitude: locationData.longitude!,
            ));
          }
        });
      }
    });
  }
}

Future<UserLocation> getLocation() async {
  var location = Location();
  late UserLocation _currentLocation;
  try {
    var userLocation = await location.getLocation();
    _currentLocation = UserLocation(
      latitude: userLocation.latitude!,
      longitude: userLocation.longitude!,
    );
  } on Exception catch (e) {
    print('Could not get location: ${e.toString()}');
  }

  return _currentLocation;
}

class UserLocation {
  final double latitude;
  final double longitude;

  UserLocation({required this.latitude, required this.longitude});
}

class _HomeScreenState extends State<HomeScreen> {
  late AndroidNotificationChannel channel;

  String constructFCMPayload(String? token) {
    return jsonEncode({
      'token': token,
      'data': {
        'via': 'FlutterFire Cloud Messaging!!!',
      },
      'notification': {
        'title': 'Hello FlutterFire!',
        'body': 'This notification was created via FCM!',
      },
    });
  }

  String token_noti = "";

  createAlertDialog(BuildContext context) {
    TextEditingController locationVal = TextEditingController();
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(
              "WOHOOOOOO",
            ),
            content: TextFormField(
              controller: locationVal,
              decoration: InputDecoration(hintText: "Enter Location"),
            ),
            actions: <Widget>[
              MaterialButton(
                onPressed: () {
                  if (locationVal.text.length < 2) {
                  } else {}
                },
                elevation: 5,
                child: Text('Add'),
              )
            ],
          );
        });
  }

  void loadFCM() async {
    if (!kIsWeb) {
      channel = const AndroidNotificationChannel(
        'high_importance_channel', // id
        'High Importance Notifications', // description
        importance: Importance.high,
        playSound: true,
      );

      flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

      /// Create an Android Notification Channel.
      ///
      /// We use this channel in the `AndroidManifest.xml` file to override the
      /// default FCM channel to enable heads up notifications.
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      /// Update the iOS foreground notification presentation options to allow
      /// heads up notifications.
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  /// Initialize the [FlutterLocalNotificationsPlugin] package.
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  User? user = FirebaseAuth.instance.currentUser;
  UserModel loggedUser = UserModel();
  final Location location = Location();
  StreamSubscription<LocationData>? locationSubscription;

  CollectionReference notesRef = FirebaseFirestore.instance
      .collection("users")
      .doc(FirebaseAuth.instance.currentUser?.uid)
      .collection("notes");

  late String _error;

  _checkPermission() async {
    print("INNNNNNNNNNNNNNNN");
    final LocationData _locationData = await location.getLocation();
    PermissionStatus permissionGrantedResult = await location.hasPermission();
    PermissionStatus _permissionGranted = permissionGrantedResult;

    // setState(() {
    //   _permissionGranted = permissionGrantedResult;
    // });

    if (_permissionGranted != PermissionStatus.granted) {
      print("Permission Granted");
      PermissionStatus permissionRequestedResult =
          await location.requestPermission();
      print(permissionRequestedResult);
      setState(() {
        _permissionGranted = permissionRequestedResult;
      });
      if (permissionRequestedResult != PermissionStatus.granted) {
        return;
      } else {
        _loadLocation();
      }
    } else {
      _loadLocation();
    }
  }

  Future<void> _listenLocation() async {
    LocationData _locationData = await location.getLocation();
    locationSubscription =
        location.onLocationChanged.handleError((dynamic err) {
      locationSubscription?.cancel();
    }).listen((LocationData currentLocation) {
      if (this.mounted) {
        setState(() {
          print("From listen location");
          print(currentLocation.latitude);
          print(currentLocation.longitude);
          _error = "null";
          _locationData = currentLocation;

          Future<Null> notesRef = FirebaseFirestore.instance
              .collection("users")
              .doc(FirebaseAuth.instance.currentUser?.uid)
              .collection("notes")
              .get()
              .then((QuerySnapshot querySnapshot) {
            querySnapshot.docs.forEach((doc) {
              print(doc["title"]);
              print(doc.id);
              print(doc['locationLng']);
              print(doc['locationLat']);

              if (doc['locationLng'] != "null") {
                double? userLat = currentLocation.latitude;
                double? userLng = currentLocation.longitude;

                double reminderLat = double.parse(doc['locationLat']);
                double reminderLng = double.parse(doc['locationLng']);

                userLat = (userLat! * pi) / 100;
                userLng = (userLng! * pi) / 100;
                reminderLat = (reminderLat * pi) / 100;
                reminderLng = (reminderLng * pi) / 100;

                double dlong = reminderLng - userLng;
                double dlat = reminderLat - userLat;

                num ans = pow(sin(dlat / 2), 2) +
                    cos(userLat) * cos(reminderLat) * pow(sin(dlong / 2), 2);

                ans = 2 * asin(sqrt(ans));
                ans = ans * 6371;

                print("Distance between User and reminder: ${ans}");

                if (ans < 1.5) {
                  print("USER IS NEAR REMINDER LOCATION");
                  print(doc['title']);

                  sendNotification(
                      token_noti, doc['title'], doc['description'], context);

                  Future<void> notesRef = FirebaseFirestore.instance
                      .collection("users")
                      .doc(FirebaseAuth.instance.currentUser?.uid)
                      .collection("notes")
                      .doc(doc.id)
                      .update({'locationLng': 'null', 'locationLat': 'null'});
                } else {
                  print("USER NOT NEAR");
                }
              }
            });
          });

          // check if user in any of the reminder's locations
        });
      }
    });
  }

  void _loadLocation() async {
    LocationData _locationData = await location.getLocation();

    print("Locationnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn");
    print(_locationData.latitude);
    print(_locationData.longitude);

    _listenLocation();
  }

  CollectionReference ref = FirebaseFirestore.instance
      .collection("users")
      .doc(FirebaseAuth.instance.currentUser?.uid)
      .collection("notes");

  List<Color> myColors = [
    Colors.yellow[200]!,
    Colors.red[200]!,
    Colors.green[200]!,
    Colors.deepPurple[200]!,
  ];

  @override
  void initState() {
    super.initState();

    requestPermissionNoti();
    loadFCM();
    listenFCM();
    getToken();

    FirebaseFirestore.instance
        .collection("users")
        .doc(user!.uid)
        .get()
        .then((value) {
      this.loggedUser = UserModel.fromMap(value.data());
      setState(() {});
    });

    print("Hi");
  }

  void saveToken(String token) async {
    await FirebaseFirestore.instance
        .collection("users")
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .update({'token': token});

    print("Toekn added");
  }

  void getToken() async {
    await FirebaseMessaging.instance.getToken().then((token) {
      print(token);
      setState(() {
        token_noti = token!;
      });

      saveToken(token_noti);
    });
  }

  void requestPermissionNoti() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true);
  }

  static void sendNotification(
      String token, String title, String des, context) async {
    Map<String, String> headermap = {
      'content-type': 'application/json',
      'Authorization':
          'key=AAAAec8ze_k:APA91bE-N0DyLjsgpwN1ppPmUt_6U1oKSz1bl4pHkVslQ3lQyjFhx77pUueCDtbB7-P0X-oWNsVA3wWATMQBqonIuqsbqRKls7hey5m6EDAy9WP_MSjs9_mECyN9msh1gvBMF6K0lx-v',
    };

    Map notificationMap = {'body': des, 'title': title};

    Map dataMap = {
      'click_action': 'FLUTTER_NOTIFICATION_CLICK',
      'id': '1',
      'status': 'done',
      'ride_request_id': 'abc'
    };

    Map sendNotification = {
      "notification": notificationMap,
      "data": dataMap,
      "priority": "high",
      "to": token
    };

    final res = await http.post(
        Uri.parse("https://fcm.googleapis.com/fcm/send"),
        headers: headermap,
        body: jsonEncode(sendNotification));

    if (res.statusCode == 200) {
      print("SUCCESS SENDING NOTIGICTION");
    } else
      print("ERROR SENDING PUSH NOTIFICATION");
  }

  void listenFCM() async {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
      if (notification != null && android != null && !kIsWeb) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,

              // TODO add a proper drawable resource to android, for now using
              //      one that already exists in example app.
              icon: 'launch_background',
            ),
          ),
        );
      }
    });
  }

  Widget build(BuildContext context) {
    print("STUDPIDDDDDDDD");
    _checkPermission();

    final logoutButton = Material(
      elevation: 5,
      borderRadius: BorderRadius.circular(30),
      color: Colors.redAccent,
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "${loggedUser.name}'s Notes",
          style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w500,
              fontSize: 30,
              fontFamily: "lato"),
        ),
        centerTitle: true,
        actions: <Widget>[
          Padding(
            padding: EdgeInsets.only(right: 20.0),
            child: GestureDetector(
              onTap: () {
                logout(context);
              },
              child: Icon(
                Icons.logout,
                size: 26,
                color: Colors.black54,
              ),
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (context) => AddNote()))
              .then((value) {
            print("Calling set state");
            setState(() {});
          });
        },
        child: Icon(
          Icons.add,
          color: Colors.white,
        ),
        backgroundColor: Colors.black87,
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: ref.get(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ListView.builder(
              itemCount: snapshot.data?.docs.length,
              itemBuilder: (context, index) {
                Random random = new Random();
                Color bg = myColors[random.nextInt(4)];

                Object? list =
                    (snapshot.data?.docs[index].data() as Map<String, dynamic>);

                DateTime mydatetime = (snapshot.data?.docs[index].data()
                        as Map<String, dynamic>)['created']
                    .toDate();

                String formattedTime =
                    DateFormat.yMMMd().add_jm().format(mydatetime);

                return InkWell(
                  onTap: (() {
                    Navigator.of(context)
                        .push(MaterialPageRoute(
                            builder: (context) => ViewNote(
                                (snapshot.data?.docs[index].data()
                                    as Map<String, dynamic>),
                                formattedTime,
                                snapshot.data!.docs[index].reference)))
                        .then((value) {
                      setState(() {});
                    });
                  }),
                  child: Card(
                    color: bg,
                    child: Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${(snapshot.data?.docs[index].data() as Map<String, dynamic>)['title']}",
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w500,
                                fontFamily: "lato",
                                color: Colors.black87),
                          ),
                          Container(
                            alignment: Alignment.centerRight,
                            child: Text(
                              DateFormat.yMMMd().add_jm().format(mydatetime),
                              style: TextStyle(
                                  fontSize: 17,
                                  fontFamily: "lato",
                                  color: Colors.black87),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          } else {
            return Center(
              child: Text("Loading"),
            );
          }
        },
      ),
    );
  }

  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => LoginScreen()));
  }

  // getLoc() async {
  //   try {
  //     final LocationData locResult = await location.getLocation();
  //     print("Location..");
  //     print(locResult.latitude);
  //     print(locResult.longitude);
  //   } catch (e) {
  //     print(e);
  //   }
  // }
}
