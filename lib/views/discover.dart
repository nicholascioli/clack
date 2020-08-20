import 'package:clack/api.dart';
import 'package:clack/api/hashtag_result.dart';
import 'package:clack/api/video_result.dart';
import 'package:clack/utility.dart';
import 'package:clack/views/video_feed.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class Discover extends StatefulWidget {
  final void Function(VideoFeedActivePage active) setActive;
  const Discover(this.setActive);

  @override
  _DiscoverState createState() => _DiscoverState();
}

class _DiscoverState extends State<Discover> {
  ApiStream<HashtagResult> _hashtags;
  List<ApiStream<VideoResult>> _hashtagVideos = List(10);
  bool _hasInit = false;

  final hashtagTextStyle = TextStyle(fontWeight: FontWeight.bold, height: 1.5);
  final subtextTextStyle = TextStyle(color: Colors.grey, height: 1.5);

  @override
  void initState() {
    _hashtags = API.getTrendingHashtags(10);
    _hashtags.setOnChanged(() => setState(() {
          // Initialize all of the videos
          if (!_hasInit) {
            _hasInit = true;
            _hashtags.results.forEach((key, ht) {
              print("INDEX: $key");
              _hashtagVideos[key] = API.getVideosForHashtag(ht, 10);
              _hashtagVideos[key].setOnChanged(() => setState(() {}));
            });
          }
        }));

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
                icon: Icon(Icons.arrow_back), onPressed: () => _handleBack()),
            actions: [
              IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () => showNotImplemented(context))
            ],
            title: Text("Discover"),
          ),
          body: _hashtags[0] == null
              ? Center(
                  child: SpinKitFadingGrid(color: Colors.black),
                )
              : CustomScrollView(
                  slivers: [
                    SliverList(
                        delegate: SliverChildListDelegate.fixed([
                      AspectRatio(
                          aspectRatio: 2,
                          child: Image.network(
                            _hashtags[0].profileLarger.toString(),
                            fit: BoxFit.fitWidth,
                          )),
                    ])),
                    _buildTrending()
                  ],
                ),
        ),
        onWillPop: () => _handleBack());
  }

  Widget _buildTrending() => SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
        final ht = _hashtags[index];

        return Padding(
            padding: EdgeInsets.only(top: 10),
            child: Column(children: [
              Padding(
                  padding: EdgeInsets.only(left: 10, right: 10, bottom: 10),
                  child: Row(children: [
                    CircleAvatar(
                      child: Text("#"),
                      radius: 20,
                    ),
                    SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ht.title, style: hashtagTextStyle),
                        Text(
                          "Trending Hashtag",
                          style: subtextTextStyle,
                        )
                      ],
                    ),
                    Spacer(),
                    ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: Container(
                            color: Color.fromARGB(255, 210, 210, 210),
                            child: Padding(
                                padding: EdgeInsets.all(5),
                                child:
                                    Text(statToString(ht.stats.videoCount))))),
                  ])),
              _hashtagVideos[index] != null
                  ? SizedBox(
                      height: 150,
                      child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          shrinkWrap: true,
                          itemBuilder: (innerContext, innerIndex) {
                            final videos = _hashtagVideos[index];

                            return Padding(
                                padding: EdgeInsets.only(
                                    left: (innerIndex == 0) ? 10 : 3),
                                child: GestureDetector(
                                    onTap: () => Navigator.pushNamed(context, VideoFeed.routeName,
                                        arguments: VideoFeedArgs(videos, innerIndex, null,
                                            heroTag: ht.title)),
                                    child: Hero(
                                        tag:
                                            "${ht.title}_video_page_$innerIndex",
                                        child: Container(
                                            color: Colors.black,
                                            child: AspectRatio(
                                                aspectRatio: 0.75,
                                                child: videos[innerIndex] == null
                                                    ? Container(
                                                        child: SpinKitFadingCube(color: Colors.white),
                                                        color: Colors.black)
                                                    : FittedBox(fit: BoxFit.fitWidth, child: Image.network(videos[innerIndex].video.dynamicCover.toString())))))));
                          }))
                  : SpinKitCubeGrid(color: Colors.black),
              SizedBox(height: 10),
              Divider()
            ]));
      }, childCount: 10));

  Future<bool> _handleBack() {
    widget.setActive(VideoFeedActivePage.VIDEO);

    return Future.value(false);
  }
}
