import 'package:flutter/material.dart';

class AutomaticMessage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Automatic Message")),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            print("Emergency Message Sent");
          },
          child: Text("Send Emergency Message"),
        ),
      ),
    );
  }
}