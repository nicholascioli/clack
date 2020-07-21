import 'package:clack/views/full_image.dart';
import 'package:clack/views/sound_group.dart';
import 'package:flutter/material.dart';

import 'views/video_feed.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Clack',
        initialRoute: VideoFeed.routeName,
        routes: {
          VideoFeed.routeName: (ctx) => VideoFeed(),
          FullImage.routeName: (ctx) => FullImage(),
          SoundGroup.routeName: (ctx) => SoundGroup()
        });
  }
}
