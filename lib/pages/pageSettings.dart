import 'package:flutter/material.dart';

// settings page
class PageSettings extends StatefulWidget {
  const PageSettings({Key? key}) : super(key: key);

  @override
  _PageSettingsState createState() => _PageSettingsState();
}

class _PageSettingsState extends State<PageSettings> {
  List<DropdownMenuItem<String>> get langDropdownItems {
    List<DropdownMenuItem<String>> menuItems = [
      DropdownMenuItem(child: Text("English"), value: "English"),
      DropdownMenuItem(child: Text("简体中文"), value: "简体中文"),
      DropdownMenuItem(child: Text("繁體中文"), value: "繁體中文"),
    ];
    return menuItems;
  }
  String langSelected = "English";

  List<DropdownMenuItem<String>> get defaultMaskModeDropdownItems {
    List<DropdownMenuItem<String>> menuItems = [
      DropdownMenuItem(child: Text("Mask"), value: "Mask"),
      DropdownMenuItem(child: Text("UnMask"), value: "UnMask"),
    ];
    return menuItems;
  }
  String defaultMaskModeSelected = "UnMask";

  List<DropdownMenuItem<String>> get lockScreenTimeDropdownItems {
    List<DropdownMenuItem<String>> menuItems = [
      DropdownMenuItem(child: Text("Never"), value: "Never"),
      DropdownMenuItem(child: Text("1 Minute"), value: "1 Minute"),
      DropdownMenuItem(child: Text("2 Minute"), value: "2 Minute"),
      DropdownMenuItem(child: Text("3 Minute"), value: "3 Minute"),
      DropdownMenuItem(child: Text("4 Minute"), value: "4 Minute"),
      DropdownMenuItem(child: Text("5 Minute"), value: "5 Minute"),
      DropdownMenuItem(child: Text("6 Minute"), value: "6 Minute"),
      DropdownMenuItem(child: Text("7 Minute"), value: "7 Minute"),
      DropdownMenuItem(child: Text("8 Minute"), value: "8 Minute"),
      DropdownMenuItem(child: Text("9 Minute"), value: "9 Minute"),
      DropdownMenuItem(child: Text("10 Minute"), value: "10 Minute"),
    ];
    return menuItems;
  }
  String lockScreenTimeSelected = "Never";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Settings"),
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
                  "User Interface Language",
                  style: TextStyle(color: Colors.black, fontSize: 14),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                  left: 15.0, right: 15.0, top: 15, bottom: 0),
              child: DropdownButtonFormField(
                  value: langSelected,
                  //style: TextStyle(color: Colors.red,fontSize: 30),
                  onChanged: (String? newValue) {
                    setState(() {
                      langSelected = newValue!;
                    });
                  },
                  items: langDropdownItems),
            ),
            Padding(
              padding: const EdgeInsets.only(
                  left: 15.0, right: 15.0, top: 15, bottom: 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Default Mask Mode",
                  style: TextStyle(color: Colors.black, fontSize: 14),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                  left: 15.0, right: 15.0, top: 15, bottom: 0),
              child: DropdownButtonFormField(
                  value: defaultMaskModeSelected,
                  //style: TextStyle(color: Colors.red,fontSize: 30),
                  onChanged: (String? newValue) {
                    setState(() {
                      defaultMaskModeSelected = newValue!;
                    });
                  },
                  items: defaultMaskModeDropdownItems),
            ),
            const Padding(
              padding: EdgeInsets.only(
                  left: 15.0, right: 15.0, top: 15, bottom: 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Lock Screen After No Operation",
                  style: TextStyle(color: Colors.black, fontSize: 14),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                  left: 15.0, right: 15.0, top: 15, bottom: 0),
              child: DropdownButtonFormField(
                  value: lockScreenTimeSelected,
                  //style: TextStyle(color: Colors.red,fontSize: 30),
                  onChanged: (String? newValue) {
                    setState(() {
                      lockScreenTimeSelected = newValue!;
                    });
                  },
                  items: lockScreenTimeDropdownItems),
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
                  'Save Settings',
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
                  //TODO FORGOT PASSWORD SCREEN GOES HERE
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
