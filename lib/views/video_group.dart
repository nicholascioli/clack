import 'package:clack/api/api_stream.dart';
import 'package:clack/api/video_result.dart';
import 'package:clack/fragments/GridFragment.dart';
import 'package:flutter/material.dart';
import 'package:share/share.dart';

class VideoGroupArguments {
  final Widget Function() headerBuilder;
  final ApiStream<VideoResult> stream;
  final String Function() getShare;

  const VideoGroupArguments(
      {@required this.stream,
      @required this.headerBuilder,
      @required this.getShare});
}

class VideoGroup extends StatefulWidget {
  static final routeName = "/video_group";

  @override
  _VideoGroupState createState() => _VideoGroupState();
}

class _VideoGroupState extends State<VideoGroup> {
  Widget Function() _headerBuilder;
  ApiStream<VideoResult> _videos;
  bool _hasInit = false;
  String Function() _getShare;

  @override
  Widget build(BuildContext context) {
    // Extract the stream from the arguments
    if (!_hasInit) {
      VideoGroupArguments args = ModalRoute.of(context).settings.arguments;
      _headerBuilder = args.headerBuilder;
      _videos = args.stream;
      _videos.setOnChanged(() {
        if (mounted)
          setState(() {
            print("UPDATE!: ${_videos[0]}");
          });
      });
      _getShare = args.getShare;
      _hasInit = true;
    }

    return Scaffold(
        appBar: AppBar(actions: [
          IconButton(
              icon: Icon(Icons.share),
              onPressed: () => Share.share(_getShare()))
        ]),
        body: _buildPage());
  }

  Widget _buildPage() => CustomScrollView(slivers: [
        SliverPadding(
            padding: EdgeInsets.only(top: 20, bottom: 20),
            sliver: SliverToBoxAdapter(child: _headerBuilder())),
        GridFragment(
            asSliver: true,
            stream: _videos,
            showPlayCount: false,
            showOriginal: true,
            heroTag: "videoGroup")
      ]);
}
