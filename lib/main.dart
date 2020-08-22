import 'package:clack/api.dart';
import 'package:clack/views/full_image.dart';
import 'package:clack/views/sign_in_webview.dart';
import 'package:clack/views/sound_group.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';

import 'views/video_feed.dart';

void main() async {
  // Needed to ensure API can be initialized before app starts
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait only
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Initialize the API
  await API.init();

  // Run the app
  return runApp(Phoenix(child: MyApp()));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Clack',
        initialRoute: VideoFeed.routeName,
        routes: {
          VideoFeed.routeName: (ctx) => VideoFeed(),
          FullImage.routeName: (ctx) => FullImage(),
          SoundGroup.routeName: (ctx) => SoundGroup(),
          SignInWebview.routeName: (ctx) => SignInWebview()
        });
  }
}
