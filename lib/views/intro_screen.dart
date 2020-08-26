import 'dart:async';

import 'package:flutter/material.dart';

/// An intro screen to use when first opening the app
class IntroScreen extends StatefulWidget {
  final Future<Widget> Function() nextScreenBuilder;
  final Color color;

  const IntroScreen({@required this.nextScreenBuilder, @required this.color});

  @override
  _IntroScreenState createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen>
    with SingleTickerProviderStateMixin {
  Future<Widget> _future;
  Widget _next;

  @override
  void initState() {
    // Set up view
    _future = widget.nextScreenBuilder();

    // Kill self after future finishes
    _future.then((value) => setState(() => _next = value));

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return _next != null
        ? _next
        : MaterialApp(
            home: Container(
                color: Colors.black,
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Spacer(),
                      Flexible(
                          flex: 4,
                          child: Row(children: [
                            Spacer(),
                            Flexible(
                                flex: 2,
                                child: Image.asset("icons/launcher_icon.png")),
                            Spacer()
                          ])),
                      Flexible(
                          flex: 1,
                          child: CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(widget.color))),
                      Spacer()
                    ])));
  }
}
