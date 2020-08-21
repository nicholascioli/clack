import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:clack/api/author_result.dart';
import 'package:clack/api/hashtag_result.dart';
import 'package:clack/api/music_result.dart';
import 'package:clack/api/video_result.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'api/shared_types.dart';

const TYPE_RECENT_VIDEOS = 1;
const TYPE_LIKED_VIDEOS = 2;
const TYPE_TAG_VIDEOS = 3;
const TYPE_AUDIO_VIDEOS = 4;
const TYPE_TRENDING_VIDEOS = 5;

/// A result from an API call.
///
/// [hasMore] indicates that there is more data available to fetch, starting at
/// [nextCursor].
class ApiResult<T> {
  final bool hasMore;
  final int nextCursor;
  final Iterable<T> results;

  const ApiResult(this.hasMore, this.nextCursor, this.results);
}

/// Generic stream of results from TT'a API.
///
/// An [ApiResult] overrides `operator []` to allow for indexed access to
/// its members. Trying to access an index which has not been fetched yet
/// or is out of bounds returns `null`.
///
/// Since this is a networked-backed list, any attempts to access indices close
/// to the current length (within 20% of the `count`) of the list or past the bounds will trigger
/// a network request to fetch more. You can subscribe to changes to this list
/// caused by network requests by calling [setOnChanged()].
///
class ApiStream<T> {
  int _maxCursor = 0;
  int count = 0;
  Future<ApiResult<T>> Function(int count, int maxCursor) _stream;

  // Used for checking if we can fetch more
  bool isFetching = false;
  bool hasMore = true;

  // Internal list used for caching network results
  List<T> _results;

  // Callback for when data changes
  void Function() _cb = () {};

  /// Construct an [ApiStream]
  ///
  /// Avoid calling this directly in favor of [API]'s static methods.
  ApiStream(this.count, this._stream, {List<T> initialResults}) {
    this._results = initialResults != null ? initialResults : [];
  }

  /// Return a const inner list
  Map<int, T> get results => _results.asMap();

  // The internal list grows linearly starting from 0.
  // Note: This should probably be fixed to allow for 'seeking'
  //   to the right position, but it is unclear how to start from
  //   an arbitrary index considering that each network request returns
  //   the next max cursor to fetch from.
  // Note2: We use the count as an indication of how frequently to fetch (20% of
  //   the count is defined as the bounds for fetching)
  T operator [](int i) {
    // If we see that we need more, fetch in the background
    if (hasMore && i >= _results.length - max(1, (count * 0.2).floor()))
      _next().then((value) {
        print("API STREAM FETCHED: $value");

        // Do nothing if we get nothing
        if (value.isEmpty) return;

        _results.addAll(value);

        // Update listener
        this._cb();
      });

    // Just in case we took too long and forgot to fetch, we return null
    return i >= _results.length ? null : _results[i];
  }

  /// Returns the length of the stream in its current form.
  ///
  /// Note: This __will__ change if trying to access an index near or past
  /// the end. See [setOnChanged()] for more info.
  int get length => _results.length;

  /// Clear the current cache of this stream and force a reload
  Future<void> refresh() {
    // Clear the current results
    _results.clear();

    // Reset the state
    _maxCursor = 0;
    isFetching = false;
    hasMore = true;

    // Alert listeners about the changes
    this._cb();

    return Future.value();
  }

  /// Attach a callback when the list updates.
  ///
  /// Since this is a networked-backed list, use this method to know when
  /// the underlying list has been updated due to network requests.
  ///
  /// As an example, to have your view update whenever new items are added:
  ///
  /// ```dart
  /// @override
  /// void initState() {
  ///   ApiStream<T> stream = ...;
  ///   stream.setOnChanged(() => setState(() {}));
  /// }
  /// ```
  void setOnChanged(void Function() cb) => this._cb = cb;

