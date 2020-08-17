import 'package:clack/api/shared_types.dart';
import 'package:clack/api/video_result.dart';
import 'package:dataclass/dataclass.dart';

@dataClass
class MusicResult {
  final String id;

  final DateTime createTime;
  final String text;

  final Music musicInfo;
  final Video video;
  final Author author;
  final VideoStats stats;

  const MusicResult(
      {this.id,
      this.createTime,
      this.text,
      this.musicInfo,
      this.video,
      this.author,
      this.stats});

  factory MusicResult.fromJson(Map<String, dynamic> json) {
    final video = json["itemInfos"];
    final videoMeta = video["video"]["videoMeta"];
    final music = json["musicInfos"];
    final author = json["authorInfos"];

    return MusicResult(
        id: music["musicId"],
        createTime: DateTime.fromMillisecondsSinceEpoch(
            int.tryParse(video["createTime"])),
        text: video["text"],
        musicInfo: Music(
            id: music["musicId"],
            authorName: music["authorName"],
            title: music["musicName"],
            coverLarge: Uri.parse(music["coversLarger"][0]),
            coverMedium: Uri.parse(music["coversMedium"][0]),
            coverThumb: Uri.parse(music["covers"][0]),
            playUrl: Uri.parse(music["playUrl"][0])),
        video: Video(
            id: video["id"],
            width: videoMeta["width"],
            height: videoMeta["height"],
            duration: videoMeta["duration"],
            ratio: videoMeta["ratio"]
                .toString(), // TODO; Here, ratio is a number...
            cover: Uri.parse(video["covers"][0]),
            dynamicCover: Uri.parse(video["coversDynamic"][0]),
            originCover: Uri.parse(video["coversOrigin"][0]),
            playAddr: Uri.parse(video["video"]["urls"][0]),
            downloadAddr: Uri.parse(video["video"]["urls"][
                0]), // TODO: Request does not include this, so duplicate for now
            isOriginal: video["isOriginal"]),
        author: Author(
            id: author["userId"],
            secUid: author["secUid"],
            uniqueId: author["uniqueId"],
            nickname: author["nickName"],
            avatarLarger: Uri.parse(author["coversLarger"][0]),
            avatarMedium: Uri.parse(author["coversMedium"][0]),
            avatarThumb: Uri.parse(author["covers"][0]),
            signature: author["signature"],
            openFavorite:
                author["isSecret"], // TODO: This might not be the actual field
            verified: author["verified"],
            relation: author["relation"]),
        stats: VideoStats(
            commentCount: video["commentCount"],
            diggCount: video["diggCount"],
            playCount: video["playCount"],
            shareCount: video["shareCount"]));
  }
}
