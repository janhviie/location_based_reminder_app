import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart';

class AddNote extends StatefulWidget {
  const AddNote({Key? key}) : super(key: key);

  @override
  State<AddNote> createState() => _AddNoteState();
}

class _AddNoteState extends State<AddNote> {
  late String title;
  late String description = "";
  String api = "89963686dbb2496ab9af6a2ed8d4e3a9";
  String addReminderMsg = "Add Reminder";

  String LocationLat = "null";
  String LocationLng = "null";

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(12),
          child: Column(children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 55,
                  height: 35,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Icon(
                      Icons.arrow_back_ios_new_outlined,
                      size: 20,
                    ),
                    style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all(Colors.grey[700]),
                        padding: MaterialStateProperty.all(
                            EdgeInsets.symmetric(horizontal: 15, vertical: 8))),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      child: ElevatedButton(
                        onPressed: () {
                          createAlertDialog(context);
                        },
                        child: Text("${addReminderMsg}",
                            style: TextStyle(
                                fontSize: 18,
                                fontFamily: "lato",
                                color: Colors.white)),
                        style: ButtonStyle(
                            backgroundColor:
                                MaterialStateProperty.all(Colors.grey[700]),
                            padding: MaterialStateProperty.all(
                                EdgeInsets.symmetric(
                                    horizontal: 15, vertical: 8))),
                      ),
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    ElevatedButton(
                      onPressed: add,
                      child: Text(
                        "Save",
                        style: TextStyle(
                            fontSize: 18,
                            fontFamily: "lato",
                            color: Colors.white),
                      ),
                      style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all(Colors.grey[700]),
                          padding: MaterialStateProperty.all(
                              EdgeInsets.symmetric(
                                  horizontal: 15, vertical: 8))),
                    )
                  ],
                )
              ],
            ),
            SizedBox(height: 12),
            Form(
                child: Column(
              children: [
                Form(
                    child: Column(
                  children: [
                    TextFormField(
                      decoration: InputDecoration.collapsed(hintText: "Title"),
                      style: TextStyle(
                          fontSize: 32,
                          fontFamily: "lato",
                          fontWeight: FontWeight.bold,
                          color: Colors.black54),
                      onChanged: (_val) {
                        title = _val;
                      },
                    ),
                    Container(
                      height: MediaQuery.of(context).size.height * 0.75,
                      padding: const EdgeInsets.only(top: 12),
                      child: TextFormField(
                        decoration: InputDecoration.collapsed(
                            hintText: "Reminder Description"),
                        style: TextStyle(
                            fontSize: 20,
                            fontFamily: "lato",
                            color: Colors.black54),
                        onChanged: (_val) {
                          description = _val;
                        },
                        maxLines: 20,
                      ),
                    ),
                  ],
                ))
              ],
            ))
          ]),
        ),
      ),
    ));
  }

  // add note

  void add() async {
    CollectionReference ref = FirebaseFirestore.instance
        .collection("users")
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .collection("notes");

    var data = {
      'title': title,
      'description': description,
      'created': DateTime.now(),
      'locationLat': LocationLat,
      'locationLng': LocationLng
    };

    ref.add(data);

    Navigator.pop(context);
  }

  // creating add location dialog

  createAlertDialog(BuildContext context) {
    TextEditingController locationVal = TextEditingController();
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(
              "A Reminder will be notified when you reach this location !",
            ),
            content: TextFormField(
              controller: locationVal,
              decoration: InputDecoration(hintText: "Enter Location"),
            ),
            actions: <Widget>[
              MaterialButton(
                onPressed: () {
                  if (locationVal.text.length < 2) {
                    displayToastMessage(
                        "Empty location not allowed !", context);
                  } else {
                    saveLocToDB(locationVal.text);
                  }
                },
                elevation: 5,
                child: Text('Add'),
              )
            ],
          );
        });
  }

  void displayToastMessage(String message, BuildContext context) {
    Fluttertoast.showToast(msg: message);
  }

  saveLocToDB(String loc) async {
    print(loc);

    final response = await get(Uri.parse(
        'https://api.opencagedata.com/geocode/v1/json?q=${loc}&key=${api}&language=en&pretty=1'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print("Json data received");
      String locLat = data["results"][0]["geometry"]["lat"].toString();
      String locLong = data["results"][0]["geometry"]["lng"].toString();

      print("Location lat ${locLat}");
      print("Location lng ${locLong}");
      LocationLat = locLat;
      LocationLng = locLong;
      displayToastMessage("Location Added", context);
      Navigator.pop(context);
    } else {
      displayToastMessage("Enter Valid Locationn!!", context);
    }
    // addReminderMsg = "Update Location";
    // setState(() {});
    // Navigator.pop(context);
  }
}
