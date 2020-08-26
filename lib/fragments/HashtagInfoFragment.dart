import 'package:clack/api.dart';
import 'package:clack/api/hashtag_result.dart';
import 'package:clack/views/full_image.dart';
import 'package:flutter/material.dart';
import 'package:transparent_image/transparent_image.dart';

import '../utility.dart';

class HashtagInfoFragment extends StatefulWidget {
  /// The initial data to show
  final HashtagResult initialHashtag;

  /// Whether or not the initial data is complete.
  ///
  /// Setting this to `true` disables a network fetch for this hashtag's info
  final bool initialIsActual;

  HashtagInfoFragment(
      {@required this.initialHashtag, this.initialIsActual = false});

  @override
  _HashtagInfoFragmentState createState() => _HashtagInfoFragmentState();
}

class _HashtagInfoFragmentState extends State<HashtagInfoFragment> {
  final TextStyle titleTextStyle =
      TextStyle(fontSize: 20, fontWeight: FontWeight.bold);
  final TextStyle textStyle = TextStyle(color: Colors.grey);

  Future<HashtagResult> _result;

  @override
  void initState() {
    // Fetch the full info from TT
    _result = widget.initialIsActual
        ? Future.value(widget.initialHashtag)
        : API.getHashtagInfo(widget.initialHashtag.title);

    super.initState();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
      future: _result,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          return _buildHeader(snapshot.data);
        } else {
          return _buildHeader(widget.initialHashtag);
        }
      });

  Widget _buildHeader(HashtagResult ht) =>
      Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                      flex: 1,
                      child: AspectRatio(
                          aspectRatio: 1,
                          child: Card(
                              clipBehavior: Clip.antiAlias,
                              child: FittedBox(
                                  fit: BoxFit.contain,
                                  child: Stack(children: [
                                    Text("#"),

                                    // Fade in the image, if present
                                    ht.profileLarger != null &&
                                            ht.profileLarger
                                                .toString()
                                                .isNotEmpty
                                        ? FullImage.launcher(
                                            context: context,
                                            url: ht.profileLarger.toString(),
                                            child: FadeInImage.memoryNetwork(
                                                placeholder: kTransparentImage,
                                                image: ht.profileLarger
                                                    .toString()))
                                        : Container(),
                                  ]))))),
                  Expanded(
                    flex: 2,
                    child: Padding(
                        padding: EdgeInsets.only(left: 20, top: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("#${ht.title}", style: titleTextStyle),
                            SizedBox(height: 20),
                            Text(
                                "${ht.stats != null ? statToString(ht.stats.videoCount) : "---"} videos",
                                style: textStyle)
                          ],
                        )),
                  )
                ])),
        Padding(
          padding: EdgeInsets.only(top: 10, left: 20, right: 20),
          child: Text(ht.desc, style: textStyle),
        )
      ]);
}
