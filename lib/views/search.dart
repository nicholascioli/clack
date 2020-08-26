import 'package:clack/api/api_stream.dart';
import 'package:clack/api/video_result.dart';
import 'package:clack/views/video_feed.dart';
import 'package:flutter/material.dart';

import 'package:clack/api.dart';

/// A search view for TT content
///
/// This view shows a blank screen until the user presses the
/// search icon in the top-right corner. The user can then type anything
/// as the [API] queries for suggestions in the backend. Finisheing the
/// search returns the user to the main page which then shows
/// all results separated into 4 tabs: User, Sounds, Hashtags, Videos
///
/// NOT IMPLEMENTED
class SearchView extends StatefulWidget {
  final void Function(VideoFeedActivePage active) setActive;

  const SearchView(this.setActive);

  @override
  _SearchViewState createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  String _title = "Search Page";
  ApiStream<VideoResult> res;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () => _handleBack(),
        child: DefaultTabController(
            length: 4,
            child: Scaffold(
                appBar: AppBar(
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back),
                    onPressed: () => _handleBack(),
                  ),
                  title: Text(_title),
                  actions: [
                    IconButton(
                        icon: Icon(Icons.search),
                        onPressed: () => showSearch(
                            context: context,
                            delegate: NetworkSearchDelegate<String>(
                              onResult: (result) {
                                //
                              },
                            ))),
                  ],
                  bottom: res != null
                      ? TabBar(tabs: [
                          Tab(child: Text("Users")),
                          Tab(child: Text("Sounds")),
                          Tab(child: Text("Hashtags")),
                          Tab(child: Text("Videos"))
                        ])
                      : null,
                ),
                body: res == null
                    ? Center(child: Text("Ready to Search"))
                    : _buildSearchResults())));
  }

  Widget _buildSearchResults() => TabBarView(children: [
        //
      ]);

  Future<bool> _handleBack() {
    setState(() => widget.setActive(VideoFeedActivePage.VIDEO));
    return Future.value(false);
  }
}

/// TT search delegate
///
/// Searches for suggestions in the background using [API].
///
/// NOT IMPLEMENTED
class NetworkSearchDelegate<T> extends SearchDelegate<T> {
  final void Function(String result) onResult;

  NetworkSearchDelegate({@required this.onResult});

  @override
  List<Widget> buildActions(BuildContext context) => this.query.isEmpty
      ? []
      : [IconButton(icon: Icon(Icons.clear), onPressed: () => this.query = "")];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
      icon: Icon(Icons.arrow_back), onPressed: () => this.close(context, null));

  // We want the results to appear in the search page, so here we close
  @override
  Widget buildResults(BuildContext context) {
    onResult(this.query);

    // Since we are only using this to then manually query for results,
    //   we return null
    this.close(context, null);
    return Container();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Center(child: Text(this.query));
  }
}
