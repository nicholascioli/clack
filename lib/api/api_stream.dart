import 'dart:math';

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

  // Used for checking if we can (and should) fetch more
  bool isFetching = false;
  bool hasMore = true;
  bool autoFetch = true;

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
    if (hasMore &&
        autoFetch &&
        i >= _results.length - max(1, (count * 0.2).floor())) fetch();

    // Just in case we took too long and forgot to fetch, we return null
    return i >= _results.length ? null : _results[i];
  }

  /// Ensure that the stream has fetched at least once
  Future<void> preload() async {
    if (_results.isEmpty && hasMore) await fetch();

    return Future.value();
  }

  /// Fetch the next set of results in the background
  Future<void> fetch() async {
    // Don't do anything if we have no more results or we are currently fetching
    if (isFetching || !hasMore) return Future.value();

    // Lock all future fetches until we finish
    isFetching = true;

    ApiResult<T> r = ApiResult(false, 0, []);
    try {
      r = await _stream(count, _maxCursor);
      // print("Next: (${r.nextCursor} | ${r.hasMore}) -> ${r.results}");
      _maxCursor = r.nextCursor;
      hasMore = r.hasMore;
    } catch (e) {
      print("WARNING: Fetching failed with: $e");
      print("WARNING: Failing silently...");
    } finally {
      // Release the lock on requests
      isFetching = false;
    }

    // Save the new results to ourselves, if any
    if (r.results.isNotEmpty) _results.addAll(r.results);

    // Call the listeners
    this._cb();

    return Future.value();
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
}
