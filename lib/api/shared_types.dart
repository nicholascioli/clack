import 'package:dataclass/dataclass.dart';

/// A brief overview of a TT author.
///
/// This info is typically a subset of the results for most requests. See
/// [AuthorResult] for a more complete overview of an [Author].
@dataClass
class Author {
  /// Internal ID
  final String id;

  /// Secondary ID used for certain requests
  final String secUid;

  /// The username of the [Author].
  final String uniqueId;

  /// Full-quality version of an [Author]'s profile picture
  final Uri avatarLarger;

  /// Compressed version of an [Author]'s profile picture
  final Uri avatarMedium;

  /// Thumbnail version of an [Author]'s profile picture
  final Uri avatarThumb;

  /// Friendly nickname. [Author] configurable.
  final String nickname;

  /// Signature / Tagline. [Author] configurable.
  final String signature;

  /// Whether an [Author]'s liked videos are publicly available.
  ///
  /// See [API.getAuthorFavoritedVideoStream()] for more info.
  final bool openFavorite;

  /// Whether an [Author] is verified.
  final bool verified;

  /// ???
  final int relation;

  Author(
      {this.id,
      this.secUid,
      this.uniqueId,
      this.avatarLarger,
      this.avatarMedium,
      this.avatarThumb,
      this.nickname,
      this.signature,
      this.openFavorite,
      this.verified,
      this.relation});

  /// Construct an [Author] from a supplied [json] object.
  ///
  /// The members of said JSON object must include every field by name.
  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
        id: json["id"],
        secUid: json["secUid"],
        uniqueId: json["uniqueId"],
        avatarLarger: Uri.parse(json["avatarLarger"]),
        avatarMedium: Uri.parse(json["avatarMedium"]),
        avatarThumb: Uri.parse(json["avatarThumb"]),
        nickname: json["nickname"],
        signature: json["signature"],
        openFavorite: json["openFavorite"],
        verified: json["verified"],
        relation: json["relation"]);
  }
}

/// Details of a TT music object
@dataClass
class Music {
  /// Internal ID
  final String id;

  /// The name of the owning [Author]
  final String authorName;

  /// The title of the music track
  final String title;

  /// A full-quality version of the cover art
  final Uri coverLarge;

  /// A compressed version of the cover art
  final Uri coverMedium;

  /// A thumbnail version of the cover art
  final Uri coverThumb;

  /// The URL for streaming the music track
  final Uri playUrl;

  /// Whether this music track is original to an author
  final bool original;

  Music(
      {this.id,
      this.authorName,
      this.title,
      this.coverLarge,
      this.coverMedium,
      this.coverThumb,
      this.playUrl,
      this.original});

  /// Construct a [Music] object from a supplied [json] object.
  ///
  /// The members of said JSON object must include every field by name.
  factory Music.fromJson(Map<String, dynamic> json) {
    return Music(
        id: json["id"],
        authorName: json["authorName"],
        title: json["title"],
        coverLarge: Uri.parse(json["coverLarge"]),
        coverMedium: Uri.parse(json["coverMedium"]),
        coverThumb: Uri.parse(json["coverThumb"]),
        playUrl: Uri.parse(json["playUrl"]),
        original: json["original"]);
  }
}

/// Brief details of a TT video object.
///
/// This info is typically a subset of the results for most video requests.
/// For more info on a video, refer to [VideoResult].
@dataClass
class Video {
  /// Internal ID
  final String id;

  /// Width of the Video, in pixels
  final int width;

  /// Height of the Video, in pixels
  final int height;

  /// The duration of the video in seconds(?)
  final int duration; // TODO: Is this in seconds?

  /// The ratio of the video as a string.
  ///
  /// Contrary to what you would expect, this is a string describing the
  /// resolution of the video. ex. "720p".
  final String ratio;

  /// URL to a compressed image of the first frame of the video
  final Uri cover;

  /// URL to a GIF of a segment of the video
  final Uri dynamicCover;

  /// URL to the original quality image of the first frame of the video
  final Uri originCover; // Original quality frame

  /// URL to a compressed version of the video
  final Uri playAddr;

  /// URL to the full-quality version of the video
  final Uri downloadAddr;

  /// Whether or not the video is originally of this author
  final bool isOriginal;

  Video(
      {this.id,
      this.width,
      this.height,
      this.duration,
      this.ratio,
      this.cover,
      this.dynamicCover,
      this.originCover,
      this.playAddr,
      this.downloadAddr,
      this.isOriginal});

  /// Construct a [Video] object from a supplied [json] object.
  ///
  /// The members of said JSON object must include every field by name.
  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
        id: json["id"],
        width: json["width"],
        height: json["height"],
        duration: json["duration"],
        ratio: json["ratio"],
        cover: Uri.parse(json["cover"]),
        dynamicCover: Uri.parse(json["dynamicCover"]),
        originCover: Uri.parse(json["originCover"]),
        playAddr: Uri.parse(json["playAddr"]),
        downloadAddr: Uri.parse(json["downloadAddr"]),
        isOriginal: json["isOriginal"]);
  }
}

/// Shareable info of an [Author]
@dataClass
class ShareMeta {
  /// The title of the author
  ///
  /// This includes (typically) the [Author.uniqueId] and [AuthorStats].
  final String title;

  /// The [signature] line of an [Author].
  final String desc;

  ShareMeta({this.title, this.desc});

  /// Construct a [ShareMeta] object from a supplied [json] object.
  ///
  /// The members of said JSON object must include every field by name.
  factory ShareMeta.fromJson(Map<String, dynamic> json) {
    return ShareMeta(title: json["title"], desc: json["desc"]);
  }
}

/// A comment for a specific [VideoResul]
///
/// NOT IMPLEMENTED
@dataClass
class Comment {
  // TODO: Implement this data class
}
