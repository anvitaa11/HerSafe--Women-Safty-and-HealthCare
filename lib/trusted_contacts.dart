import 'package:flutter/material.dart';

class TrustedContacts extends StatefulWidget {
  @override
  State<TrustedContacts> createState() => _TrustedContactsState();
}

class _TrustedContactsState extends State<TrustedContacts> {

  List<String> contacts = [];

  TextEditingController controller = TextEditingController();

  addContact(){
    setState(() {
      contacts.add(controller.text);
      controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Trusted Contacts")),
      body: Column(
        children: [

          Padding(
            padding: EdgeInsets.all(10),
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: "Enter Phone Number",
                suffixIcon: IconButton(
                  icon: Icon(Icons.add),
                  onPressed: addContact,
                ),
              ),
            ),
          ),

          Expanded(
            child: ListView.builder(
              itemCount: contacts.length,
              itemBuilder: (context,index){
                return ListTile(
                  title: Text(contacts[index]),
                );
              },
            ),
          )

        ],
      ),
    );
  }
}