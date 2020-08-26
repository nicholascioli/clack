import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:clack/api/author_result.dart';
import 'package:clack/api/hashtag_result.dart';
import 'package:clack/api/video_result.dart';
import 'package:clack/utility.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:tuple/tuple.dart';

import 'api/api_stream.dart';
import 'api/shared_types.dart';

const TYPE_RECENT_VIDEOS = 1;
const TYPE_LIKED_VIDEOS = 2;
const TYPE_TAG_VIDEOS = 3;
const TYPE_AUDIO_VIDEOS = 4;
const TYPE_TRENDING_VIDEOS = 5;

/// Static class for making direct TT API requests.
///
/// Many of the member functions will return [ApiStream]s which can then be used
/// to iterate over API results.
class API {
  // Constants used throughout the API calls
  static const String USER_AGENT =
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/83.0.4103.97 Safari/537.36";
  static InAppWebViewGroupOptions webViewOptions = InAppWebViewGroupOptions(
      crossPlatform:
          InAppWebViewOptions(userAgent: USER_AGENT, incognito: true));

  static AuthorResult _userDefaults =
      AuthorResult(user: Author(id: "1", uniqueId: "__ANONYMOUS__"));

  static Cookie _loginToken;
  static String _webId;
  static String _lang = "en";
  static AuthorResult _userInfo = _userDefaults; // Initialize as anonymous user

  // We need a [HeadlessInAppWebView] in order to perform url signing because
  //   the signing process is done using obfuscated JS
  static final HeadlessInAppWebView _webView = HeadlessInAppWebView(
      initialUrl: "", initialHeaders: {}, initialOptions: webViewOptions);

  static Future<void> init() async {
    const FlutterSecureStorage storage = FlutterSecureStorage();

    String token = await storage.read(key: "TT_TOKEN");
    String webId = await storage.read(key: "TT_WEBID");
    String username = await storage.read(key: "TT_USER");
    String lang = await storage.read(key: "TT_LANG");

    // Only initialize if not null
    if (token != null && username != null && webId != null && lang != null) {
      _loginToken = Cookie(name: "sid_guard", value: token);
      _webId = webId;
      _userInfo = await API.getAuthorInfo(Author(uniqueId: username));
      _lang = lang;
    }

    return Future.value();
  }

  /// Check if the user has logged in
  static bool isLoggedIn() => _loginToken != null;

  /// Trash all login data
  static Future<void> logout() async {
    // Clear secure storage
    const FlutterSecureStorage storage = FlutterSecureStorage();
    await storage.deleteAll();

    // Update locals
    _loginToken = null;
    _webId = null;
    _userInfo = _userDefaults;
    _lang = "en";

    return Future.value();
  }

  /// Save login information for all future requests
  static Future<void> login(
      Cookie token, String webId, String username, String lang) async {
    // Save to secure storage
    const FlutterSecureStorage storage = FlutterSecureStorage();
    storage.write(key: "TT_TOKEN", value: token.value.toString());
    storage.write(key: "TT_WEBID", value: webId);
    storage.write(key: "TT_USER", value: username);
    storage.write(key: "TT_LANG", value: lang);

    // Update locals
    _loginToken = token;
    _webId = webId;
    _userInfo = await API.getAuthorInfo(Author(uniqueId: username));
    _lang = lang;

    return Future.value();
  }

  /// Get a reference to the currently logged-in user
  static AuthorResult getLogin() => _userInfo;

  /// Like (digg) a video, if logged in.
  ///
  /// Returns true if the video was successfully liked
  static Future<bool> diggVideo(VideoResult video, bool shouldLike) async {
    // Do nothing if not logged in
    if (!API.isLoggedIn()) return Future.value(false);

    String url = _getFormattedUrl("api/commit/item/digg", {
      "aid": 1988,
      "aweme_id": getVideoId(video),
      "uid": _userInfo.user.id,
      "did": _webId,
      "device_id": _webId,
      "verifyFp": "",
      "cookie_enabled": true,
      "type": shouldLike ? 1 : 0, // 1 for enable, 0 for disable
    });

    dynamic asJson = await _fetchResults(url, shouldPost: true);
    return Future.value(asJson.containsKey("is_digg") && shouldLike);
  }

