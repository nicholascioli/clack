import 'dart:async';

import 'package:audioplayer/audioplayer.dart';
import 'package:clack/api/shared_types.dart';
import 'package:flutter/material.dart';
import 'package:icon_shadow/icon_shadow.dart';

import '../utility.dart';

class MusicPlayerFragment extends StatefulWidget {
  final Music musicInfo;

  MusicPlayerFragment({@required this.musicInfo});

  @override
  _MusicPlayerFragmentState createState() => _MusicPlayerFragmentState();
}

class _MusicPlayerFragmentState extends State<MusicPlayerFragment> {
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<AudioPlayerState> _updateSubscription;

  final TextStyle musicTitleTextStyle =
      TextStyle(fontSize: 20, fontWeight: FontWeight.bold);
  final TextStyle textStyle = TextStyle(color: Colors.grey);

  @override
  void initState() {
    // Update the UI when player changes state
    _updateSubscription =
        _player.onPlayerStateChanged.listen((event) => setState(() {}));

    super.initState();
  }

  @override
  void dispose() {
    // Stop the player
    _player.stop();
    _updateSubscription.cancel();

    // Continue death
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
          child: Padding(
        padding: EdgeInsets.only(left: 20, right: 20),
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                  flex: 1,
                  child: GestureDetector(
                      onTap: () => _player.state == AudioPlayerState.PLAYING
                          ? _player.pause()
                          : _player.play(widget.musicInfo.playUrl.toString()),
                      child: AspectRatio(
                          aspectRatio: 1,
                          child: ClipRRect(
                              borderRadius: BorderRadius.circular(5),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                    image: DecorationImage(
                                        image: NetworkImage(widget
                                            .musicInfo.coverLarge
                                            .toString()))),
                                child: Center(
                                  child: IconShadowWidget(
                                    Icon(
                                        _player.state !=
                                                AudioPlayerState.PLAYING
                                            ? Icons.play_arrow
                                            : Icons.pause,
                                        color: Colors.white,
                                        size: 50),
                                    shadowColor: Colors.black,
                                  ),
                                ),
                              ))))),
              Expanded(
                  flex: 2,
                  child: Padding(
                    padding: EdgeInsets.only(left: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(widget.musicInfo.title,
                            style: musicTitleTextStyle),
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.musicInfo.authorName,
                                style: textStyle,
                              ),
                              Text(
                                "${widget.musicInfo.videoCount ?? "?"} video(s)",
                                style: textStyle,
                              )
                            ]),
                        RaisedButton(
                            child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.bookmark_border),
                                  Text("Add to Favorites")
                                ]),
                            onPressed: () => showNotImplemented(context))
                      ],
                    ),
                  ))
            ]),
      ));
}
