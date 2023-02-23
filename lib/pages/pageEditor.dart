import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_boxicons/flutter_boxicons.dart';
import 'package:textvault/pages/pageDecryptFile.dart';
import 'package:textvault/theme/color.dart';

// editor page
class PageEditor extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // custom InputDecoration
    InputDecoration myInputDecoration = const InputDecoration.collapsed(
        hintText: "",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(0.0)),
          borderSide: BorderSide(
            width: 0,
            style: BorderStyle.none,
          ),
        ),
        filled: true,
        fillColor: Colors.white);

    // custom tab controller
    DefaultTabController myTabController = DefaultTabController(
      length: 1,
      child: TabBar(
        tabs: [
          Tab(text: "untitled-1"),
        ],
      ),
    );

    // custom tab container
    Container myTabContainer = Container(
      height: 40, // set height
      child: myTabController,
    );

    return Scaffold(
      body: Column(
        children: [
          Container(
            height: 40,
            width: MediaQuery.of(context).size.width,
            color: Theme.of(context).colorScheme.barColor,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const TooltipIcon(
                    icon: Icons.create,
                    tooltip: 'New File',
                  ),
                  const TooltipIcon(
                    icon: Icons.file_open,
                    tooltip: 'Open File',
                  ),
                  const TooltipIcon(
                    icon: Icons.save,
                    tooltip: 'Save File',
                  ),
                  const TooltipIcon(
                    icon: Icons.password,
                    tooltip: 'Change Password',
                  ),
                  const TooltipIcon(
                    icon: Boxicons.bxs_face_mask,
                    tooltip: 'Mask Mode',
                  ),
                  VerticalDivider(
                    endIndent: 10,
                    indent: 10,
                    color: Theme.of(context).colorScheme.barIconColor,
                  ),
                  const TooltipIcon(
                    icon: Icons.undo,
                    tooltip: 'Undo',
                  ),
                  const TooltipIcon(
                    icon: Icons.redo,
                    tooltip: 'Redo',
                  ),
                  const TooltipIcon(
                    icon: Icons.copy,
                    tooltip: 'Copy',
                  ),
                  const TooltipIcon(
                    icon: Icons.cut,
                    tooltip: 'Cut',
                  ),
                  const TooltipIcon(
                    icon: Icons.paste,
                    tooltip: 'Paste',
                  ),
                  const TooltipIcon(
                    icon: Icons.find_replace,
                    tooltip: 'Find Replace',
                  ),
                  VerticalDivider(
                    endIndent: 10,
                    indent: 10,
                    color: Theme.of(context).colorScheme.barIconColor,
                  ),
                  const TooltipIcon(
                    icon: Icons.settings,
                    tooltip: 'Settings',
                  ),
                  const TooltipIcon(
                    icon: Icons.update,
                    tooltip: 'Check Update',
                  ),
                  const TooltipIcon(
                    icon: Boxicons.bxl_github,
                    tooltip: 'Github Repository',
                  ),
                ],
              ),
            ),
          ),
          myTabContainer,
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                margin: const EdgeInsets.all(0),
                width: MediaQuery.of(context).size.width,
                height: 1600,
                child: Card(
                  color: Theme.of(context).colorScheme.cardColor,
                  elevation: 1,
                  margin: const EdgeInsets.all(0.5),
                  // TextFormField margin to Card edge
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    // mouse cursor padding to TextFormField edge
                    child: TextFormField(
                      onChanged: (text) {
                        print("First text field: $text");
                      },
                      style: TextStyle(
                        fontSize: 15.0,
                        color: Theme.of(context).colorScheme.foregroundText,
                        fontFamily: "Roboto",
                      ),
                      decoration: myInputDecoration,
                      autocorrect: false,
                      minLines: null,
                      maxLines: null,
                      expands: true,
                      cursorColor: Theme.of(context).colorScheme.foregroundText,
                    ),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

Map buttonOnTap(BuildContext context, String btnName) {
  print("buttonOnTap: $btnName");
  var result = new Map();

  switch (btnName) {
    case "New File":
      {
        Navigator.pushNamed(context, '/pageCreateFile');
      }
      break;

    case "Open File":
      {
        openOneTvFile(context);
      }
      break;

    case "Save File":
      {}
      break;

    case "Change Password":
      {
        Navigator.pushNamed(context, '/pageChangePassword');
      }
      break;

    case "Undo":
      {}
      break;

    case "Redo":
      {}
      break;

    case "Find Replace":
      {}
      break;

    case "Settings":
      {
        Navigator.pushNamed(context, '/pageSettings');
      }
      break;

    case "Github Repository":
      {}
      break;

    default:
      {
        //statements;
      }
      break;
  }

  return result;
}

// toolbar icon button
class TooltipIcon extends StatelessWidget {
  const TooltipIcon({
    required this.icon,
    required this.tooltip,
    Key? key,
  }) : super(key: key);
  final IconData icon;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () {
          buttonOnTap(context, this.tooltip);
        },
        child: SizedBox(
          width: 40,
          height: 40,
          child: Center(
            child: Icon(
              icon,
              size: 25,
              color: Theme.of(context).colorScheme.barIconColor,
            ),
          ),
        ),
      ),
    );
  }
}

// toolbar text button
class TooltipText extends StatelessWidget {
  const TooltipText({
    required this.text,
    required this.tooltip,
    Key? key,
  }) : super(key: key);
  final String text;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () {
          buttonOnTap(context, this.tooltip);
        },
        child: SizedBox(
          width: 40,
          height: 40,
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15.0,
                color: Theme.of(context).colorScheme.barIconColor,
                fontWeight: FontWeight.w800,
                fontFamily: "Roboto",
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void openOneTvFile(BuildContext context) async {
  final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Select an TextVault(.tv) File:',
      type: FileType.custom,
      allowMultiple: false,
      allowedExtensions: ['tv']);

  // if no file is picked
  if (result == null) return;

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) =>
          PageDecryptFile(result.files.single.path.toString()),
    ),
  );
}

class Doc {
  String password = "";
  String content = "";
  bool edited = false;
  String shortName = "";
  String filepath = "";
}