  /// Set the following status of an [author] to [shouldFollow]
  static Future<bool> followAuther(Author author, bool shouldFollow) async {
    // Do nothing if not logged in
    if (!API.isLoggedIn()) return Future.value(false);

    String url = _getFormattedUrl("api/commit/follow/user", {
      "aid": 1988,
      "user_id": author.id,
      "uid": _userInfo.user.id,
      "did": _webId,
      "device_id": _webId,
      "verifyFp": "",
      "cookie_enabled": true,
      "type": shouldFollow ? 1 : 0, // 1 for enable, 0 for disable
    });

    dynamic asJson = await _fetchResults(url, shouldPost: true);
    print("GOT RES: $asJson");
    return Future.value(asJson.containsKey("follow_status") && shouldFollow);
  }

  static Future<VideoResult> getVideoInfo(String videoId) async {
    String url = _getFormattedUrl("api/item/detail", {"itemId": videoId});

    dynamic asJson = await _fetchResults(url);
    dynamic info = asJson["itemInfo"]["itemStruct"];

    return VideoResult.fromJson(info);
  }

  /// Get an [author]'s extended info.
  ///
  /// This returns a [Future] as it requires network requests.
  static Future<AuthorResult> getAuthorInfo(Author author) async {
    String url =
        _getFormattedUrl("api/user/detail", {"uniqueId": author.uniqueId});

    dynamic asJson = await _fetchResults(url);
    dynamic user = asJson["userInfo"];

    return AuthorResult.fromJson(user);
  }

  static Future<HashtagResult> getHashtagInfo(String hashtagName) async {
    String url = _getFormattedUrl(
        "api/challenge/detail", {"challengeName": hashtagName});

    dynamic asJson = await _fetchResults(url);

    return HashtagResult.fromJson(asJson["challengeInfo"]);
  }

  /// Get an [ApiStream]<[VideoResult]> of currently trending videos.
  static ApiStream<VideoResult> getTrendingStream(int count) =>
      ApiStream(count, (count, cursor) {
        // TODO: Make this allow for querying anything, not just the trending
        String url = _getFormattedUrl("api/item_list", {
          "id": 1,
          "uid": _loginToken != null ? _userInfo.user.id : "",
          "did": _webId != null ? _webId : "",
          "cookieEnabled": _loginToken != null ? true : "",
          "verifyFp": "",
          "secUid": "",
          "sourceType": 12,
          "type": TYPE_TRENDING_VIDEOS,
          "count": count,
          "maxCursor": cursor,
          "minCursor": 0
        });

        return _fetchResultsFormatted(url, cursor,
            bodyParser: (body) => body["items"],
            resultMapper: (e) => VideoResult.fromJson(e));
      });

  /// Get an [ApiStream]<[VideoResult]> of an [author]'s list of videos.
  static ApiStream<VideoResult> getAuthorVideoStream(
          Author author, int count) =>
      ApiStream(count, (count, cursor) {
        String url = _getFormattedUrl("api/item_list", {
          "id": author.id,
          "secUid": author.secUid,
          "sourceType": 8,
          "type": TYPE_RECENT_VIDEOS,
          "count": count,
          "maxCursor": cursor,
          "minCursor": 0
        });

        return _fetchResultsFormatted(url, cursor,
            bodyParser: (body) => body["items"],
            resultMapper: (e) => VideoResult.fromJson(e));
      });

