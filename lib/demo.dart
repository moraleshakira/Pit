import 'package:flutter/material.dart';
import 'package:pit_proj/contacts.dart';
import 'package:pit_proj/helper.dart';
import 'package:pit_proj/add_contacts.dart';

class Demo extends StatefulWidget {
  Demo({Key? key}) : super(key: key);

  @override
  _DemoState createState() => _DemoState();
}

class _DemoState extends State<Demo> {
  List<Contact> contacts = [];

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
              ? Center(
            child: Text('No Contact'),
          )
              : ListView(
            children: snapshot.data!.map((contacts) {
              return Center(
                child: ListTile(
                  title: Text(contacts.name),
                  subtitle: Text(contacts.contact),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () async {
                      bool deleteConfirmed = await showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('Delete contact'),
                            content: Text('Are you sure you want'
                                ' to delete this contact?'),
                            actions: <Widget>[
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
                      if(deleteConfirmed!=null&&deleteConfirmed) {
                        await DBHelper.deleteContacts(contacts.id!);
                        setState(() {
                          //rebuild widget after delete
                        });
                      }
                    },
                  ),
                  onTap: () async {
                    //tap on ListTile, for update
                    final refresh = await Navigator.of(context)
                        .push(MaterialPageRoute(
                        builder: (_) => AddContacts(
                          contact: Contact(
                            id: contacts.id,
                            name: contacts.name,
                            contact: contacts.contact,
                            address: contacts.address,
                          ),
                        )));

                    if (refresh) {
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