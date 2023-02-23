import 'package:flutter/material.dart';

import '../utils/page.dart';

// change password page
class PageChangePassword extends StatefulWidget {
  const PageChangePassword({Key? key}) : super(key: key);

  @override
  _PageChangePasswordState createState() => _PageChangePasswordState();
}

class _PageChangePasswordState extends State<PageChangePassword> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Change Password'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(
                  left: 15.0, right: 15.0, top: 15, bottom: 0),
              child: TextField(
                obscureText: true,
                decoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.security,
                      size: 28.0,
                    ),
                    border: OutlineInputBorder(),
                    labelText: 'Old Password',
                    hintText: 'Enter old password'),
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
                    labelText: 'New Password',
                    hintText: 'Enter new password'),
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
                    labelText: 'Repeat New Password',
                    hintText:
                        'Repeat the password to confirm that it is entered correctly'),
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
                  'Change Password',
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
