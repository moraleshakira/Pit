import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:mob_pit/contacts.dart';
import 'package:mob_pit/helper.dart';
import 'package:mob_pit/add_contacts.dart';
import 'package:sqflite/sqflite.dart';
import 'package:url_launcher/url_launcher.dart';
import './helper.dart';
import 'package:geolocator/geolocator.dart';

class Demo extends StatefulWidget {
  Demo({Key? key}) : super(key: key);

  @override
  _DemoState createState() => _DemoState();
}

class _DemoState extends State<Demo> {
  @override
  void initState() {
    getLoc();
    super.initState();
  }

  void getLoc() async {
    Position location = await _determinePosition();
    List<Placemark> placemarks = await placemarkFromCoordinates(
      location.latitude,
      location.longitude,
    );

    // Extract the address components as needed
    String? administrativeArea = placemarks.first.administrativeArea;
    String? subAdministrativeArea = placemarks.first.subAdministrativeArea;
    String? locality = placemarks.first.locality;
    String? subLocality = placemarks.first.subLocality;
    String address =
        "${administrativeArea ?? ''} ${subAdministrativeArea ?? ''} ${locality ?? ''} ${subLocality ?? ''}";
    setState(() {
      _addressController.text = address;
    });
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }

  List<Contact> contacts = [];

  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _addressController = TextEditingController();

  int index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Contacts'),
      ),
      //add Future Builder to get contacts
      body: FutureBuilder<List<Contact>>(
        future: DBHelper.readContacts(), //read contacts list here
        builder: (BuildContext context, AsyncSnapshot<List<Contact>> snapshot) {
          //if snapshot has no data yet
          if (!snapshot.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  CircularProgressIndicator(),
                  SizedBox(
                    height: 20,
                  ),
                  Text('Loading...'),
                ],
              ),
            );
          }
          //if snapshot return empty [], show text
          //else show contact list
          return snapshot.data!.isEmpty
              ? AlertDialog(
            title: Text('Hello User please Register Your Identity'),
            content: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    _buildTextField(_nameController, 'Name'),
                    SizedBox(height: 30),
                    _buildTextField(_contactController, 'Contact'),
                    SizedBox(height: 20),
                    _buildTextField(_addressController, 'Address'),
                    SizedBox(height: 20),
                    ElevatedButton(
                      // This button is pressed to add contact
                      onPressed: () async {
                        // If contact has data, then update existing list
                        // according to id, else create a new contact

                        await DBHelper.createContacts(Contact(
                          name: _nameController.text,
                          contact: _contactController.text,
                          address: _addressController.text,
                        ));

                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (BuildContext context) =>
                                super.widget));
                      },
                      child: Text('Save'),
                    ),
                  ],
                )),
          )
              : ListView(
            children: snapshot.data!.map((contacts) {
              return Center(
                child: ListTile(
                  title: snapshot.data!.first.name == contacts.name
                      ? Text("${contacts.name} (You)")
                      : Text(contacts.name),
                  subtitle: Text(contacts.contact),
                  trailing: snapshot.data!.first.name != contacts.name &&
                      snapshot.data!.length > 1 ||
                      snapshot.data!.length == 1
                      ? IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () async {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('Delete contact'),
                            content: Text('Are you sure you want'
                                ' to delete this contact?'),
                            actionsAlignment:
                            MainAxisAlignment.spaceBetween,
                            actions: <Widget>[
                              TextButton(
                                  onPressed: () async {
                                    Database db =
                                    await DBHelper.initDB();
                                    db.rawDelete(
                                        'DELETE FROM contacts where id ="${contacts.id}"');
                                    Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                            builder: (BuildContext
                                            context) =>
                                            super.widget));
                                  },
                                  child: const Text('Delete')),
                              TextButton(
                                child: Text('Cancel'),
                                onPressed: () {
                                  Navigator.of(context).pop(false);
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                  )
                      : null,
                  onTap: () async {
                    //tap on ListTile, for update
                    final refresh = await Navigator.of(context)
                        .push(MaterialPageRoute(
                        builder: (_) => AddContacts(
                          index: snapshot.data!.first.name ==
                              contacts.name
                              ? 0
                              : null,
                          contact: Contact(
                            id: contacts.id,
                            name: contacts.name,
                            contact: contacts.contact,
                            address: contacts.address,
                          ),
                        )));
                    if (refresh! && refresh != null) {
                      setState(() {
                        //if return true, rebuild whole widget
                      });
                    }
                  },
                ),
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () async {
          final refresh = await Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => AddContacts()));

          if (refresh) {
            setState(() {
              //if return true, rebuild whole widget
            });
          }
        },
      ),
    );
  }
}

TextField _buildTextField(TextEditingController _controller, String hint) {
  return TextField(
    controller: _controller,
    decoration: InputDecoration(
      labelText: hint,
      hintText: hint,
      border: OutlineInputBorder(),
    ),
  );
}

Future<void> launchUrl(String url) async {
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    print('Could not launch $url');
  }
}

void _openGoogleMaps(BuildContext context, String address) async {
  if (address.isNotEmpty) {
    final googleMapsUrl =
        'https://www.google.com/maps/search/?api=1&query=$address';
    if (await canLaunch(googleMapsUrl)) {
      await launch(googleMapsUrl);
    } else {
      print('Could not launch $googleMapsUrl');
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Address is empty.'),
      ),
    );
  }
}
