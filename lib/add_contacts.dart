import 'package:flutter/material.dart';
import 'package:pit_proj/helper.dart';
import 'package:url_launcher/url_launcher.dart';

import 'contacts.dart';

class AddContacts extends StatefulWidget {
  AddContacts({Key? key, this.contact}) : super(key: key);
  //here i add a variable
  //it is not a required, but use this when update
  final Contact? contact;

  @override
  State<AddContacts> createState() => _AddContactsState();
}

class _AddContactsState extends State<AddContacts> {
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
                child: Text('Save to Contact List'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _openGoogleMaps(context,contacts.address),
                  child: Text('Open Google Maps'),
              ),
            ],
          ),
        ),
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
      final googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=$address';
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
