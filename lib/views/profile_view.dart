import 'package:clack/api.dart';
import 'package:clack/views/settings.dart';
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
  List<Widget> _actions;

  @override
  void initState() {
    // Set up actions
    _actions = [
      IconButton(
          icon: Icon(Icons.settings),
          onPressed: () => Navigator.pushNamed(context, SettingsView.routeName))
    ];

    super.initState();
  }

  @override
  Widget build(BuildContext context) => API.isLoggedIn()
      ? UserInfo.currentUser(
          parentActions: _actions, onBack: (_) => _handleBack())
      : _buildAnonymous();

  Widget _buildAnonymous() => WillPopScope(
      onWillPop: () => _handleBack(),
      child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () => _handleBack(),
            ),
            title: Text("Profile"),
            actions: _actions,
          ),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_outline, size: 80, color: Colors.grey),
                SizedBox(height: 20),
                Text("Sign in to view your account"),
                SizedBox(height: 20),
                RaisedButton(
                    child: Text("Sign in"),
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
