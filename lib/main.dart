import 'dart:async';

import 'package:clack/api.dart';
import 'package:clack/link_handler.dart';
import 'package:clack/utility.dart';
import 'package:clack/views/full_image.dart';
import 'package:clack/views/intro_screen.dart';
import 'package:clack/views/settings.dart';
import 'package:clack/views/sign_in_webview.dart';
import 'package:clack/views/video_group.dart';
import 'package:clack/views/user_info.dart';
import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'views/video_feed.dart';

void main() {
  // Needed to ensure API can be initialized before app starts
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait only
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Run the app (with splash screen while loading)
  return runApp(Phoenix(
      child: EasyLocalization(
          supportedLocales: [Locale("en", "US"), Locale("it", "IT")],
          path: "i18n",
          fallbackLocale: Locale("en", "US"),
          preloaderColor: Colors.black,
          saveLocale: true,
          child: IntroScreen(
              nextScreenBuilder: (BuildContext context) async {
                // Allow the animation to fully play out
                await Future.delayed(const Duration(seconds: 1));

                // Initialize the downloader
                await FlutterDownloader.initialize();

                // Initialize the API
                await API.init(context.locale.languageCode);

                // Set app defaults
                SharedPreferences prefs = await SharedPreferences.getInstance();
                void Function(String key, dynamic value,
                        Future Function(String, dynamic) method) initPref =
                    (key, value, method) {
                  if (!prefs.containsKey(key)) {
                    method(key, value);
                  }
                };
                var setBool =
                    (String key, dynamic value) => prefs.setBool(key, value);
                var setString =
                    (String key, dynamic value) => prefs.setString(key, value);
                // var setInt = (String key, dynamic value) => prefs.setInt(key, value);

                // Initialize the settings, if not present
                initPref(SettingsView.videoFullQualityKey, false, setBool);
                initPref(SettingsView.advancedUserAgentKey, API.USER_AGENT,
                    setString);

                // Run the app
                return MyApp(prefs: prefs);
              },
              color: Colors.white))));
}

class MyApp extends StatefulWidget {
  final SharedPreferences prefs;

  const MyApp({this.prefs});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
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
            primaryColor:
                getThemeColor(widget.prefs, SettingsView.themePrimaryColor),
            bottomBarColor:
                getThemeColor(widget.prefs, SettingsView.themeBottomBarColor),
            iconColor:
                getThemeColor(widget.prefs, SettingsView.themeIconColor)),
        themedWidgetBuilder: (context, theme) => MaterialApp(
            title: 'Clack',
            initialRoute: LinkHandler.routeName,
            routes: {
              LinkHandler.routeName: (ctx) =>
                  LinkHandler(initialWidget: VideoFeed()),
              VideoFeed.routeName: (ctx) => VideoFeed(),
              FullImage.routeName: (ctx) => FullImage(),
              VideoGroup.routeName: (ctx) => VideoGroup(),
              SignInWebview.routeName: (ctx) => SignInWebview(),
              SettingsView.routeName: (ctx) => SettingsView(),
              UserInfo.routeName: (ctx) => UserInfo.fromNamed(ctx)
            },
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            theme: theme));
  }
}