  /// Transform this [ApiStream] using a mapping function
  ///
  /// In the event that you need an existing [ApiStream] to wrap a different
  /// data structure (such as when converting [MusicResult] to a [VideoResult])
  /// simply pass a mapping function that, given the original wrapped data
  /// structure, generates the new data structure. This transformation is then
  /// applied to every currently loaded result and kept in order to be used
  /// when requesting the [next()] set of results.
  ///
  /// For an in-depth example, see [SoundGroup].
  ApiStream<U> transform<U>(U Function(T) transformer) {
    return ApiStream(count, (count, cursor) async {
      final res = await _stream(count, cursor);
      if (res == null) return Future.value(null);

      // Map all of the stream
      final trans = ApiResult<U>(
          res.hasMore, res.nextCursor, res.results.map((e) => transformer(e)));
      return Future.value(trans);
    }, initialResults: _results.map((e) => transformer(e)).toList());
  }

  // Fetches the next set of `count` results.
  Future<Iterable<T>> _next() async {
    // Stop multiple requests / when no more videos are available
    // TODO: Maybe use null or a tuple here to signal difference between requesting and done?
    if (isFetching || !hasMore) return [];
    isFetching = true;

    ApiResult<T> r;
    try {
      r = await _stream(count, _maxCursor);
      print("Next: $r");
      _maxCursor = r.nextCursor;
    } catch (e) {
      print("WARNING: Fetching failed with: $e");
      print("WARNING: Failing silently...");
    } finally {
      isFetching = false;
    }

    // print("GOT NEXT CURSOR: $maxCursor");
    return r.results;
  }
}

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
      "aweme_id": video.id,
      "uid": _userInfo.user.id,
      "did": _webId,
      "device_id": _webId,
      "verifyFp": "",
      "cookie_enabled": true,
      "type": shouldLike ? 1 : 0, // 1 for enable, 0 for disable
    });
    // https://m.tiktok.com/api/commit/item/digg/?aid=1988&cookie_enabled=true&appId=1233&did=6863171026114332166&uid=6609695707618492422&device_id=6863171026114332166&aweme_id=6861656038039391494&type=1&verifyFp=

    // Sign the url using TT JS
    // Note: We construct a headless webview first and then dispose of
    //   it after we finish generating the code
    await _webView.run();
    String code = await sign(url);
    String signedUrl = "$url&_signature=$code";
    await _webView.dispose();
    print("GOT URL: $signedUrl");

    // Make a request for the videos
    //   Note: We attach the login cookie if available
    var response = await http.post(signedUrl,
        headers: {
          "User-Agent": USER_AGENT,
          "cookie": _loginToken != null
              ? "sid_guard=${_loginToken.value.toString()}"
              : "",
          "Accept": "application/json, text/plain, */*",
          "Content-Type": "application/x-www-form-urlencoded",
          "DNT": "1",
          "Origin": "https://www.tiktok.com",
          "Referer": "https://www.tiktok.com/"
        },
        body: "");

    // If we failed to like, let caller know
    if (response.statusCode != 200) return Future.value(false);

    Map<String, dynamic> asJson = json.decode(response.body);
    return Future.value(asJson.containsKey("is_digg") && shouldLike);
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

        return _getVideos(url, count, cursor);
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

        return _getVideos(url, count, cursor);
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

        return _getVideos(url, count, cursor);
      });

  /// NOT IMPLEMENTED
  ///
  /// Get an [ApiStream]<[Comment]> of a [video]'s comments.
  static ApiStream<dynamic> getVideoCommentStream(
      VideoResult video, int count) {
    throw Exception("Not Implemented");
  }

  static ApiStream<MusicResult> getVideosForMusic(Music m, int count) =>
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

        return _getVideosForMusic(url, count, maxCursor);
      });

  static ApiStream<HashtagResult> getTrendingHashtags(int count) => ApiStream(
      count, (count, maxCursor) => _getTrendingHashtag(count, maxCursor));

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

        return _getVideosForMusic(url, count, maxCursor);
      }).transform((MusicResult r) => VideoResult(
          id: r.id,
          createTime: r.createTime,
          desc: r.text,
          author: r.author,
          music: r.musicInfo,
          video: r.video,
          stats: r.stats));

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

  /// Gets an [ApiResult] containing a set of hashtags that are currently trending
  static Future<ApiResult<HashtagResult>> _getTrendingHashtag(
      int count, int cursor) async {
    String url = _getFormattedUrl("api/discover/challenge", {
      "discoverType": 0,
      "needItemList": false,
      "keyWord": "",
      "offset": cursor,
      "count": count
    });

    dynamic asJson = await _fetchResults(url);
    List<dynamic> hashtags = asJson["challengeInfoList"];

    int offset = int.tryParse(asJson["offset"]);

    // TODO: How do we know that there isn't more?
    return ApiResult(offset != 0 && offset != cursor, offset,
        hashtags.map((h) => HashtagResult.fromJson(h)));
  }

  /// Gets an [ApiResult] containing a set of videos of max size [count] from
  /// the [url] endpoint.
  ///
  /// A [cursor] value of `0` fetches from the start of the results.
  ///
  /// Any non-zero [cursor] specifies where to start the search from and is
  /// part of the [ApiResult]. The [cursor] does not seem to have any obvious
  /// pattern and, as such, should only be supplied from a previous [ApiRequest].
  static Future<ApiResult<VideoResult>> _getVideos(
      String url, int count, int cursor) async {
    dynamic asJson = await _fetchResults(url);
    List<dynamic> array = asJson["items"];

    // Short out if we get no results
    if (array == null) return ApiResult(false, cursor, []);

    bool hasMore = asJson["hasMore"];
    int maxCursor = int.tryParse(asJson["maxCursor"]);
    return ApiResult(
        hasMore, maxCursor, array.map((e) => VideoResult.fromJson(e)));
  }

  /// Gets an [ApiResult] containing a list of videos that use a given [Music] track
  static Future<ApiResult<MusicResult>> _getVideosForMusic(
      String url, int count, int cursor) async {
    dynamic asJson = (await _fetchResults(url))["body"];
    List<dynamic> array =
        asJson["itemListData"]; // different from stock _getVideos

    // Short out if we get no results
    if (array == null) return ApiResult(false, cursor, []);

    bool hasMore = asJson["hasMore"];
    int maxCursor = int.tryParse(asJson["maxCursor"]);

    return ApiResult(
        hasMore, maxCursor, array.map((e) => MusicResult.fromJson(e)));
  }

  /// NOT IMPLEMENTED
  ///
  /// Fetches a batch of commments from [url]. See [_getVideos()] for more
  /// info.
  // static Future<ApiResult<dynamic>> _getComments(
  //     String url, int count, int cursor) async {
  //   throw Exception("Not Implemented");
  // }

  /// Fetches data from a TT endpoint
  static Future<dynamic> _fetchResults(String url) async {
    // Sign the url using TT JS
    // Note: We construct a headless webview first and then dispose of
    //   it after we finish generating the code
    await _webView.run();
    String code = await sign(url);
    String signedUrl = "$url&_signature=$code";
    await _webView.dispose();
    print("GOT URL: $signedUrl");

    // Make a request for the videos
    //   Note: We attach the login cookie if available
    var response = await http.get(signedUrl, headers: {
      "User-Agent": USER_AGENT,
      "cookie":
          _loginToken != null ? "sid_guard=${_loginToken.value.toString()}" : ""
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
  static String _getFormattedUrl(
      String endpoint, Map<String, dynamic> options) {
    String result = "https://m.tiktok.com/$endpoint/";

    // Apply all of the options
    result += options.entries.fold(
        "?appId=1233&language=$_lang",
        (previousValue, element) =>
            "$previousValue&${element.key}=${element.value.toString()}");

    return result;
  }
}
