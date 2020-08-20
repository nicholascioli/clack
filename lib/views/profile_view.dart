import 'package:clack/api.dart';
import 'package:clack/views/sign_in_webview.dart';
import 'package:clack/views/user_info.dart';
import 'package:clack/views/video_feed.dart';
import 'package:flutter/material.dart';

class ProfileView extends StatefulWidget {
  final void Function(VideoFeedActivePage active) setActive;
  const ProfileView(this.setActive);

  @override
  _ProfileViewState createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  @override
  Widget build(BuildContext context) =>
      API.isLoggedIn() ? UserInfo.currentUser() : _buildAnonymous();

  Widget _buildAnonymous() => WillPopScope(
      onWillPop: () => _handleBack(),
      child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () => _handleBack(),
            ),
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
                    onPressed: () =>
                        Navigator.pushNamed(context, SignInWebview.routeName))
              ],
            ),
          )));

  Future<bool> _handleBack() {
    // Go back to the videos on back
    widget.setActive(VideoFeedActivePage.VIDEO);

    return Future.value(false);
  }
}
