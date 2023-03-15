import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_boxicons/flutter_boxicons.dart';
import 'package:flutter_window_close/flutter_window_close.dart';
import 'package:path/path.dart' as path;
import 'package:textvault/theme/color.dart';
import 'package:textvault/utils/home_dir.dart';
import 'package:textvault/utils/math.dart';
import 'package:textvault/utils/number.dart';
import 'package:textvault/utils/url.dart';
import 'package:textvault/widgets/widget_alert_dialog.dart';
import 'package:textvault/widgets/widget_tab_view.dart';
import 'package:textvault/widgets/widget_toolbar.dart';

/// TextFormField content will disappear if user switch tabs(lost focus) or resize window.
/// If user want to keep text of TextFormField, there are 3 things must be done:
/// 1, controller: TextEditingController(text: aGlobalStringVar)
/// 2, onChanged: (newText) { aGlobalStringVar = newText; }
/// 3, define aGlobalStringVar in global variant area.

const gTvHeader = 'tvheader';
const gMinPwdLen = 8;
const gMinFileSize = 18;
const btnNameNewFile = 'New File';
const btnNameOpenFile = 'Open File';
const btnNameSaveFile = 'Save File';
const btnNameChangePassword = 'Change Password';
const btnNameUndo = 'Undo';
const btnNameRedo = 'Redo';
const btnNameFindReplace = 'Find Replace';
const btnNameSettings = 'Settings';
const btnNameGithubRepository = 'Github Repository';

class RetHistoryItem {
  bool isOk = false;
  String content = '';
  int cursorPos = 0;
}

class _HistoryItem {
  _HistoryItem({
    required this.content,
    required this.cursorPos,
  });

  String content;
  int cursorPos;
}

class _History {
  final List<_HistoryItem> _items = [];
  int _currVer = -1;
  final int _maxUndo = 50;

  onChanged(String content, int cursorPos) {
    // if length greater or equal to max limit, remove some oldest elements.
    for (; _items.length >= _maxUndo;) {
      _items.removeAt(0);
    }

    // if content didn't be changed, no need to do anything.
    if (_items.isNotEmpty &&
        _currVer >= 0 &&
        _items.elementAt(_currVer).content == content) {
      return;
    }

    // remove all elements after `_currVer`
    for (; _items.length - 1 > _currVer;) {
      _items.removeLast();
    }

    // add new element
    _items.add(_HistoryItem(content: content, cursorPos: cursorPos));
    _currVer = _items.length - 1;
  }

  clearAll() {
    _items.clear();
    _currVer = -1;
  }

  bool canUndo() {
    return _currVer > 0;
  }

  RetHistoryItem undo() {
    RetHistoryItem ret = RetHistoryItem();

    if (!canUndo()) {
      ret.isOk = false;
      return ret;
    }

    _currVer--;
    ret.isOk = true;
    ret.content = _items.elementAt(_currVer).content;
    ret.cursorPos = _items.elementAt(_currVer).cursorPos;
    return ret;
  }

  bool canRedo() {
    return _currVer >= 0 && _currVer < _items.length - 1;
  }

  RetHistoryItem redo() {
    RetHistoryItem ret = RetHistoryItem();

    if (!canRedo()) {
      ret.isOk = false;
      return ret;
    }

    _currVer++;
    ret.isOk = true;
    ret.content = _items.elementAt(_currVer).content;
    ret.cursorPos = _items.elementAt(_currVer).cursorPos;
    return ret;
  }
}

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

  final _history = _History();
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
          final crypt = enc.Encrypter(
              enc.AES(key, mode: enc.AESMode.ctr, padding: 'PKCS7'));
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

    // add first version to history list
    if (errMsg.isEmpty && _history._items.isEmpty) {
      _history.onChanged(content, 0);
    }

    return errMsg;
  }

  historyOnChanged(String content, int cursorPos) {
    _history.onChanged(content, cursorPos);
  }

  historyClearAndKeepLatest() {
    _history.clearAll();
    // keep latest version to history list
    _history.onChanged(content, ctrlContent.selection.baseOffset);
  }

  bool historyCanUndo() {
    return _history.canUndo();
  }

  RetHistoryItem historyUndo() {
    return _history.undo();
  }

  bool historyCanRedo() {
    return _history.canRedo();
  }

  RetHistoryItem historyRedo() {
    return _history.redo();
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
final gPageMainNotifier = ValueNotifier("");

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
                    gPageMainNotifier.value = "";
                    gPageMainNotifier.value = "close-file:$index";
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
              gPageMainNotifier.value = "";
              gPageMainNotifier.value =
                  'open-file:${gConfig.recentOpen[index]}';
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

// main page
class PageMain extends StatefulWidget {
  const PageMain({
    super.key,
  });

  @override
  PageMainState createState() => PageMainState();
}

class PageMainState extends State<PageMain> {
  @override
  void initState() {
    super.initState();
    gPageMainNotifier
        .addListener(update); // add listen callback for `gPageMainNotifier`

    // Intercept the window close event, and decide whether to exit the
    // application according to the user's choice. This method only works
    // on the Linux/macOS/Windows desktop side.
    FlutterWindowClose.setWindowShouldCloseHandler(() async {
      var editedCount = 0;
      gDocs.forEach((key, value) {
        if (value.edited) {
          editedCount++;
        }
      });
      var documentStr = editedCount > 1 ? 'documents' : 'document';
      if (editedCount > 0) {
        return await showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                  title: Text(
                      '$editedCount $documentStr need to be saved, do you really want to quit without saving?'),
                  actions: [
                    ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Quit')),
                    ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Don\'t Quit')),
                  ]);
            });
      } else {
        // quit app
        return true;
      }
    });
  }

  @override
  void dispose() {
    gPageMainNotifier.removeListener(
        update); // remove listen callback for `gPageMainNotifier`
    super.dispose();
  }

