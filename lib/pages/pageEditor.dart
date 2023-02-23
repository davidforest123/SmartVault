import 'package:flutter/material.dart';
import 'package:flutter_boxicons/flutter_boxicons.dart';
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
                  const ToolbarIconButton(
                    icon: Icons.create,
                    tooltip: 'New File',
                  ),
                  const ToolbarIconButton(
                    icon: Icons.file_open,
                    tooltip: 'Open File',
                  ),
                  const ToolbarIconButton(
                    icon: Icons.save,
                    tooltip: 'Save File',
                  ),
                  const ToolbarIconButton(
                    icon: Icons.security,
                    tooltip: 'Set/Change Password',
                  ),
                  const ToolbarIconButton(
                    icon: Boxicons.bxs_face_mask,
                    tooltip: 'Mask Mode',
                  ),
                  VerticalDivider(
                    endIndent: 10,
                    indent: 10,
                    color: Theme.of(context).colorScheme.barIconColor,
                  ),
                  const ToolbarIconButton(
                    icon: Icons.undo,
                    tooltip: 'Undo',
                  ),
                  const ToolbarIconButton(
                    icon: Icons.redo,
                    tooltip: 'Redo',
                  ),
                  const ToolbarIconButton(
                    icon: Icons.copy,
                    tooltip: 'Copy',
                  ),
                  const ToolbarIconButton(
                    icon: Icons.cut,
                    tooltip: 'Cut',
                  ),
                  const ToolbarIconButton(
                    icon: Icons.paste,
                    tooltip: 'Paste',
                  ),
                  const ToolbarIconButton(
                    icon: Icons.find_replace,
                    tooltip: 'Find Replace',
                  ),
                  VerticalDivider(
                    endIndent: 10,
                    indent: 10,
                    color: Theme.of(context).colorScheme.barIconColor,
                  ),
                  const ToolbarIconButton(
                    icon: Icons.settings,
                    tooltip: 'Settings',
                  ),
                  const ToolbarIconButton(
                    icon: Icons.update,
                    tooltip: 'Check Update',
                  ),
                  const ToolbarIconButton(
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
    case "New File":{

    }
      break;

    case "Open File":
      {Navigator.pushNamed(context, '/pageDecryptFile');}
      break;

    case "Save File":
      {Navigator.pushNamed(context, '/pageSetPassword');}
      break;

    case "Set/Change Password":
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
class ToolbarIconButton extends StatelessWidget {
  const ToolbarIconButton({
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
class ToolbarTextButton extends StatelessWidget {
  const ToolbarTextButton({
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
