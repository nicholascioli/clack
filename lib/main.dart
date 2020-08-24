import 'package:clack/api.dart';
import 'package:clack/utility.dart';
import 'package:clack/views/full_image.dart';
import 'package:clack/views/settings.dart';
import 'package:clack/views/sign_in_webview.dart';
import 'package:clack/views/sound_group.dart';
import 'package:clack/views/user_info.dart';
import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'views/video_feed.dart';

void main() async {
  // Needed to ensure API can be initialized before app starts
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait only
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Initialize the API
  await API.init();

  // Run the app
  return runApp(
      Phoenix(child: MyApp(prefs: await SharedPreferences.getInstance())));
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;

  const MyApp({this.prefs});

  @override
  Widget build(BuildContext context) {
    return new DynamicTheme(
        // FIXME: This is nasty
        defaultBrightness:
            MediaQueryData.fromWindow(WidgetsBinding.instance.window)
                .platformBrightness,
        data: (brightness) => createTheme(
            context: context,
            brightness: brightness,
            primaryColor: getThemeColor(prefs, SettingsView.themePrimaryColor),
            bottomBarColor:
                getThemeColor(prefs, SettingsView.themeBottomBarColor),
            iconColor: getThemeColor(prefs, SettingsView.themeIconColor)),
        themedWidgetBuilder: (context, theme) => MaterialApp(
            title: 'Clack',
            initialRoute: VideoFeed.routeName,
            routes: {
              VideoFeed.routeName: (ctx) => VideoFeed(),
              FullImage.routeName: (ctx) => FullImage(),
              SoundGroup.routeName: (ctx) => SoundGroup(),
              SignInWebview.routeName: (ctx) => SignInWebview(),
              SettingsView.routeName: (ctx) => SettingsView(),
              UserInfo.routeName: (ctx) => UserInfo.fromNamed(ctx)
            },
            theme: theme));
  }
}
