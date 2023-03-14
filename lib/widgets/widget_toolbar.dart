// toolbar icon button
import 'package:flutter/material.dart';

typedef BoolCallback = bool Function();
typedef OnTapCallback = void Function(BuildContext context, String btnName);

// notify toolbar to run setState(refresh UI).
final gToolbarNotifier = ValueNotifier("");

class TooltipIcon extends StatefulWidget {
  TooltipIcon({
    required this.onTap,
    required this.icon,
    required this.tooltip,
    required this.enable,
    Key? key,
  }) : super(key: key);

  final OnTapCallback onTap;
  final IconData icon;
  final String tooltip;
  final BoolCallback enable;
  bool enabled = false;

  @override
  TooltipIconState createState() => TooltipIconState();
}

// toolbar icon button
class TooltipIconState extends State<TooltipIcon> {
  @override
  void initState() {
    super.initState();
    gToolbarNotifier.addListener(update); // add listen callback for `gNotifier`
  }

  @override
  void dispose() {
    gToolbarNotifier
        .removeListener(update); // remove listen callback for `gNotifier`
    super.dispose();
  }

  void update() {
    setState(() {
      widget.enabled = widget.enable();
    });
  }

  @override
  Widget build(BuildContext context) {
    // This is necessary to setup correct 'enabled' value when toolbar initialized.
    // If it is called in `initState()`, it will not achieve the desired effect.
    update();

    return Tooltip(
      message: widget.enabled ? widget.tooltip : '',
      child: InkWell(
        onTap: () {
          widget.onTap(
              context,
              widget.enabled
                  ? widget.tooltip
                  : ''); //onToolbarBtnTap(context, widget.enabled ? widget.tooltip : '');
        },
        child: SizedBox(
          width: 40,
          height: 40,
          child: Center(
            child: Icon(
              widget.icon,
              size: 25,
              color: widget.enabled
                  ? Colors.black54
                  : Colors.black54.withOpacity(0.3),
            ),
          ),
        ),
      ),
    );
  }
}
