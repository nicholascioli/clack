import 'package:clack/api/shared_types.dart';
import 'package:dataclass/dataclass.dart';

/// Stats related to a video.
///
/// This is a subset of results of a [VideoResult] object. It includes info
/// such as the comment count, play count, etc.
@dataClass
class VideoStats {
  /// The total number of comments for this video
  ///
  /// The comments themselves must be fetched with [API.getVideoCommentStream()].
  final int commentCount;

  /// The amount of likes (heart icon) for this video
  final int diggCount;

  /// The amount of play-throughs for this video
  final int playCount;

  /// The amount of times this video has been shared
  final int shareCount;

  VideoStats(
      {this.commentCount, this.diggCount, this.playCount, this.shareCount});

  /// Construct a [VideoStat] from a supplied [json] object.
  ///
  /// The members of said JSON object must include every field by name.
  factory VideoStats.fromJson(Map<String, dynamic> json) {
    return VideoStats(
        commentCount: json["commentCount"],
        diggCount: json["diggCount"],
        playCount: json["playCount"],
        shareCount: json["shareCount"]);
  }
}

/// A [Video]'s full info.
@dataClass
class VideoResult {
  /// Internal ID
  final String id;

  /// The time that this video was created
  final DateTime createTime;

  /// The description of this video
  final String desc;

  /// The owning [Author]
  final Author author;

  /// The [Music] used in this video
  final Music music;

  /// The [Video] itself
  final Video video;

  /// Stats related to this video
  final VideoStats stats;

  /// Whether or not the current user has liked this video
  final bool digged;

  /// A list of substrings of [desc] that should render as links
  List<TextExtra> textExtra;

  VideoResult(
      {this.id,
      this.createTime,
      this.desc,
      this.author,
      this.music,
      this.video,
      this.stats,
      this.digged,
      this.textExtra});

  /// Construct a [VideoResult] from a supplied [json] object.
  ///
  /// The members of said JSON object must include every field by name.
  factory VideoResult.fromJson(Map<String, dynamic> json) {
    List<dynamic> extrasRaw = json["textExtra"] ?? [];
    List<TextExtra> extras =
        extrasRaw.map((e) => TextExtra.fromJson(e)).toList();

    // Here, we sort the extras for quick composing
    extras.sort((a, b) => a.start - b.start);

    return VideoResult(
        id: json["id"],
        createTime: DateTime.fromMillisecondsSinceEpoch(
            json["createTime"] * 1000), // Timestamp is in seconds
        desc: json["desc"],
        author: Author.fromJson(json["author"]),
        music: Music.fromJson(json["music"]),
        video: Video.fromJson(json["video"]),
        stats: VideoStats.fromJson(json["stats"]),
        digged: json["digged"],
        textExtra: extras);
  }

  /// Construct a [VideoResult] from a list of music videos
  ///
  /// This is slightly different than [VideoResult.fromJson] due to the slight
  /// differences in the response.
  factory VideoResult.fromMusicJson(Map<String, dynamic> json) {
    final result = json["itemInfos"];
    final videoMeta = result["video"]["videoMeta"];
    final music = json["musicInfos"];
    final author = json["authorInfos"];

    List<dynamic> extrasRaw = json["textExtra"] ?? [];
    List<TextExtra> extras =
        extrasRaw.map((e) => TextExtra.fromJson(e)).toList();

    // Here, we sort the extras for quick composing
    extras.sort((a, b) => a.start - b.start);

    return VideoResult(
        id: json["id"],
        createTime: DateTime.fromMillisecondsSinceEpoch(
            int.tryParse(result["createTime"]) * 1000),
        desc: result["text"],
        author: Author(
            id: author["userId"],
            secUid: author["secUid"],
            uniqueId: author["uniqueId"],
            nickname: author["nickName"],
            avatarLarger: Uri.parse(author["coversLarger"][0]),
            avatarMedium: Uri.parse(author["coversMedium"][0]),
            avatarThumb: Uri.parse(author["covers"][0]),
            signature: author["signature"],
            openFavorite: false, // NOTE: You should re-request this from TT
            verified: author["verified"],
            relation: author["relation"]),
        music: Music(
            id: music["musicId"],
            authorName: music["authorName"],
            title: music["musicName"],
            coverLarge: Uri.parse(music["coversLarger"][0]),
            coverMedium: Uri.parse(music["coversMedium"][0]),
            coverThumb: Uri.parse(music["covers"][0]),
            playUrl: Uri.parse(music["playUrl"][0])),
        video: Video(
            id: result["id"],
            width: videoMeta["width"],
            height: videoMeta["height"],
            duration: videoMeta["duration"],
            ratio: videoMeta["ratio"]
                .toString(), // TODO; Here, ratio is a number...
            cover: Uri.parse(result["covers"][0]),
            dynamicCover: Uri.parse(result["coversDynamic"][0]),
            originCover: Uri.parse(result["coversOrigin"][0]),
            playAddr: Uri.parse(result["video"]["urls"][0]),
            downloadAddr: Uri.parse(result["video"]["urls"][
                0]), // TODO: Request does not include this, so duplicate for now
            isOriginal: result["isOriginal"]),
        stats: VideoStats(
            commentCount: result["commentCount"],
            diggCount: result["diggCount"],
            playCount: result["playCount"],
            shareCount: result["shareCount"]),
        digged: json["liked"],
        textExtra: extras);
  }
}
