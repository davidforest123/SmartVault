import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_boxicons/flutter_boxicons.dart';
import 'package:path/path.dart' as path;
import 'package:textvault/theme/color.dart';
import 'package:textvault/utils/home_dir.dart';
import 'package:textvault/utils/number.dart';
import 'package:textvault/widgets/widget_alert_dialog.dart';
import 'package:textvault/widgets/widget_tab_view.dart';

/// TextFormField content will disappear if user switch tabs(lost focus) or resize window.
/// If user want to keep text of TextFormField, there are 3 things must be done:
/// 1, controller: TextEditingController(text: aGlobalStringVar)
/// 2, onChanged: (newText) { aGlobalStringVar = newText; }
/// 3, define aGlobalStringVar in global variant area.

const gTvHeader = 'tvheader';
const gMinPwdLen = 8;
const gMinFileSize = 18;

class Doc {
  Doc({
    required this.filename,
    required this.content,
    required this.filepath,
    required this.password,
  });

  String filename;
  String content;
  String filepath;
  String password;

  var ctrlPageCreateFileName = TextEditingController(text: "");
  var ctrlPageCreateFileSelectDir = TextEditingController();
  var ctrlPageCreateFilePwd = TextEditingController();
  var ctrlPageCreateFilePwdConfirm = TextEditingController();
  var ctrlContent = TextEditingController();
  var ctrlPageDecFilePwd = TextEditingController();
  var ctrlPageChgPwdOldPwd = TextEditingController();
  var ctrlPageChgPwdNewPwd = TextEditingController();
  var ctrlPageChgPwdNewPwdConfirm = TextEditingController();
  int selectedTab = 0;
  int version = 1;
  bool edited = false;

  String save() {
    var toSave = BytesBuilder();
    var plainText = gTvHeader + content;
    var errMsg = '';
    toSave.add(Uint8List.fromList('$version\n'.codeUnits));

    if (password.length < gMinPwdLen) {
      var pwdLen = password.length;
      errMsg = 'password length $pwdLen is less than $gMinPwdLen';
      return errMsg;
    }
    if (plainText.isEmpty) {
      errMsg = 'plainText is empty, empty string cannot be encrypted';
      return errMsg;
    }

    switch (version) {
      // AES256
      case 1:
        {
          var digest = sha256.convert(utf8.encode(password)).toString();
          final key = enc.Key.fromUtf8(digest.substring(0, 32));
          final iv = enc.IV.fromUtf8('16bytesIVabCDefG');
          final crypt = enc.Encrypter(
              enc.AES(key, mode: enc.AESMode.ctr, padding: 'PKCS7'));
          final encrypted = crypt.encrypt(plainText, iv: iv);
          toSave.add(encrypted.bytes);
          break;
        }
      default:
        {
          errMsg = "unsupported version $version";
          return errMsg;
        }
    }
    try {
      File(filepath).writeAsBytesSync(toSave.toBytes());
    } catch (e) {
      errMsg = e.toString();
    } finally {
      gDocs[gSelectedTabIndex]!.edited = false;
      gTabViewSetStateNotifier.value = "";
      gTabViewSetStateNotifier.value = "random-data";
    }
    return errMsg;
  }

  String load() {
    var errMsg = '';
    Uint8List buffer;

    try {
      buffer = File(filepath).readAsBytesSync();
    } catch (e) {
      errMsg = e.toString();
      return errMsg;
    }

    var len = buffer.length;
    if (buffer.length < gMinFileSize) {
      errMsg = 'TextVault file size $len should not be less than $gMinFileSize';
      return errMsg;
    }

    var version = '';
    var versionEndIdx = 0;
    for (int i = 1; i < 5; i++) {
      if (buffer.elementAt(i) == 10 /*'\n'*/) {
        version = String.fromCharCodes(buffer.getRange(0, i));
        versionEndIdx = i;
        break;
      }
    }
    if (version.isEmpty) {
      errMsg = 'TextVault file version not found';
      return errMsg;
    }
    if (!isNumeric(version)) {
      errMsg = 'TextVault file version $version is not a number';
      return errMsg;
    }
    var intVersion = int.parse(version);
    var cipherText = enc.Encrypted(Uint8List.fromList(
        buffer.getRange(versionEndIdx + 1, buffer.length).toList()));
    switch (intVersion) {
      case 1:
        {
          var digest =
              sha256.convert(utf8.encode(ctrlPageDecFilePwd.text)).toString();
          final key = enc.Key.fromUtf8(digest.substring(0, 32));
          final iv = enc.IV.fromUtf8('16bytesIVabCDefG');
          final crypt = enc.Encrypter(enc.AES(key, mode: enc.AESMode.ctr));
          var plainText = '';
          try {
            plainText = crypt.decrypt(cipherText, iv: iv);
          } catch (e) {
            errMsg = e.toString();
          } finally {
            if (plainText.startsWith(gTvHeader)) {
              content = plainText.substring(gTvHeader.length);
              password = ctrlPageDecFilePwd.text;
              ctrlContent.text = content;
            } else {
              errMsg = 'password is not correct';
            }
          }
          break;
        }
      default:
        {
          errMsg = "unsupported version $version";
          return errMsg;
        }
    }

    return errMsg;
  }
}

