import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:clack/api/author_result.dart';
import 'package:clack/api/video_result.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
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
  int _count = 0;
  Future<ApiResult<T>> Function(int count, int maxCursor) _stream;

  // Used for checking if we can fetch more
  bool isFetching = false;
  bool hasMore = true;

  // Internal list used for caching network results
  List<T> _results = [];

  // Callback for when data changes
  void Function() _cb;

  /// Construct an [ApiStream]
  ///
  /// Avoid calling this directly in favor of [API]'s static methods.
  ApiStream(this._count, this._stream);

  // The internal list grows linearly starting from 0.
  // Note: This should probably be fixed to allow for 'seeking'
  //   to the right position, but it is unclear how to start from
  //   an arbitrary index considering that each network request returns
  //   the next max cursor to fetch from.
  // Note2: We use the count as an indication of how frequently to fetch (20% of
  //   the count is defined as the bounds for fetching)
  operator [](int i) {
    // If we see that we need more, fetch in the background
    if (i >= _results.length - max(1, (_count * 0.2).floor()))
      _next().then((value) {
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

  // Fetches the next set of `count` results.
  Future<Iterable<T>> _next() async {
    // Stop multiple requests / when no more videos are available
    // TODO: Maybe use null or a tuple here to signal difference between requesting and done?
    if (isFetching || !hasMore) return [];
    isFetching = true;

    ApiResult<T> r;
    try {
      r = await _stream(_count, _maxCursor);
      _maxCursor = r.nextCursor;
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
  static const String _USER_AGENT =
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/83.0.4103.97 Safari/537.36";
  static const String _TEMPLATE_URL =
      "https://m.tiktok.com/api/item_list/?id=1&secUid=&minCursor=0&sourceType=12&appId=1233";

  // We need a [HeadlessInAppWebView] in order to perform url signing because
  //   the signing process is done using obfuscated JS
  static final HeadlessInAppWebView _webView = HeadlessInAppWebView(
      initialUrl: "",
      initialHeaders: {},
      initialOptions: InAppWebViewGroupOptions(
          crossPlatform: InAppWebViewOptions(userAgent: _USER_AGENT)));

  /// Get an [ApiStream]<[VideoResult]> of currently trending videos.
  static ApiStream<VideoResult> getTrendingStream(int count) =>
      ApiStream(count, (count, cursor) {
        // TODO: Make this allow for querying anything, not just the trending
        String url = "$_TEMPLATE_URL&count=$count&maxCursor=$cursor&type=5";
        return _getVideos(url, count, cursor);
      });

  /// Get an [ApiStream]<[VideoResult]> of an [author]'s list of videos.
  static ApiStream<VideoResult> getAuthorVideoStream(
          Author author, int count) =>
      ApiStream(count, (count, cursor) {
        String url =
            "https://m.tiktok.com/api/item_list/?count=$count&id=${author.id}&type=1&secUid=${author.secUid}&maxCursor=$cursor&minCursor=0&sourceType=8&appId=1233&language=en";
        return _getVideos(url, count, cursor);
      });

  /// Get an [ApiStream]<[VideoResult]> of an [author]'s liked videos.
  ///
  /// This function will return an empty list if the [author]'s liked videos
  /// are private. See [Author].
  static ApiStream<VideoResult> getAuthorFavoritedVideoStream(
          Author author, int count) =>
      ApiStream(count, (count, cursor) {
        String url =
            'https://m.tiktok.com/api/item_list/?count=$count&id=${author.id}&type=$TYPE_LIKED_VIDEOS&secUid=${author.secUid}&maxCursor=$cursor&minCursor=0&sourceType=9&appId=1233';
        return _getVideos(url, count, cursor);
      });

  /// NOT IMPLEMENTED
  ///
  /// Get an [ApiStream]<[Comment]> of a [video]'s comments.
  static ApiStream<dynamic> getVideoCommentStream(
      VideoResult video, int count) {
    throw Exception("Not Implemented");
  }

  /// Get an [author]'s extended info.
  ///
  /// This returns a [Future] as it requires network requests.
  static Future<AuthorResult> getAuthorInfo(Author author) async {
    String url =
        "https://m.tiktok.com/api/user/detail/?uniqueId=${author.uniqueId}&language=en";

    // Sign the url using TT JS
    // Note: We construct a headless webview first and then dispose of
    //   it after we finish generating the code
    await _webView.run();
    String code = await sign(url);
    // String code = "_02B4Z6wo00f01i39SdgAAIBCH934gt2LpXIt.E1AANSG77";
    String signedUrl = "$url&_signature=$code";
    await _webView.dispose();
    print("GOT URL: $signedUrl");

    // Make a request for the user
    var response =
        await http.get(signedUrl, headers: {"User-Agent": _USER_AGENT});

    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      dynamic asJson = json.decode(response.body);
      dynamic user = asJson["userInfo"];

      return AuthorResult.fromJson(user);
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception('Failed to fetch user');
    }
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
    // Sign the url using TT JS
    // Note: We construct a headless webview first and then dispose of
    //   it after we finish generating the code
    await _webView.run();
    String code = await sign(url);
    String signedUrl = "$url&_signature=$code";
    await _webView.dispose();
    print("GOT URL: $signedUrl");

    // Make a request for the videos
    var response =
        await http.get(signedUrl, headers: {"User-Agent": _USER_AGENT});

    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      // print("GOT RESPONSE: ${response.body}");
      dynamic asJson = json.decode(response.body);
      List<dynamic> array = asJson["items"];

      // Short out if we get no results
      if (array == null) return ApiResult(false, cursor, []);

      bool hasMore = asJson["hasMore"];
      int maxCursor = int.tryParse(asJson["maxCursor"]);
      return ApiResult(
          hasMore, maxCursor, array.map((e) => VideoResult.fromJson(e)));
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception('Failed to fetch videos from $url: ${response.body}');
    }
  }

  /// NOT IMPLEMENTED
  ///
  /// Fetches a batch of commments from [url]. See [_getVideos()] for more
  /// info.
  // static Future<ApiResult<dynamic>> _getComments(
  //     String url, int count, int cursor) async {
  //   throw Exception("Not Implemented");
  // }

  static Future<String> sign(String url) async {
    // Now execute
    var givenJS = rootBundle.loadString('js/acrawler.js');
    return givenJS.then((String js) async {
      return await _webView.webViewController.evaluateJavascript(
          source: "$js; byted_acrawler.sign({ url: \"$url\" })");
    });
  }
}
