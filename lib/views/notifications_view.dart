import 'package:clack/utility.dart';
import 'package:clack/views/video_feed.dart';
import 'package:flutter/material.dart';

class NotificationView extends StatelessWidget {
  final void Function(VideoFeedActivePage active) setActive;
  const NotificationView(this.setActive);

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
                  icon: Icon(Icons.send),
                  onPressed: () => showNotImplemented(context))
            ],
            title: Text("All Activity"),
          ),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.notifications_none, size: 80, color: Colors.grey),
                SizedBox(height: 20),
                Text("Messages and notifications will appear here"),
                SizedBox(height: 20),
                RaisedButton(
                    child: Text("Sign up"),
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