class Config {
  List<String> recentOpen = [];

  // this is necessary for jsonEncode/jsonDecode
  Map toJson() => {'RecentOpen': recentOpen};

  addRecentOpen(String newPath) {
    if (newPath.isEmpty) {
      return;
    }
    recentOpen.add(newPath);
    var temp = recentOpen.toSet(); // remove duplicated
    temp.remove(""); // remove empty string
    recentOpen = temp.toList();
    save();
  }

  save() {
    var savePath = path.join(homeDirPath!, ".textvault");
    var jsonString = jsonEncode(this);
    File(savePath).writeAsString(jsonString);
  }

  load() {
    var configPath = path.join(homeDirPath!, ".textvault");
    var configExist = File(configPath).existsSync();
    var configString = '';
    if (configExist) {
      configString = File(configPath).readAsStringSync();
      if (configString.isNotEmpty) {
        var jsonDoc = jsonDecode(configString);
        List<dynamic> recentOpen = jsonDoc['RecentOpen'];
        for (var element in recentOpen) {
          addRecentOpen(element.toString());
        }
      }
    }
  }
}

var docRecentOpen = Doc(
  filename: "Recent Open",
  content: "",
  filepath: "",
  password: "",
);

Map<int, Doc> gDocs = {
  0: docRecentOpen,
};

int gSelectedTabIndex = 0;
// message notifier between different widgets.
final gNotifier = ValueNotifier("");
Config gConfig = Config();

Widget onTabBuild(BuildContext context, int index) {
  var width = (index == 0) ? 0.0 : 25.0;
  var height = (index == 0) ? 0.0 : 25.0;
  var editedStatus = gDocs[index]!.edited ? ' - [Edited]' : '';
  return Tab(
    height: 40,
    child: Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: Text(gDocs[index]!.filename + editedStatus),
        ),
        Container(
            decoration: BoxDecoration(
                border: Border.all(
                    color: Colors.transparent, style: BorderStyle.none)),
            height: height,
            width: width,
            child: FittedBox(
              child: FloatingActionButton(
                  heroTag: 'btn$index',
                  // 'heroTag' must be unique between different FloatingActionButton
                  elevation: 0,
                  // remove shadow of FloatingActionButton
                  backgroundColor: Colors.transparent,
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(90.0))),
                  child: const Icon(
                    Icons.close,
                    size: 28,
                  ),
                  onPressed: () {
                    gNotifier.value = "";
                    gNotifier.value = "close-file:$index";
                  }),
            ))
      ],
    ),
  );
}

Widget onTabWindowBuild(BuildContext context, int index) {
  if (index == 0) {
    gConfig.load();
    var clearBtn = Padding(
        padding: const EdgeInsets.all(5),
        child: ElevatedButton(
          onPressed: () {
            gConfig.recentOpen = [];
            gConfig.save();
            gTabViewSetStateNotifier.value = '';
            gTabViewSetStateNotifier.value = 'update recent open window';
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            child: const Text("Clear Recent Open"),
          ),
        ));
    var historyList = List.generate(
      gConfig.recentOpen.length,
      (index) => Padding(
        padding: const EdgeInsets.all(5),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              gNotifier.value = "";
              gNotifier.value = 'open-file:${gConfig.recentOpen[index]}';
            },
            child: Text(gConfig.recentOpen[index],
                style: const TextStyle(
                  decoration: TextDecoration.underline,
                )),
          ),
        ),
      ),
    );
    historyList.add(clearBtn);

    return Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: historyList,
        ));
  } else {
    return WidgetEditor(context: context, tabIndex: index);
  }
}

// editor page
class PageEditor extends StatefulWidget {
  const PageEditor({
    super.key,
  });

  @override
  PageEditorState createState() => PageEditorState();
}

