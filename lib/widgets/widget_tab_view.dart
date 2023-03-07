import 'package:flutter/material.dart';

final gTabViewSetStateNotifier = ValueNotifier("");

class WidgetTabView extends StatefulWidget {
  const WidgetTabView({
    super.key,
    required this.itemCount,
    required this.tabBuilder,
    required this.pageBuilder,
    this.stub,
    this.onPositionChange,
    this.onScroll,
    this.initPosition,
  });

  final int itemCount;
  final IndexedWidgetBuilder tabBuilder;
  final IndexedWidgetBuilder pageBuilder;
  final Widget? stub;
  final ValueChanged<int>? onPositionChange;
  final ValueChanged<double>? onScroll;
  final int? initPosition;

  @override
  WidgetTabsState createState() => WidgetTabsState();
}

class WidgetTabsState extends State<WidgetTabView>
    with TickerProviderStateMixin {
  late TabController controller;
  late int _currentCount;
  late int _currentPosition;

  @override
  void initState() {
    gTabViewSetStateNotifier.addListener(
        setStateCallback); // add listen callback for `gTabViewSetStateNotifier`
    _currentPosition = widget.initPosition ?? 0;
    controller = TabController(
      length: widget.itemCount,
      vsync: this,
      initialIndex: _currentPosition,
    );
    controller.addListener(onPositionChange);
    controller.animation!.addListener(onScroll);
    _currentCount = widget.itemCount;
    super.initState();
  }

  @override
  void didUpdateWidget(WidgetTabView oldWidget) {
    if (_currentCount != widget.itemCount) {
      controller.animation!.removeListener(onScroll);
      controller.removeListener(onPositionChange);
      controller.dispose();

      if (widget.initPosition != null) {
        _currentPosition = widget.initPosition!;
      }

      if (_currentPosition > widget.itemCount - 1) {
        _currentPosition = widget.itemCount - 1;
        _currentPosition = _currentPosition < 0 ? 0 : _currentPosition;
        if (widget.onPositionChange is ValueChanged<int>) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && widget.onPositionChange != null) {
              widget.onPositionChange!(_currentPosition);
            }
          });
        }
      }

      _currentCount = widget.itemCount;
      setState(() {
        controller = TabController(
          length: widget.itemCount,
          vsync: this,
          initialIndex: _currentPosition,
        );
        controller.addListener(onPositionChange);
        controller.animation!.addListener(onScroll);
      });
    } else if (widget.initPosition != null) {
      controller.animateTo(widget.initPosition!);
    }

    super.didUpdateWidget(oldWidget);
  }

  // listen callback of `gNotifier`
  void setStateCallback() {
    setState(() {});
  }

  @override
  void dispose() {
    gTabViewSetStateNotifier.removeListener(
        setStateCallback); // remove listen callback for `gNotifier`
    controller.animation!.removeListener(onScroll);
    controller.removeListener(onPositionChange);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.itemCount < 1) return widget.stub ?? Container();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          // TabBar background color, it is also the color of unselected tab,
          // because tab is transparent here.
          color: Colors.grey.withOpacity(0.2),
          alignment: Alignment.center,
          child: TabBar(
            // Set false can remove extra space on the left/right of tabs.
            isScrollable: false,
            controller: controller,
            // selected tab text color
            labelColor: Theme.of(context).primaryColor,
            // unselected tab text color
            unselectedLabelColor: Theme.of(context).hintColor,
            // Adjust the spacing between the tabs, it is an important option,
            // it also changes the width of indicator(the selected tab).
            // If it is not set as 0, `indicator.BoxDecoration.color` will not cover a whole tabBar.
            labelPadding: const EdgeInsets.symmetric(horizontal: 0),
            indicator: BoxDecoration(
              // indicator background color, covers a whole TabBar.
              color: Theme.of(context).cardColor,
              border: const Border(
                bottom: BorderSide(
                  // hide the bottom line inside the indicator
                  color: Colors.transparent, //Theme.of(context).primaryColor,
                ),
              ),
            ),
            // hide the bottom line outside the indicator
            indicatorWeight: 0,
            tabs: List.generate(
              widget.itemCount,
              (index) => widget.tabBuilder(context, index),
            ),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: controller,
            children: List.generate(
              widget.itemCount,
              (index) => widget.pageBuilder(context, index),
            ),
          ),
        ),
      ],
    );
  }

  void onPositionChange() {
    if (!controller.indexIsChanging) {
      _currentPosition = controller.index;
      if (widget.onPositionChange is ValueChanged<int>) {
        widget.onPositionChange!(_currentPosition);
      }
    }
  }

  void onScroll() {
    if (widget.onScroll is ValueChanged<double>) {
      widget.onScroll!(controller.animation!.value);
    }
  }
}
