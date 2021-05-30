import 'package:flutter/foundation.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'video.dart';

final geo = Geoflutterfire();
final _firestore = FirebaseFirestore.instance;
// Init firestore and geoFlutterFire

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return MaterialApp(
          title: 'DocFinder',
          theme: ThemeData(
            primarySwatch: Colors.blue,
          ),
          home: MyHomePage(title: 'DocFinder'),
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _initialized = false;
  bool _error = false;
  dynamic userLoc;
  dynamic documentList;
  String _role = 'ENT';
  dynamic apiROle = null;
  String _km = '5';
  String searchText = '';

  getloc() async {
    await Geolocator.getCurrentPosition().then((value) => {
          setState(
            () {
              userLoc = value;
            },
          ),
        });
  }

  getDistance(dynamic docLoc) {
    return Geolocator.distanceBetween(userLoc.latitude, userLoc.longitude,
            docLoc.latitude, docLoc.longitude) /
        1000;
  }

  void initializeFlutterFire() async {
    try {
      getloc();
      // Wait for Firebase to initialize and set `_initialized` state to true
      await Firebase.initializeApp();
      setState(() {
        _initialized = true;
      });
    } catch (e) {
      // Set `_error` state to true if Firebase initialization fails
      setState(() {
        _error = true;
      });
    }
  }

  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    initializeFlutterFire();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (_initialized && userLoc != null) {
      GeoFirePoint center =
          geo.point(latitude: userLoc.latitude, longitude: userLoc.longitude);

      double distancez = num.parse(_km) / 3;

      double lat = 0.023323826086956514;
      double lon = 0.02926080000000002776;

      double lowerLat = center.latitude - (lat * distancez);
      double lowerLon = center.longitude - (lon * distancez);

      double greaterLat = center.latitude + (lat * distancez);
      double greaterLon = center.longitude + (lon * distancez);

      GeoPoint lesserGeoPoint = GeoPoint(lowerLat, lowerLon);
      GeoPoint greaterGeoPoint = GeoPoint(greaterLat, greaterLon);
      Stream<QuerySnapshot> stream;
      dynamic query = _firestore
          .collection("doctors")
          .where("location", isGreaterThan: lesserGeoPoint)
          .where("location", isLessThan: greaterGeoPoint);

      stream = query.snapshots();
      if (searchText.trim() != '') {
        stream = query.where("name", isEqualTo: searchText).snapshots();
      }
      if (apiROle != null) {
        stream = query.where("role", isEqualTo: apiROle).snapshots();
      }

      final Stream<QuerySnapshot> roloz =
          _firestore.collection("roles").snapshots();

      return Scaffold(
        resizeToAvoidBottomInset: false,
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: const <Widget>[
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Color(0xAA6F6F6F),
                ),
                child: Text(
                  'DocFinder',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.video_call),
                title: Text('Video Call'),
              ),
              ListTile(
                leading: Icon(Icons.account_circle),
                title: Text('Profile'),
              ),
              ListTile(
                leading: Icon(Icons.settings),
                title: Text('Settings'),
              ),
            ],
          ),
        ),
        appBar: AppBar(
          backgroundColor: Color(0xAA6F6F6F),
          title: Text(widget.title),
          actions: [
            TextButton(
                onPressed: () => {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => VideoCallPage()),
                      )
                    },
                child: Text('Video Call'))
          ],
        ),
        body: Center(
          child: _initialized && userLoc != null
              ? StreamBuilder(
                  stream: stream,
                  builder: (BuildContext context,
                      AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (!snapshot.hasData) {
                      return Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    return Stack(
                      alignment: AlignmentDirectional.center,
                      children: <Widget>[
                        Container(
                            alignment: FractionalOffset(0.0, 0.0),
                            child: Row(children: [
                              Expanded(
                                  flex: 9,
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 16),
                                    child: TextField(
                                      controller: _controller,
                                      autofocus: false,
                                      decoration: InputDecoration(
                                        fillColor: Color(0xAAE8E8E8),
                                        border: OutlineInputBorder(),
                                        hintText: 'Find Doctors',
                                        suffixIcon: IconButton(
                                          onPressed: () => {
                                            setState(() {
                                              searchText = '';
                                            }),
                                            _controller.clear()
                                          },
                                          icon: Icon(Icons.clear),
                                        ),
                                      ),
                                    ),
                                  )),
                              Expanded(
                                  flex: 1,
                                  child: IconButton(
                                      color: Color(0xAA6F6F6F),
                                      padding: EdgeInsets.all(0),
                                      onPressed: () {
                                        setState(() {
                                          searchText = _controller.text;
                                        });
                                      },
                                      icon: Icon(Icons.search))),
                            ])),
                        Container(
                            padding: EdgeInsets.all(1.w),
                            alignment: FractionalOffset(0.0, 0.1),
                            child: StreamBuilder(
                                stream: roloz,
                                builder: (BuildContext context,
                                    AsyncSnapshot<QuerySnapshot> rolezoz) {
                                  if (!rolezoz.hasData) {
                                    return Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }
                                  return Row(children: [
                                    Expanded(flex: 2, child: Text('Role')),
                                    Expanded(
                                      flex: 5,
                                      child: DropdownButton<String>(
                                        value: _role,
                                        elevation: 16,
                                        style: const TextStyle(
                                            color: Colors.deepPurple),
                                        onChanged: (String? newValue) {
                                          setState(() {
                                            // apiROle = apiROle;
                                            _role = newValue!;
                                          });
                                        },
                                        items: rolezoz.data!.docs.map((dz) {
                                          // print(dz.id);
                                          return DropdownMenuItem<String>(
                                            value: dz["role"],
                                            onTap: () {
                                              setState(() {
                                                apiROle = dz.reference;
                                              });
                                            },
                                            child: Text(dz["role"]),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                    Expanded(flex: 2, child: Text('KM')),
                                    Expanded(
                                        flex: 5,
                                        child: DropdownButton<String>(
                                          value: _km,
                                          elevation: 16,
                                          style: const TextStyle(
                                              color: Colors.deepPurple),
                                          onChanged: (String? nyew) {
                                            setState(() {
                                              _km = nyew!;
                                              distancez =
                                                  num.parse(nyew).toDouble() /
                                                      3;
                                            });
                                          },
                                          items: <num>[5, 10, 20]
                                              .map<DropdownMenuItem<String>>(
                                                  (num value) {
                                            return DropdownMenuItem<String>(
                                              value: value.toString(),
                                              child: Text(
                                                  value.toString() + ' km'),
                                            );
                                          }).toList(),
                                        )),
                                  ]);
                                })),
                        Container(
                          width: 30.w,
                          height: 30.h,
                          alignment: FractionalOffset(0.0, 0.0),
                          decoration: BoxDecoration(
                            color: Color(0xAAA9A9A9),
                            border: Border.all(
                              color: Color(0xAAA9A9A9).withOpacity(0.5),
                              width: 3.0,
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Container(
                          width: 60.w,
                          height: 60.h,
                          alignment: FractionalOffset(0.0, 0.0),
                          decoration: BoxDecoration(
                            color: Color(0xAAE4E4E4),
                            border: Border.all(
                              color: Color(0xAAA9A9A9).withOpacity(0.5),
                              width: 3.0,
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Container(
                          width: 90.w,
                          height: 90.h,
                          alignment: FractionalOffset(0.0, 0.0),
                          decoration: BoxDecoration(
                            color: Color(0xAAEFEFEF),
                            border: Border.all(
                              color: Color(0xAAA9A9A9).withOpacity(0.5),
                              width: 3.0,
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),
                        ListView(
                          scrollDirection: Axis.horizontal,
                          shrinkWrap: true,
                          children: snapshot.data!.docs.map((document) {
                            GeoPoint docLoc = document["location"] as GeoPoint;
                            double distance = getDistance(docLoc) * -0.05;

                            bool abc = num.parse(_km) > getDistance(docLoc);

                            return abc
                                ? Container(
                                    alignment: Alignment(distance, distance),
                                    child: IconButton(
                                      padding: EdgeInsets.all(0),
                                      onPressed: () {},
                                      icon: CircleAvatar(
                                        radius: 100,
                                        backgroundImage:
                                            NetworkImage(document["pic"]),
                                        child: Text(document["name"],
                                            style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 17,
                                                fontWeight: FontWeight.bold)),
                                      ),
                                    ))
                                : Container();
                          }).toList(),
                        )
                      ],
                    );
                  })
              : CircularProgressIndicator(),
        ),
      );
    }
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Color(0xAA6F6F6F),
          title: Text(widget.title),
        ),
        body: Container());
  }
}