class PageEditorState extends State<PageEditor> {
  @override
  void initState() {
    super.initState();
    gNotifier.addListener(update); // add listen callback for `gNotifier`
  }

  @override
  void dispose() {
    super.dispose();
    gNotifier.removeListener(update); // remove listen callback for `gNotifier`
  }

// listen callback of `gNotifier`
  void update() {
    //setState(() {});
    if (gNotifier.value == 'new-file') {
      addTab("untitled-${gDocs.length}.tv", "", "", "", 0);
    } else if (gNotifier.value.startsWith("open-file:")) {
      var toOpenFilepath = gNotifier.value.replaceAll("open-file:", "");
      String basename = path.basename(File(toOpenFilepath).path);
      addTab(basename, "", "", toOpenFilepath, 1);
    } else if (gNotifier.value.startsWith("close-file:")) {
      var toRemoveIdx = gNotifier.value.replaceAll("close-file:", "");
      delTab(int.parse(toRemoveIdx));
    } else if (gNotifier.value == 'change-password') {
      if (gSelectedTabIndex >= 1 &&
          gDocs[gSelectedTabIndex]!.selectedTab == 2) {
        // `setState` is necessary for switching tab right now
        setState(() {
          gDocs[gSelectedTabIndex]!.selectedTab = 3;
        });
      }
    } else if (gNotifier.value == 'save-file') {
      // ignore 'Recent Open' page
      if (gSelectedTabIndex == 0) {
        return;
      }
      gDocs[gSelectedTabIndex]!.content =
          gDocs[gSelectedTabIndex]!.ctrlContent.text;
      var errMsg = gDocs[gSelectedTabIndex]!.save();
      if (errMsg.isNotEmpty) {
        showAlertDialog(context, "Can't Save File", errMsg, "OK");
        return;
      }
    }
  }

  // https://stackoverflow.com/questions/50036546/how-to-create-a-dynamic-tabbarview-render-a-new-tab-with-a-function-in-flutter
  addTab(String filename, String content, String password, String filepath,
      initSelectedTab) {
    var alreadyOpen = false;
    // user can open multiple tabs with empty filepath, empty filepath means user will create new file.
    if (filepath.isNotEmpty) {
      for (int i = 0; i < gDocs.length; i++) {
        if (gDocs[i]!.filepath == filepath) {
          alreadyOpen = true;
        }
      }
    }
    if (alreadyOpen) {
      showAlertDialog(
          context, "Can't Open File", "File($filepath) already open", "OK");
      return;
    }

    // `setState` is necessary for switching tab right now
    setState(() {
      var newIdx = gDocs.length;
      var newDoc = Doc(
        filename: filename,
        content: content,
        password: password,
        filepath: filepath,
      );
      newDoc.selectedTab = initSelectedTab;
      newDoc.ctrlPageCreateFileName.text = filename;
      gDocs[newIdx] = newDoc;
      gSelectedTabIndex = gDocs.length - 1; // select last tab
      print("current tab $gSelectedTabIndex");
      gTabViewSetStateNotifier.value = "";
      gTabViewSetStateNotifier.value = "update TabBars' color";
    });
  }

  delTab(int delIdx) {
    setState(() {
      gDocs.remove(delIdx);
      Map<int, Doc> updateIdxDocs = {};
      List<int> toDelKeys = [];
      gDocs.forEach((key, value) {
        if (key > delIdx) {
          updateIdxDocs[key - 1] = gDocs[key]!;
          toDelKeys.add(key);
        }
      });
      for (var element in toDelKeys) {
        gDocs.remove(element);
      }
      gDocs.addAll(updateIdxDocs);
    });
  }

  @override
  Widget build(BuildContext context) {
    var myToolBar = Container(
      height: 40,
      width: MediaQuery.of(context).size.width,
      // toolbar background color
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
            VerticalDivider(
              endIndent: 10,
              indent: 10,
              color: Theme.of(context).colorScheme.barIconColor,
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
              icon: Icons.undo,
              tooltip: 'Undo',
            ),
            const TooltipIcon(
              icon: Icons.redo,
              tooltip: 'Redo',
            ),
            const TooltipIcon(
              icon: Icons.find_replace,
              tooltip: 'Find Replace',
            ),
          ],
        ),
      ),
    );

    WidgetTabView myTabView = WidgetTabView(
      initPosition: gSelectedTabIndex,
      itemCount: gDocs.length,
      tabBuilder: (context, index) => onTabBuild(context, index),
      pageBuilder: (context, index) => onTabWindowBuild(context, index),
      onPositionChange: (index) {
        gSelectedTabIndex = index;
        print("current tab $index");
        gTabViewSetStateNotifier.value = "";
        gTabViewSetStateNotifier.value = "update TabBars' color";
      },
      //onScroll: (position) => print('$position'),
    );

    var result = Scaffold(
      body: Column(
        children: [
          myToolBar,
          Expanded(
            child: myTabView,
          ),
        ],
      ),
    );

    return result;
  }
}

