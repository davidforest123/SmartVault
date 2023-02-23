import 'package:flutter/material.dart';
import 'package:textvault/utils/page.dart';

// decrypt file page
class PageDecryptFile extends StatefulWidget {
  final String toOpenFile;

  PageDecryptFile(String toOpenFile) : this.toOpenFile = toOpenFile;

  @override
  _PageDecryptFileState createState() => _PageDecryptFileState();
}

class _PageDecryptFileState extends State<PageDecryptFile> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Decrypt File'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(
                  left: 15.0, right: 15.0, top: 15, bottom: 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "To open: " + this.widget.toOpenFile,
                  style: TextStyle(color: Colors.black, fontSize: 14),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                  left: 15.0, right: 15.0, top: 15, bottom: 0),
              child: TextField(
                obscureText: true,
                decoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.password,
                      size: 28.0,
                    ),
                    border: OutlineInputBorder(),
                    labelText: 'Password',
                    hintText: 'Enter password'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                  left: 15.0, right: 15.0, top: 15, bottom: 0),
              child: ElevatedButton(
                // set full width for button
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                onPressed: () {
                  //TODO FORGOT PASSWORD SCREEN GOES HERE
                },
                child: Text(
                  'Decrypt File',
                  //style: TextStyle(color: Colors.blue, fontSize: 25),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                  left: 15.0, right: 15.0, top: 15, bottom: 0),
              child: ElevatedButton(
                // set full width for button
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                onPressed: () {
                  utilBackToPreviousPage(context);
                },
                child: Text(
                  'Cancel',
                  //style: TextStyle(color: Colors.blue, fontSize: 25),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
