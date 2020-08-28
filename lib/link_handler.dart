import 'dart:async';

import 'package:clack/fragments/HashtagInfoFragment.dart';
import 'package:clack/fragments/MusicPlayerFragment.dart';
import 'package:clack/utility.dart';
import 'package:clack/views/user_info.dart';
import 'package:clack/views/video_feed.dart';
import 'package:clack/views/video_group.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tuple/tuple.dart';
import 'package:uni_links/uni_links.dart';

import 'api.dart';
import 'api/api_stream.dart';
import 'api/hashtag_result.dart';
import 'api/shared_types.dart';

class LinkHandler extends StatefulWidget {
  static const String routeName = "/link";

  /// The initial widget to display before loading the (possible) link
  final Widget initialWidget;

  const LinkHandler({@required this.initialWidget});

  @override
  _LinkHandlerState createState() => _LinkHandlerState();
}

class _LinkHandlerState extends State<LinkHandler> {
  StreamSubscription _sub;

  @override
  void initState() {
    super.initState();

    // Subscribe to links while running
    _sub = getUriLinksStream().listen((Uri uri) async {
      print("LINK TIME: $uri");
      _spawnLinkPage(uri);
    }, onError: (e) => _showErrorAlert(e.toString()));

    // Handle cold starts
    _coldInit();
  }

  @override
  void dispose() {
    _sub.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.initialWidget;

  // Handle cold-boot links
  void _coldInit() async {
    try {
      String initialLink = await getInitialLink();
      if (initialLink != null) {
        final link = Uri.parse(initialLink);
        _spawnLinkPage(link);
      }
    } on PlatformException {
      _showErrorAlert("Malformed link");
    }
  }

  void _spawnLinkPage(Uri link) async {
    // If we have just the homepage, do nothing
    if (link.pathSegments.isEmpty) return;

    String topLevel = link.pathSegments[0];
    print("TOP LEVEL: $topLevel");

    Tuple2<String, dynamic> args;

    // Video requires regexp, so separate
    if (topLevel.startsWith("@")) {
      print("UNIQUE ID: $topLevel");
      String uniqueId = topLevel.substring(1);

      // Chekc if we are opening a user's page, or a specific video
      if (link.pathSegments.length == 1)
        args = Tuple2(
            UserInfo.routeName,
            UserInfoArgs(
              authorGetter: () => Author(uniqueId: uniqueId),
              onBack: (ctx) {
                Navigator.of(ctx).pop();
                return Future.value();
              },
            ));
      else if (link.pathSegments.length == 3)
        args = Tuple2(
            VideoFeed.routeName,
            VideoFeedArgs(
                ApiStream(
                  1,
                  (count, cursor) async => ApiResult(
                      false, 0, [await API.getVideoInfo(link.pathSegments[2])]),
                ),
                0,
                1));
      else
        _showErrorAlert("Malformed user link: $link");
    } else {
      // Verify that we have info
      if (link.pathSegments.length < 2 || link.pathSegments[1].isEmpty)
        _showErrorAlert("Malformed link: $link");

      switch (topLevel) {
        // Music
        case "music":
          {
            int start = link.pathSegments[1].indexOf(RegExp("[0-9]+\$"));
            String musicId = link.pathSegments[1].substring(start);

            print("MUSIC: $musicId");
            Music m = await API.getMusicInfo(musicId);
            args = Tuple2(
                VideoGroup.routeName,
                VideoGroupArguments(
                  stream: API.getVideosForMusic(m, 20),
                  headerBuilder: () => MusicPlayerFragment(musicInfo: m),
                  getShare: (shareExtra) => getMusicShare(m, shareExtra),
                ));
            break;
          }
        // Hashtags
        case "tag":
          {
            // Fetch info on the hashtag first
            String htName = link.pathSegments[1];
            print("GOT HASHTAG NAME: $htName");

            HashtagResult ht = await API.getHashtagInfo(htName);
            print("GOT HASHTAG OBJ: ${ht.id} -> ${ht.title}");
            args = Tuple2(
                VideoGroup.routeName,
                VideoGroupArguments(
                    stream: API.getVideosForHashtag(ht, 20),
                    headerBuilder: () => HashtagInfoFragment(
                        initialHashtag: ht, initialIsActual: true),
                    getShare: (shareExtra) => getHashtagShare(ht, shareExtra)));

            break;
          }
        default:
          {
            return _showErrorAlert("Unknown link: ${link.toString()}");
          }
      }
    }

    Navigator.of(context).pushNamed(args.item1, arguments: args.item2);
  }

  void _showErrorAlert(String msg) => showDialog(
      context: context,
      child: AlertDialog(
        content: Text("Could not open link! :( \n\nReason: $msg"),
        actions: [
          FlatButton(
            child: Text("OK"),
            onPressed: () => Navigator.of(context).pop(),
          )
        ],
      ));
}