// toolbar icon button
class WidgetEditor extends StatefulWidget {
  const WidgetEditor({
    required this.context,
    required this.tabIndex,
    Key? key,
  }) : super(key: key);

  final BuildContext context;
  final int tabIndex;

  @override
  WidgetEditorState createState() => WidgetEditorState();
}

class WidgetEditorState extends State<WidgetEditor> {
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

    var widgetEditor = Padding(
        // mouse cursor padding to TextFormField edge
        padding: const EdgeInsets.all(5),
        child: TextFormField(
          // `controller` is necessary to keep text of TextFormField when switch tabs.
          controller: gDocs[widget.tabIndex]!.ctrlContent,
          //TextEditingController(text: gDocs[this.widget.tabIndex]!.content),
          onChanged: (newText) {
            gDocs[widget.tabIndex]!.content =
                newText; // this is necessary to keep text of TextFormField when resize window.
            gDocs[widget.tabIndex]!.edited = true;
            gTabViewSetStateNotifier.value = '';
            gTabViewSetStateNotifier.value = 'random data';
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
        ));

    var widgetCreateFile = Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(
              left: 15.0, right: 15.0, top: 15, bottom: 0),
          child: TextFormField(
            controller: gDocs[widget.tabIndex]!.ctrlPageCreateFileName,
            decoration: const InputDecoration(
                prefixIcon: Icon(
                  Boxicons.bx_file,
                  size: 28.0,
                ),
                border: OutlineInputBorder(),
                labelText: 'File Name',
                hintText: 'Enter file name'),
            onChanged: (String newText) {
              gDocs[gSelectedTabIndex]!.filename = newText;
              gTabViewSetStateNotifier.value = "";
              gTabViewSetStateNotifier.value = "random data";
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(
              left: 15.0, right: 15.0, top: 15, bottom: 0),
          child: TextFormField(
            controller: gDocs[widget.tabIndex]!.ctrlPageCreateFileSelectDir,
            decoration: InputDecoration(
                labelText: 'Where To Store',
                hintText: 'Select a directory to store file',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(
                  Icons.folder,
                  size: 28.0,
                ),
                suffixIcon: IconButton(
                    icon: const Icon(Icons.browse_gallery),
                    onPressed: () {
                      utilPickDirectory(
                          gDocs[widget.tabIndex]!.ctrlPageCreateFileSelectDir);
                    })),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(
              left: 15.0, right: 15.0, top: 15, bottom: 0),
          child: TextFormField(
            controller: gDocs[widget.tabIndex]!.ctrlPageCreateFilePwd,
            obscureText: true,
            decoration: const InputDecoration(
                prefixIcon: Icon(
                  Icons.password,
                  size: 28.0,
                ),
                border: OutlineInputBorder(),
                labelText: 'Password',
                hintText: 'Enter password to encrypt file'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(
              left: 15.0, right: 15.0, top: 15, bottom: 0),
          child: TextFormField(
            controller: gDocs[widget.tabIndex]!.ctrlPageCreateFilePwdConfirm,
            obscureText: true,
            decoration: const InputDecoration(
                prefixIcon: Icon(
                  Icons.password,
                  size: 28.0,
                ),
                border: OutlineInputBorder(),
                labelText: 'Confirm Password',
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
              var errMsg = '';
              if (gDocs[widget.tabIndex]!.ctrlPageCreateFileName.text.isEmpty) {
                errMsg = '[File Name] must be non-empty';
              } else if (gDocs[widget.tabIndex]!
                      .ctrlPageCreateFileName
                      .text
                      .endsWith('.tv') ==
                  false) {
                errMsg = '[File Name] must end with \'.tv\'';
              } else if (gDocs[widget.tabIndex]!
                  .ctrlPageCreateFileSelectDir
                  .text
                  .isEmpty) {
                errMsg = '[Where To Store] must be non-empty';
              } else if (Directory(gDocs[widget.tabIndex]!
                          .ctrlPageCreateFileSelectDir
                          .text)
                      .existsSync() ==
                  false) {
                errMsg = '[Where To Store] must already exist]';
              } else if (File(path.join(
                          gDocs[widget.tabIndex]!
                              .ctrlPageCreateFileSelectDir
                              .text,
                          gDocs[widget.tabIndex]!.ctrlPageCreateFileName.text))
                      .existsSync() ==
                  true) {
                errMsg = '[Where To Store]/[File Name] must not exist]';
              } else if (gDocs[widget.tabIndex]!
                      .ctrlPageCreateFilePwd
                      .text
                      .length <
                  gMinPwdLen) {
                errMsg =
                    '[Password] length must be greater than or equal to $gMinPwdLen';
              } else if (gDocs[widget.tabIndex]!.ctrlPageCreateFilePwd.text !=
                  gDocs[widget.tabIndex]!.ctrlPageCreateFilePwdConfirm.text) {
                errMsg = "[Password] and [Confirm Password] don't match";
              }

              if (errMsg.isNotEmpty) {
                showAlertDialog(context, "Can't Create File", errMsg, "OK");
              } else {
                // `setState` is necessary for switching tab right now
                setState(() {
                  gDocs[widget.tabIndex]!.filename =
                      gDocs[widget.tabIndex]!.ctrlPageCreateFileName.text;
                  gDocs[widget.tabIndex]!.content = '';
                  gDocs[widget.tabIndex]!.filepath = path.join(
                      gDocs[widget.tabIndex]!.ctrlPageCreateFileSelectDir.text,
                      gDocs[widget.tabIndex]!.ctrlPageCreateFileName.text);
                  gDocs[widget.tabIndex]!.password =
                      gDocs[widget.tabIndex]!.ctrlPageCreateFilePwd.text;
                  gDocs[widget.tabIndex]!.selectedTab = 2;
                  gConfig.addRecentOpen(gDocs[widget.tabIndex]!.filepath);
                });
                gDocs[widget.tabIndex]!.save();
                return;
              }
            },
            child: const Text(
              'Create File',
              //style: TextStyle(color: Colors.blue, fontSize: 25),
            ),
          ),
        )
      ],
    );

    var widgetDecryptFile = Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(
              left: 15.0, right: 15.0, top: 15, bottom: 0),
          child: TextField(
            controller: gDocs[widget.tabIndex]!.ctrlPageDecFilePwd,
            obscureText: true,
            decoration: const InputDecoration(
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
              var errMsg = '';
              if (gDocs[widget.tabIndex]!.ctrlPageDecFilePwd.text.isEmpty) {
                errMsg = "Password must be non-empty";
              } else {
                errMsg = gDocs[widget.tabIndex]!.load();
              }

              if (errMsg.isNotEmpty) {
                showAlertDialog(context, "Can't Decrypt File", errMsg, "OK");
                return;
              }

              // `setState` is necessary for switching tab right now
              setState(() {
                gDocs[widget.tabIndex]!.selectedTab = 2;
                gConfig.addRecentOpen(gDocs[widget.tabIndex]!.filepath);
                gTabViewSetStateNotifier.value = '';
                gTabViewSetStateNotifier.value = 'update recent open window';
              });
            },
            child: const Text(
              'Decrypt File',
              //style: TextStyle(color: Colors.blue, fontSize: 25),
            ),
          ),
        )
      ],
    );