  /// Get an [ApiStream]<[VideoResult]> of an [author]'s liked videos.
  ///
  /// This function will return an empty list if the [author]'s liked videos
  /// are private. See [Author].
  static ApiStream<VideoResult> getAuthorFavoritedVideoStream(
          Author author, int count) =>
      ApiStream(count, (count, cursor) {
        String url = _getFormattedUrl("api/item_list", {
          "id": author.id,
          "secUid": author.secUid,
          "sourceType": 9,
          "type": TYPE_LIKED_VIDEOS,
          "count": count,
          "maxCursor": cursor,
          "minCursor": 0
        });

        return _fetchResultsFormatted(url, cursor,
            bodyParser: (body) => body["items"],
            resultMapper: (e) => VideoResult.fromJson(e));
      });

  /// Get an [ApiStream]<[Comment]> of a [video]'s comments.
  static ApiStream<Comment> getVideoCommentStream(
          VideoResult video, int count) =>
      ApiStream(count, (count, maxCursor) {
        String url = _getFormattedUrl(
            "api/comment/list",
            {
              "aid": 1988,
              "cookie_enabled": true,
              "did": _webId,
              "uid": _userInfo.user.id,
              "aweme_id": getVideoId(video),
              "cursor": maxCursor,
              "count": count,
              "verifyFp": ""
            },
            useMobile: false);

        return _fetchResultsFormatted(url, maxCursor,
            bodyParser: (body) => body["comments"],
            resultMapper: (e) => Comment.fromJson(e),
            infoParser: (json) =>
                Tuple2(json["has_more"] == 1, json["cursor"]));
      });

  static ApiStream<Comment> getCommentReplyStream(Comment comment, int count) =>
      ApiStream(count, (count, maxCursor) {
        String url = _getFormattedUrl(
            "api/comment/list/reply",
            {
              "aid": 1988,
              "cookie_enabled": true,
              "did": _webId,
              "uid": _userInfo.user.id,
              "comment_id": comment.cid,
              "item_id": comment.awemeId,
              "cursor": maxCursor,
              "count": count,
              "verifyFp": "",
            },
            useMobile: false);

        return _fetchResultsFormatted(url, maxCursor,
            bodyParser: (body) => body["comments"],
            resultMapper: (e) => Comment.fromJson(e),
            infoParser: (json) =>
                Tuple2(json["has_more"] == 1, json["cursor"]));
      });

  static ApiStream<VideoResult> getVideosForMusic(Music m, int count) =>
      ApiStream(count, (count, maxCursor) {
        String url = _getFormattedUrl("share/item/list", {
          "id": m.id,
          "secUid": "",
          "shareId": "",
          "type": TYPE_AUDIO_VIDEOS,
          "count": count,
          "maxCursor": maxCursor,
          "minCursor": 0
        });

        return _fetchResultsFormatted(url, maxCursor,
            bodyParser: (body) => body["body"]["itemListData"],
            resultMapper: (e) => VideoResult.fromMusicJson(e),
            infoParser: (json) =>
                Tuple2(json["body"]["hasMore"], json["body"]["maxCursor"]));
      });

  static ApiStream<HashtagResult> getTrendingHashtags(int count) =>
      ApiStream(count, (count, maxCursor) {
        String url = _getFormattedUrl("api/discover/challenge", {
          "discoverType": 0,
          "needItemList": false,
          "keyWord": "",
          "offset": maxCursor,
          "count": count
        });

        // // TODO: How do we know that there aren't more?
        return _fetchResultsFormatted(url, maxCursor,
            bodyParser: (body) => body["challengeInfoList"],
            resultMapper: (e) => HashtagResult.fromJson(e),
            infoParser: (json) => Tuple2(false, json["offset"]));
      });

  static ApiStream<VideoResult> getVideosForHashtag(
          HashtagResult ht, int count) =>
      ApiStream(count, (count, maxCursor) {
        final String url = _getFormattedUrl("share/item/list", {
          "id": ht.id,
          "secUid": "",
          "shareId": "",
          "type": TYPE_TAG_VIDEOS,
          "count": count,
          "maxCursor": maxCursor,
          "minCursor": 0
        });

        return _fetchResultsFormatted(url, maxCursor,
            bodyParser: (body) => body["body"]["itemListData"],
            resultMapper: (element) => VideoResult.fromMusicJson(element),
            infoParser: (json) =>
                Tuple2(json["body"]["hasMore"], json["body"]["maxCursor"]));
      });

