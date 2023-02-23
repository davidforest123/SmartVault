import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_boxicons/flutter_boxicons.dart';

import '../utils/page.dart';

// set password page
class PageCreateFile extends StatefulWidget {
  const PageCreateFile({Key? key}) : super(key: key);

  @override
  _PageCreateFileState createState() => _PageCreateFileState();
}

class _PageCreateFileState extends State<PageCreateFile> {
  var selectDirTextField = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Create File"),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Padding(
              padding:
                  EdgeInsets.only(left: 15.0, right: 15.0, top: 15, bottom: 0),
              child: TextFormField(
                controller: TextEditingController(text: "MyPasswords.tv"),
                decoration: InputDecoration(
                    prefixIcon: Icon(
                      Boxicons.bx_file,
                      size: 28.0,
                    ),
                    border: OutlineInputBorder(),
                    labelText: 'File Name',
                    hintText: 'Enter file name'),
              ),
            ),
            Padding(
              padding:
                  EdgeInsets.only(left: 15.0, right: 15.0, top: 15, bottom: 0),
              child: TextField(
                controller: selectDirTextField,
                decoration: InputDecoration(
                    labelText: 'Where To Store',
                    hintText: 'Select a directory to store file',
                    filled: true,
                    prefixIcon: Icon(
                      Icons.folder,
                      size: 28.0,
                    ),
                    suffixIcon: IconButton(
                        icon: Icon(Icons.browse_gallery),
                        onPressed: () {
                          utilPickDirectory(selectDirTextField);
                        })),
              ),
            ),
            Padding(
              padding:
                  EdgeInsets.only(left: 15.0, right: 15.0, top: 15, bottom: 0),
              child: TextFormField(
                obscureText: true,
                decoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.password,
                      size: 28.0,
                    ),
                    border: OutlineInputBorder(),
                    labelText: 'Password',
                    hintText: 'Enter password to encrypt file'),
              ),
            ),
            const Padding(
              padding:
                  EdgeInsets.only(left: 15.0, right: 15.0, top: 15, bottom: 0),
              child: TextField(
                obscureText: true,
                decoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.password,
                      size: 28.0,
                    ),
                    border: OutlineInputBorder(),
                    labelText: 'Repeat Password',
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
                  //utilPickDirectory();
                },
                child: const Text(
                  'Create',
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

void utilPickDirectory(TextEditingController selectDir) async {
  String? selected = await FilePicker.platform.getDirectoryPath();
  if (selected == null) {
    // User canceled the picker
    return;
  }
  selectDir.text = selected;
}