    var widgetChangePassword = Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(
              left: 15.0, right: 15.0, top: 15, bottom: 0),
          child: TextField(
            controller: gDocs[widget.tabIndex]!.ctrlPageChgPwdOldPwd,
            obscureText: true,
            decoration: const InputDecoration(
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
            controller: gDocs[widget.tabIndex]!.ctrlPageChgPwdNewPwd,
            obscureText: true,
            decoration: const InputDecoration(
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
            controller: gDocs[widget.tabIndex]!.ctrlPageChgPwdNewPwdConfirm,
            obscureText: true,
            decoration: const InputDecoration(
                prefixIcon: Icon(
                  Icons.password,
                  size: 28.0,
                ),
                border: OutlineInputBorder(),
                labelText: 'Confirm New Password',
                hintText:
                    'Repeat the new password to confirm that it is entered correctly'),
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
              // `setState` is necessary for switching tab right now
              setState(() {
                if (gDocs[widget.tabIndex]!.ctrlPageChgPwdOldPwd.text !=
                    gDocs[gSelectedTabIndex]!.password) {
                  showAlertDialog(context, "Can't Change Password",
                      "old password is not correct", "OK");
                  return;
                }
                if (gDocs[widget.tabIndex]!.ctrlPageChgPwdNewPwd.text.length <
                    gMinPwdLen) {
                  var pwdLen =
                      gDocs[widget.tabIndex]!.ctrlPageChgPwdNewPwd.text.length;
                  showAlertDialog(
                      context,
                      "Can't Change Password",
                      "new password length $pwdLen is less than $gMinPwdLen",
                      "OK");
                  return;
                }
                if (gDocs[widget.tabIndex]!.ctrlPageChgPwdNewPwd.text !=
                    gDocs[widget.tabIndex]!.ctrlPageChgPwdNewPwdConfirm.text) {
                  showAlertDialog(
                      context,
                      "Can't Change Password",
                      "[New Password] and [Confirm New Password] don't match",
                      "OK");
                  return;
                }

                gDocs[gSelectedTabIndex]!.password =
                    gDocs[widget.tabIndex]!.ctrlPageChgPwdNewPwd.text;
                var errMsg = gDocs[gSelectedTabIndex]!.save();
                if (errMsg.isNotEmpty) {
                  gDocs[gSelectedTabIndex]!.password =
                      gDocs[widget.tabIndex]!.ctrlPageChgPwdOldPwd.text;
                  showAlertDialog(
                      context, "Can't Change Password", errMsg, "OK");
                  return;
                }

                gDocs[widget.tabIndex]!.ctrlPageChgPwdOldPwd.text = '';
                gDocs[widget.tabIndex]!.ctrlPageChgPwdNewPwd.text = '';
                gDocs[widget.tabIndex]!.ctrlPageChgPwdNewPwdConfirm.text = '';
                gDocs[gSelectedTabIndex]!.selectedTab = 2;
              });
            },
            child: const Text(
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
              // `setState` is necessary for switching tab right now
              setState(() {
                gDocs[widget.tabIndex]!.ctrlPageChgPwdOldPwd.text = '';
                gDocs[widget.tabIndex]!.ctrlPageChgPwdNewPwd.text = '';
                gDocs[widget.tabIndex]!.ctrlPageChgPwdNewPwdConfirm.text = '';
                gDocs[gSelectedTabIndex]!.selectedTab = 2;
              });
            },
            child: const Text(
              'Cancel',
              //style: TextStyle(color: Colors.blue, fontSize: 25),
            ),
          ),
        ),
      ],
    );

    return WidgetTabView(
      initPosition: gDocs[widget.tabIndex]!.selectedTab,
      itemCount: 4,
      tabBuilder: (context, index) => Container(),
      pageBuilder: (context, index) {
        if (index == 0) {
          return widgetCreateFile;
        } else if (index == 1) {
          return widgetDecryptFile;
        } else if (index == 2) {
          return widgetEditor;
        } else {
          return widgetChangePassword;
        }
      },
      onPositionChange: (newIndex) {
        gDocs[widget.tabIndex]!.selectedTab = newIndex;
      },
      //onScroll: (position) => print('$position'),
    );
  }
}

