import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mob_pit/helper.dart';
import 'package:url_launcher/url_launcher.dart';

import 'contacts.dart';

class AddContacts extends StatefulWidget {
  AddContacts({Key? key, this.index, this.contact}) : super(key: key);
  //here i add a variable
  //it is not a required, but use this when update
  final Contact? contact;
  final int? index;

  @override
  State<AddContacts> createState() => _AddContactsState();
}

class _AddContactsState extends State<AddContacts> {
  Future<void> getLoc() async {
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

  //for TextField
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void initState() {
    //when contact has data, mean is to update
    //instead of create new contact

    if (widget.contact != null) {
      _nameController.text = widget.contact!.name;
      _contactController.text = widget.contact!.contact;
      _addressController.text = widget.contact!.address;
    }
    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var contacts;
    return Scaffold(
        appBar: AppBar(
          title: Text('Add Contacts'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios),
            onPressed: () => Navigator.of(context).pop(false),
            // To prevent back button pressed without add/update
          ),
        ),
        body: Center(
          child: SingleChildScrollView(
            // Create two text fields to key in name and contact
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
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
                      if (widget.contact != null) {
                        await DBHelper.updateContacts(Contact(
                          id: widget.contact!.id, // Have to add id here
                          name: _nameController.text,
                          contact: _contactController.text,
                          address: _addressController.text,
                        ));
                        Navigator.of(context).pop(true);
                      } else {
                        await DBHelper.createContacts(Contact(
                          name: _nameController.text,
                          contact: _contactController.text,
                          address: _addressController.text,
                        ));

                        Navigator.of(context).pop(true);
                      }
                    },
                    child: Text('Save'),
                  ),
                  SizedBox(height: 20),
                  Visibility(
                      visible: widget.index == 0,
                      child: ElevatedButton(
                          onPressed: () {
                            getLoc();
                          },
                          child: Text('Generate Location'))),
                  SizedBox(height: 20),
                  Visibility(
                    visible: _nameController.text != "",
                    child: ElevatedButton(
                      onPressed: () =>
                          _openGoogleMaps(context, _addressController.text),
                      child: Text('Open Google Maps'),
                    ),
                  )
                ],
              ),
            ),
          ),
        ));
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
}

//build a text field method
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
