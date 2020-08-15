import 'package:dataclass/dataclass.dart';

@dataClass
class HashtagStats {
  final int videoCount;
  final int viewCount;

  const HashtagStats({this.videoCount, this.viewCount});

  factory HashtagStats.fromJson(Map<String, dynamic> json) => HashtagStats(
      videoCount: json["videoCount"], viewCount: json["viewCount"]);
}

@dataClass
class HashtagResult {
  /// Internal ID
  final String id;

  /// The hashtag without the #
  final String title;

  /// Description of the Hashtag
  final String desc;

  /// The smallest profile image size
  final Uri profileThumb;

  /// A medium sized profile image
  final Uri profileMedium;

  /// The full size profile image
  final Uri profileLarger;

  /// The smallest hashtag cover image
  final Uri coverThumb;

  /// A medium sized cover image
  final Uri coverMedium;

  /// The full sized cover image
  final Uri coverLarger;

  /// Stats about the hashtag
  final HashtagStats stats;

  const HashtagResult(
      {this.id,
      this.title,
      this.desc,
      this.profileThumb,
      this.profileMedium,
      this.profileLarger,
      this.coverThumb,
      this.coverMedium,
      this.coverLarger,
      this.stats});

  factory HashtagResult.fromJson(Map<String, dynamic> json) => HashtagResult(
      id: json["challenge"]["id"],
      title: json["challenge"]["title"],
      desc: json["challenge"]["desc"],
      profileThumb: Uri.parse(json["challenge"]["profileThumb"]),
      profileMedium: Uri.parse(json["challenge"]["profileMedium"]),
      profileLarger: Uri.parse(json["challenge"]["profileLarger"]),
      coverThumb: Uri.parse(json["challenge"]["coverThumb"]),
      coverMedium: Uri.parse(json["challenge"]["coverMedium"]),
      coverLarger: Uri.parse(json["challenge"]["coverLarger"]),
      stats: HashtagStats.fromJson(json["stats"]));
}
