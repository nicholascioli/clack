import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

/// An intro screen to use when first opening the app
// TODO: Create a logo
class IntroScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
          color: Colors.orange,
          child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.all_inclusive, color: Colors.white, size: 100),
            SizedBox(
              height: 20,
            ),
            SpinKitCubeGrid(color: Colors.white)
          ]))),
    );
  }
}