  /// Signs a URL using TT's obfuscated JS
  ///
  /// Most requests, if not all, need be signed using TT's proprietary signing
  /// algorithm. To avoid the need to connect to TT's website every time we
  /// create a new request, this function loads the pre-downloaded JS script
  /// and passes it through a WebView.
  static Future<String> sign(String url) async {
    // Now execute
    var givenJS = rootBundle.loadString('js/acrawler.js');
    return givenJS.then((String js) async {
      return await _webView.webViewController.evaluateJavascript(
          source: "$js; byted_acrawler.sign({ url: \"$url\" })");
    });
  }

  /// Fetches data from a TT endpoint and formats it into an ApiResult
  static Future<ApiResult<T>> _fetchResultsFormatted<T, U>(
      String url, int cursor,
      {List<U> Function(Map<String, dynamic> body) bodyParser,
      T Function(U element) resultMapper,
      Tuple2<bool, dynamic> Function(dynamic json) infoParser,
      String moreKey = "hasMore",
      String cursorKey = "maxCursor"}) async {
    // First, get the content
    Map<String, dynamic> asJson = await _fetchResults(url);

    // Get the relevant field
    List<U> body = bodyParser(asJson);

    // Short out if we get no results
    if (body == null) return ApiResult(false, cursor, []);

    // Extract needed fields for ApiStream
    Tuple2<bool, dynamic> info = infoParser != null
        ? infoParser(asJson)
        : Tuple2(asJson[moreKey], asJson[cursorKey]);
    bool hasMore = info.item1;
    dynamic maxCursor = info.item2;

    // Coerce into an ApiResult
    return ApiResult(
        hasMore,
        maxCursor is int ? maxCursor : int.tryParse(maxCursor),
        body.map(resultMapper));
  }

  /// Fetches data from a TT endpoint
  ///
  /// Set [shouldPost] to `false` for a GET, and `true` for a POST
  static Future<dynamic> _fetchResults(String url,
      {bool shouldPost = false}) async {
    // Sign the url using TT JS
    // Note: We construct a headless webview first and then dispose of
    //   it after we finish generating the code
    await _webView.run();
    String code = await sign(url);
    String signedUrl = "$url&_signature=$code";
    await _webView.dispose();
    print("GOT URL: $signedUrl");

    // Select the method
    var method = shouldPost ? http.post : http.get;

    // Make a request for the videos
    //   Note: We attach the login cookie if available
    var response = await method(signedUrl, headers: {
      "User-Agent": USER_AGENT,
      "cookie": _loginToken != null
          ? "sid_guard=${_loginToken.value.toString()}"
          : "",
      "Accept": "application/json, text/plain, */*",
      "Content-Type": "application/x-www-form-urlencoded",
      "DNT": "1",
      "Origin": "https://www.tiktok.com",
      "Referer": "https://www.tiktok.com/"
    });

    // Make sure that we get a valid response
    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      //   then parse the JSON.
      // print("GOT RESPONSE: ${response.body}");
      return Future.value(json.decode(response.body));
    } else {
      // If the server did not return a 200 OK response,
      //   then throw an exception.
      throw Exception(
          'Failed to fetch results from $url: ${response.statusCode} => ${response.body}');
    }
  }

  /// Get a url with formatted [options]
  ///
  /// The endpoint is always assumed to start with https://m.tiktok.com/
  /// Set [useMobile] to `false` for https://www.tiktok.com/
  static String _getFormattedUrl(String endpoint, Map<String, dynamic> options,
      {bool useMobile = true}) {
    String result = "https://${useMobile ? "m" : "www"}.tiktok.com/$endpoint/";

    // Apply all of the options
    result += options.entries.fold(
        "?appId=1233&language=$_lang",
        (previousValue, element) =>
            "$previousValue&${element.key}=${element.value.toString()}");

    return result;
  }
}
