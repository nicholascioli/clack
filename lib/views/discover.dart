import 'package:clack/api.dart';
import 'package:clack/api/api_stream.dart';
import 'package:clack/api/hashtag_result.dart';
import 'package:clack/api/video_result.dart';
import 'package:clack/fragments/HashtagInfoFragment.dart';
import 'package:clack/generated/locale_keys.g.dart';
import 'package:clack/utility.dart';
import 'package:clack/views/video_feed.dart';
import 'package:clack/views/video_group.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:transparent_image/transparent_image.dart';

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
              _hashtagVideos[key] = API.getVideosForHashtag(ht, 10);
              _hashtagVideos[key].setOnChanged(() => setState(() {}));
              _hashtagVideos[key].preload();
            });
          }
        }));
    _hashtags.preload();

    super.initState();
  }

  @override
  void dispose() {
    // Remove the listeners
    _hashtags.setOnChanged(() {});
    _hashtagVideos.forEach((element) {
      element.setOnChanged(() {});
    });

    super.dispose();
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
            title: Text(LocaleKeys.page_discover).tr(),
          ),
          body: !_hashtags.hasLoaded
              ? Center(
                  child: SpinKitFadingGrid(
                      color: Theme.of(context).textTheme.headline1.color),
                )
              : CustomScrollView(
                  slivers: [
                    SliverList(
                        delegate: SliverChildListDelegate.fixed([
                      AspectRatio(
                          aspectRatio: 2,
                          child: FadeInImage.memoryNetwork(
                            placeholder: kTransparentImage,
                            image: _hashtags[0].profileLarger.toString(),
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
                    GestureDetector(
                        onTap: () =>
                            _handleOpenGroup(_hashtagVideos[index], ht),
                        child: CircleAvatar(
                          backgroundImage: ht.profileThumb.toString().isNotEmpty
                              ? NetworkImage(ht.profileThumb.toString())
                              : null,
                          child: ht.profileThumb.toString().isEmpty
                              ? Text("#")
                              : null,
                          radius: 20,
                        )),
                    SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                            onTap: () =>
                                _handleOpenGroup(_hashtagVideos[index], ht),
                            child: Text(ht.title, style: hashtagTextStyle)),
                        Text(
                          LocaleKeys.hashtag_trending,
                          style: subtextTextStyle,
                        ).tr()
                      ],
                    ),
                    Spacer(),
                    Card(
                        color: Colors.blueGrey,
                        child: Padding(
                            padding: EdgeInsets.all(5),
                            child: Text(
                                statToString(context)
                                    .format(ht.stats.videoCount),
                                style: TextStyle(color: Colors.white)))),
                  ])),

              // Show the list of videos
              SizedBox(
                  height: 150,
                  child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      shrinkWrap: true,
                      itemCount: !_hashtagVideos[index].hasMore
                          ? _hashtagVideos[index].length
                          : null, // Infinite list until we know the full size
                      itemBuilder: (innerContext, innerIndex) =>
                          _buildVideo(ht, _hashtagVideos[index], innerIndex))),

              // Bottom offset and divider
              SizedBox(height: 10),
              Divider()
            ]));
      }, childCount: 10));

  /// Build a single video widget in the list
  Widget _buildVideo(
      HashtagResult ht, ApiStream<VideoResult> videos, int innerIndex) {
    double aspectRatio = 0.75;

    return Padding(
        padding: EdgeInsets.only(left: (innerIndex == 0) ? 10 : 3),
        child: GestureDetector(
          onTap: () => Navigator.pushNamed(context, VideoFeed.routeName,
              arguments:
                  VideoFeedArgs(videos, innerIndex, null, heroTag: ht.title)),
          child: Hero(
              tag: "${ht.title}_video_page_$innerIndex",
              child: Container(
                  color: Colors.black,
                  child: AspectRatio(
                      aspectRatio: aspectRatio,
                      child: FittedBox(
                          fit: BoxFit.fitWidth,
                          child: videos[innerIndex] == null
                              ? Container()
                              : FadeInImage.memoryNetwork(
                                  fadeInDuration: Duration(milliseconds: 300),
                                  placeholder: kTransparentImage,
                                  image: videos[innerIndex]
                                      .video
                                      .dynamicCover
                                      .toString()))))),
        ));
  }

  void _handleOpenGroup(ApiStream<VideoResult> stream, HashtagResult ht) =>
      Navigator.of(context).pushNamed(VideoGroup.routeName,
          arguments: VideoGroupArguments(
              stream: stream,
              headerBuilder: () => HashtagInfoFragment(initialHashtag: ht),
              getShare: () => getHashtagShare(ht)));

  Future<bool> _handleBack() {
    widget.setActive(VideoFeedActivePage.VIDEO);

    return Future.value(false);
  }
}
