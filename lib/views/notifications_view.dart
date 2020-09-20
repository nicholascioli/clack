import 'package:clack/api.dart';
import 'package:clack/fragments/NotificationFragment.dart';
import 'package:clack/generated/locale_keys.g.dart';
import 'package:clack/utility.dart';
import 'package:clack/views/sign_in_webview.dart';
import 'package:clack/views/video_feed.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class NotificationView extends StatefulWidget {
  final void Function(VideoFeedActivePage active) setActive;

  const NotificationView(this.setActive);

  @override
  _NotificationViewState createState() => _NotificationViewState();
}

class _NotificationViewState extends State<NotificationView> {
  @override
  void initState() {
    // Setup callback
    API.notifications.setOnChanged(() => setState(() {}));

    // Prefetch some results
    API.notifications.preload();

    super.initState();
  }

  @override
  void dispose() {
    API.notifications.setOnChanged(() {});

    super.dispose();
  }

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
              icon: Icon(Icons.inbox),
              onPressed: () => showNotImplemented(context),
            )
          ],
          title: Text(LocaleKeys.page_notifications).tr(),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) => RefreshIndicator(
            onRefresh: () async => await API.notifications.refresh(),
            child: API.notifications.length != 0
                ? ListView.builder(
                    itemBuilder: (context, index) => NotificationFragment(
                        notification: API.notifications[index]),
                    itemCount: API.notifications.length,
                  )
                : _emptyList(constraints),
          ),
        ),
      ),
    );
  }

  Widget _emptyList(BoxConstraints constraints) => SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: constraints.maxHeight,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.notifications_none, size: 80, color: Colors.grey),
                SizedBox(height: 20),
                Text(LocaleKeys.notifications_empty).tr(),

                // Only show the log in button when not logged in
                Visibility(
                  visible: !API.isLoggedIn(),
                  child: Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: RaisedButton(
                      child: Text(LocaleKeys.sign_in).tr(),
                      onPressed: () => Navigator.of(context).pushNamed(
                        SignInWebview.routeName,
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      );

  Future<bool> _handleBack() {
    // Go back to the videos on back
    widget.setActive(VideoFeedActivePage.VIDEO);

    return Future.value(false);
  }
}