// toolbar icon button
class TooltipIcon extends StatelessWidget {
  const TooltipIcon({
    required this.icon,
    required this.tooltip,
    Key? key,
  }) : super(key: key);

  //PageEditor editor = PageEditor();
  final IconData icon;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () {
          onToolbarBtnTap(context, tooltip);
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

void openOneTvFile(BuildContext context) async {
  final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Select an TextVault(.tv) File:',
      type: FileType.custom,
      allowMultiple: false,
      allowedExtensions: ['tv']);

  // if no file is picked
  if (result == null) return;

  var toOpen = result.files.single.path.toString();
  gNotifier.value = "";
  gNotifier.value = 'open-file:$toOpen';
}

Map onToolbarBtnTap(BuildContext context, String btnName) {
  Map result = {};

  switch (btnName) {
    case "New File":
      {
        gNotifier.value = "";
        gNotifier.value = "new-file";
      }
      break;

    case "Open File":
      {
        openOneTvFile(context);
      }
      break;

    case "Save File":
      {
        gNotifier.value = "";
        gNotifier.value = "save-file";
      }
      break;

    case "Change Password":
      {
        gNotifier.value = "";
        gNotifier.value = "change-password";
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

void utilPickDirectory(TextEditingController selectDir) async {
  String? selected = await FilePicker.platform.getDirectoryPath();
  if (selected == null) {
    // User canceled the picker
    return;
  }
  selectDir.text = selected;
}

/*
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
          buttonOnTap(context, tooltip);
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
}*/
