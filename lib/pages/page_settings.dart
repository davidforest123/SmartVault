import 'package:flutter/material.dart';

import '../utils/page.dart';

// settings page
class PageSettings extends StatefulWidget {
  const PageSettings({Key? key}) : super(key: key);

  @override
  PageSettingsState createState() => PageSettingsState();
}

class PageSettingsState extends State<PageSettings> {
  List<DropdownMenuItem<String>> get langDropdownItems {
    List<DropdownMenuItem<String>> menuItems = [
      const DropdownMenuItem(value: "English", child: Text("English")),
      const DropdownMenuItem(value: "简体中文", child: Text("简体中文")),
      const DropdownMenuItem(value: "繁體中文", child: Text("繁體中文")),
    ];
    return menuItems;
  }

  String langSelected = "English";

  int lockScreenTime = 0;

  bool enableFileAssociate = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(
                  left: 15.0, right: 15.0, top: 15, bottom: 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Language",
                    style: TextStyle(color: Colors.black, fontSize: 14),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width / 2,
                    child: DropdownButtonFormField(
                        value: langSelected,
                        onChanged: (String? newValue) {
                          setState(() {
                            langSelected = newValue!;
                          });
                        },
                        items: langDropdownItems),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                  left: 15.0, right: 15.0, top: 15, bottom: 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Associate *.tv Files',
                  ),
                  Switch(
                    value: enableFileAssociate,
                    activeColor: const Color(0xFF6200EE),
                    onChanged: (bool newValue) {
                      setState(() {
                        enableFileAssociate = newValue;
                      });
                    },
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                  left: 15.0, right: 15.0, top: 15, bottom: 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Lock File After Inactive",
                    style: TextStyle(color: Colors.black, fontSize: 14),
                  ),
                  SizedBox(
                      // SizedBox is used to control size of `Slider` component.
                      width: MediaQuery.of(context).size.width / 2,
                      child: Column(
                        children: [
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: List.generate(
                                      11,
                                      (index) => Text(index == 0
                                          ? 'Never'
                                          : (index == 10 ? '$index' : ''))),
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: List.generate(
                                    11,
                                    (index) => const SizedBox(
                                      height: 8,
                                      child: VerticalDivider(
                                        width: 8,
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                          Slider(
                            min: 0,
                            max: 10,
                            divisions: 10,
                            value: lockScreenTime.toDouble(),
                            onChanged: (double newValue) {
                              setState(() {
                                lockScreenTime = newValue.round();
                              });
                            },
                            label: lockScreenTime == 0
                                ? "Never"
                                : (lockScreenTime == 1
                                    ? "1 Minute"
                                    : "$lockScreenTime Minutes"),
                          ),
                        ],
                      )),
                ],
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
                child: const Text(
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
                onPressed: () {},
                child: const Text(
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
