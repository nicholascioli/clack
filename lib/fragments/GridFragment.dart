import 'package:clack/api/api_stream.dart';
import 'package:clack/api/video_result.dart';
import 'package:clack/views/video_feed.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:icon_shadow/icon_shadow.dart';
import 'package:transparent_image/transparent_image.dart';

import '../utility.dart';

class GridFragment extends StatelessWidget {
  final ApiStream<VideoResult> stream;
  final int count;
  final bool asSliver;
  final bool showUserInfo;
  final String emptyMessage;
  final bool showPlayCount;
  final bool showOriginal;
  final String heroTag;

  /// Generates a [GridFragment] with the videos of a specific stream
  ///
  /// The [stream] is reused by passing it to the [VideoFeed] upon construction.
  /// Set [count] to null in order to make the list infinite.
  /// Set [asSliver] to true to use a SliverGrid.
  const GridFragment(
      {@required this.stream,
      this.count,
      this.asSliver = false,
      this.showUserInfo = true,
      this.emptyMessage = "Nothing to see here...",
      this.showPlayCount = true,
      this.showOriginal = false,
      this.heroTag = "gridFragment"});

  Widget _wrap(Widget inner) =>
      asSliver ? SliverToBoxAdapter(child: inner) : inner;

  @override
  Widget build(BuildContext context) {
    // Start loading, if needed
    stream.preload();

    // Show loading if waiting on stream
    if (!stream.hasLoaded) {
      return _wrap(Center(
          child: SpinKitFadingGrid(
        color: Theme.of(context).textTheme.headline1.color,
        size: 50,
      )));
    }

    // If we have nothing to show, show the empty message
    if ((count != null && count < 1) ||
        (stream.length == 0 && stream.hasMore == false)) {
      return _wrap(Center(child: Text(emptyMessage)));
    }

    final gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, crossAxisSpacing: 3, mainAxisSpacing: 3);

    // Otherwise, build the grid
    return asSliver
        ? SliverGrid(
            delegate:
                SliverChildBuilderDelegate(_buildElement, childCount: count),
            gridDelegate: gridDelegate)
        : GridView.builder(
            shrinkWrap: true,
            gridDelegate: gridDelegate,
            itemCount: count,
            itemBuilder: _buildElement,
          );
  }

  Widget _buildElement(BuildContext ctx, int index) {
    // If we have reached the true end of the stream, return null to
    // signal that we have finished
    if (stream[index] == null) return null;

    // Otherwise, build the element...
    return GestureDetector(
        onTap: () => Navigator.pushNamed(ctx, VideoFeed.routeName,
            arguments: VideoFeedArgs(stream, index, count,
                showUserInfo: showUserInfo, heroTag: heroTag)),
        child: Stack(children: [
          // Clipped square preview
          Hero(
              tag: "${heroTag}_video_page_$index",
              child: Container(
                  color: Colors.black,
                  child: AspectRatio(
                      aspectRatio: 1,
                      child: FittedBox(
                          fit: BoxFit.fitWidth,
                          child: FadeInImage.memoryNetwork(
                              fadeInDuration: Duration(milliseconds: 300),
                              placeholder: kTransparentImage,
                              image: stream[index]
                                  .video
                                  .dynamicCover
                                  .toString()))))),
          // Optional play count
          showPlayCount ? _playCount(index) : Container(),
          showOriginal ? _originalText(index) : Container()
        ]));
  }

  /// Show a play count
  Widget _playCount(int index) {
    /// Text style for the play count overlay on each video thumbnail
    final TextStyle _playCountTextStyle =
        TextStyle(color: Colors.white, fontSize: 15, shadows: [
      Shadow(
        offset: Offset(1.0, 1.0),
        blurRadius: 3.0,
        color: Color.fromARGB(255, 0, 0, 0),
      ),
    ]);

    return Align(
        alignment: Alignment.bottomLeft,
        child: Padding(
            padding: EdgeInsets.all(5),
            child: stream[index] == null
                ? Container()
                : Row(children: [
                    IconShadowWidget(
                      Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                      ),
                      shadowColor: Colors.black,
                    ),
                    Text(
                      statToString(stream[index].stats.playCount),
                      style: _playCountTextStyle,
                    )
                  ])));
  }

  Widget _originalText(int index) {
    return Align(
        alignment: Alignment.topLeft,
        child: stream[index] == null || !stream[index].video.isOriginal
            ? Container()
            : Padding(
                padding: EdgeInsets.all(5),
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(5),
                      topLeft: Radius.circular(5),
                      topRight: Radius.circular(20),
                      bottomRight: Radius.circular(20)),
                  child: Container(
                    color: Colors.yellow,
                    child: Padding(
                        padding: EdgeInsets.only(
                            left: 5, top: 5, bottom: 5, right: 10),
                        child: Text("Original")),
                  ),
                )));
  }
}
