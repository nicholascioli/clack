import 'package:clack/utility.dart';
import 'package:clack/views/video_feed.dart';
import 'package:flutter/material.dart';

class ProfileView extends StatelessWidget {
  final void Function(VideoFeedActivePage active) setActive;
  const ProfileView(this.setActive);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () => _handleBack(),
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () => _handleBack(),
            ),
            actions: [
              IconButton(
                  icon: Icon(Icons.settings),
                  onPressed: () => showNotImplemented(context))
            ],
            title: Text("Profile"),
          ),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_outline, size: 80, color: Colors.grey),
                SizedBox(height: 20),
                Text("Sign up for an account"),
                SizedBox(height: 20),
                FlatButton(
                    child: Text("Sign up"),
                    color: Colors.pink,
                    textColor: Colors.white,
                    onPressed: () => showNotImplemented(context))
              ],
            ),
          ),
        ));
  }

  Future<bool> _handleBack() {
    // Go back to the videos on back
    setActive(VideoFeedActivePage.VIDEO);

    return Future.value(false);
  }
}
