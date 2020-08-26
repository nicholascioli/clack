import 'package:clack/api/shared_types.dart';
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

  /// Share information for this hashtag
  final ShareMeta shareMeta;

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
      this.stats,
      this.shareMeta});

  factory HashtagResult.fromJson(Map<String, dynamic> raw) {
    Map<String, dynamic> json = raw["challenge"];
    Map<String, dynamic> stats = raw["stats"];
    Map<String, dynamic> share =
        raw.containsKey("shareMeta") ? raw["shareMeta"] : null;

    return HashtagResult(
        id: json["id"],
        title: json["title"],
        desc: json["desc"],
        profileThumb: Uri.parse(json["profileThumb"]),
        profileMedium: Uri.parse(json["profileMedium"]),
        profileLarger: Uri.parse(json["profileLarger"]),
        coverThumb: Uri.parse(json["coverThumb"]),
        coverMedium: Uri.parse(json["coverMedium"]),
        coverLarger: Uri.parse(json["coverLarger"]),
        stats: HashtagStats.fromJson(stats),
        shareMeta: share != null ? ShareMeta.fromJson(share) : null);
  }
}