// listen callback of `gPageMainNotifier`
  void update() {
    //setState(() {});
    if (gPageMainNotifier.value == 'new-file') {
      addTab("untitled-${gDocs.length}.tv", "", "", "", 0);
    } else if (gPageMainNotifier.value.startsWith("open-file:")) {
      var toOpenFilepath = gPageMainNotifier.value.replaceAll("open-file:", "");
      String basename = path.basename(File(toOpenFilepath).path);
      addTab(basename, "", "", toOpenFilepath, 1);
    } else if (gPageMainNotifier.value.startsWith("close-file:")) {
      var toRemoveIdx = gPageMainNotifier.value.replaceAll("close-file:", "");
      if (gDocs[int.parse(toRemoveIdx)]!.edited) {
        showChoiceDialog(
            context,
            "Close Tab Warning",
            'Current document has been edited, do you really want to close it without saving?',
            ['Close', 'Don\'t Close']).then((choice) {
          // `choice` is from `Navigator.of(context).pop` in showChoiceDialog implement.
          if (choice == 'Close') {
            delTab(int.parse(toRemoveIdx));
          }
        });
      } else {
        // close tab
        delTab(int.parse(toRemoveIdx));
      }
    } else if (gPageMainNotifier.value == 'change-password') {
      if (gSelectedTabIndex >= 1 &&
          gDocs[gSelectedTabIndex]!.selectedTab == 2) {
        // `setState` is necessary for switching tab right now
        setState(() {
          gDocs[gSelectedTabIndex]!.selectedTab = 3;
        });
      }
    } else if (gPageMainNotifier.value == 'save-file') {
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

      gDocs[gSelectedTabIndex]!.historyClearAndKeepLatest();
      gToolbarNotifier.value = 'update toolbar:${getRandomString(10)}';
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
      print("current main tab $gSelectedTabIndex");
      gTabViewSetStateNotifier.value = "";
      gTabViewSetStateNotifier.value = "update TabBars' color";
    });

    gToolbarNotifier.value = 'update toolbar:${getRandomString(10)}';
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
            TooltipIcon(
              onTap: onToolbarBtnTap,
              icon: Icons.create,
              tooltip: btnNameNewFile,
              enable: () {
                return true;
              },
            ),
            TooltipIcon(
              onTap: onToolbarBtnTap,
              icon: Icons.file_open,
              tooltip: btnNameOpenFile,
              enable: () {
                return true;
              },
            ),
            TooltipIcon(
              onTap: onToolbarBtnTap,
              icon: Icons.save,
              tooltip: btnNameSaveFile,
              enable: () {
                if (gDocs[gSelectedTabIndex] == null) {
                  return false;
                }
                return (gSelectedTabIndex > 0 &&
                    gDocs[gSelectedTabIndex]!.edited &&
                    gDocs[gSelectedTabIndex]!.selectedTab == 2);
              },
            ),
            TooltipIcon(
              onTap: onToolbarBtnTap,
              icon: Icons.password,
              tooltip: btnNameChangePassword,
              enable: () {
                if (gDocs[gSelectedTabIndex] == null) {
                  return false;
                }
                return (gSelectedTabIndex > 0 &&
                    !gDocs[gSelectedTabIndex]!.edited &&
                    gDocs[gSelectedTabIndex]!.selectedTab == 2);
              },
            ),
            TooltipIcon(
              onTap: onToolbarBtnTap,
              icon: Icons.undo,
              tooltip: btnNameUndo,
              enable: () {
                if (gDocs[gSelectedTabIndex] == null) {
                  return false;
                }
                return (gSelectedTabIndex > 0 &&
                    gDocs[gSelectedTabIndex]!.selectedTab == 2 &&
                    gDocs[gSelectedTabIndex]!.historyCanUndo());
              },
            ),
            TooltipIcon(
              onTap: onToolbarBtnTap,
              icon: Icons.redo,
              tooltip: btnNameRedo,
              enable: () {
                if (gDocs[gSelectedTabIndex] == null) {
                  return false;
                }
                return (gSelectedTabIndex > 0 &&
                    gDocs[gSelectedTabIndex]!.selectedTab == 2 &&
                    gDocs[gSelectedTabIndex]!.historyCanRedo());
              },
            ),
            TooltipIcon(
              onTap: onToolbarBtnTap,
              icon: Icons.find_replace,
              tooltip: btnNameFindReplace,
              enable: () {
                if (gDocs[gSelectedTabIndex] == null) {
                  return false;
                }
                return (gSelectedTabIndex > 0 &&
                    gDocs[gSelectedTabIndex]!.selectedTab == 2);
              },
            ),
            VerticalDivider(
              endIndent: 10,
              indent: 10,
              color: Theme.of(context).colorScheme.barIconColor,
            ),
            TooltipIcon(
              onTap: onToolbarBtnTap,
              icon: Icons.settings,
              tooltip: btnNameSettings,
              enable: () {
                return true;
              },
            ),
            TooltipIcon(
              onTap: onToolbarBtnTap,
              icon: Boxicons.bxl_github,
              tooltip: btnNameGithubRepository,
              enable: () {
                return true;
              },
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
        print("current main tab $index");
        gTabViewSetStateNotifier.value = "";
        gTabViewSetStateNotifier.value = "update TabBars' color";
        gToolbarNotifier.value = 'update toolbar:${getRandomString(10)}';
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
            gDocs[widget.tabIndex]!.historyOnChanged(newText,
                gDocs[widget.tabIndex]!.ctrlContent.selection.baseOffset);

            gTabViewSetStateNotifier.value = '';
            gTabViewSetStateNotifier.value = 'random data';
            gToolbarNotifier.value = 'update toolbar:${getRandomString(10)}';
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
                    'Enter the password again to confirm that it was entered correctly'),
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
                    'Enter the password again to confirm that it was entered correctly'),
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
        print('current sub tab $newIndex');
        gDocs[widget.tabIndex]!.selectedTab = newIndex;
        gToolbarNotifier.value = 'update toolbar:${getRandomString(10)}';
      },
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
  gPageMainNotifier.value = "";
  gPageMainNotifier.value = 'open-file:$toOpen';
}

