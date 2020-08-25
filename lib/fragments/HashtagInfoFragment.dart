import 'package:clack/api/hashtag_result.dart';
import 'package:flutter/material.dart';

import '../utility.dart';

class HashtagInfoFragment extends StatelessWidget {
  final HashtagResult hashtag;

  HashtagInfoFragment({@required this.hashtag});

  final TextStyle titleTextStyle =
      TextStyle(fontSize: 20, fontWeight: FontWeight.bold);
  final TextStyle textStyle = TextStyle(color: Colors.grey);

  @override
  Widget build(BuildContext context) =>
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
                            child: FittedBox(
                                fit: BoxFit.contain, child: Text("#")),
                          ))),
                  Expanded(
                    flex: 2,
                    child: Padding(
                        padding: EdgeInsets.only(left: 20, top: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("#${hashtag.title}", style: titleTextStyle),
                            SizedBox(height: 20),
                            Text(
                                "${statToString(hashtag.stats.videoCount)} videos",
                                style: textStyle)
                          ],
                        )),
                  )
                ])),
        Padding(
          padding: EdgeInsets.only(top: 10, left: 20, right: 20),
          child: Text(hashtag.desc, style: textStyle),
        )
      ]);
}