void onToolbarBtnTap(BuildContext context, String btnName) {
  switch (btnName) {
    case btnNameNewFile:
      {
        gPageMainNotifier.value = "";
        gPageMainNotifier.value = "new-file";
      }
      break;

    case btnNameOpenFile:
      {
        openOneTvFile(context);
      }
      break;

    case btnNameSaveFile:
      {
        gPageMainNotifier.value = "";
        gPageMainNotifier.value = "save-file";
      }
      break;

    case btnNameChangePassword:
      {
        gPageMainNotifier.value = "";
        gPageMainNotifier.value = "change-password";
      }
      break;

    case btnNameUndo:
      {
        var ret = gDocs[gSelectedTabIndex]!.historyUndo();
        if (ret.isOk) {
          gDocs[gSelectedTabIndex]!.ctrlContent.text = ret.content;
          gDocs[gSelectedTabIndex]!.ctrlContent.selection =
              TextSelection.collapsed(offset: ret.cursorPos);
        }
        gToolbarNotifier.value = 'update toolbar:${getRandomString(10)}';
      }
      break;

    case btnNameRedo:
      {
        var ret = gDocs[gSelectedTabIndex]!.historyRedo();
        if (ret.isOk) {
          gDocs[gSelectedTabIndex]!.ctrlContent.text = ret.content;
          gDocs[gSelectedTabIndex]!.ctrlContent.selection =
              TextSelection.collapsed(offset: ret.cursorPos);
        }
        gToolbarNotifier.value = 'update toolbar:${getRandomString(10)}';
      }
      break;

    case btnNameFindReplace:
      {}
      break;

    case btnNameSettings:
      {
        Navigator.pushNamed(context, '/pageSettings');
      }
      break;

    case btnNameGithubRepository:
      {
        launchURL('https://github.com/davidforest123/TextVault');
      }
      break;

    default:
      {}
      break;
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
