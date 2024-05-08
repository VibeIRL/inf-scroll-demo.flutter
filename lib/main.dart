import 'dart:io';
import 'dart:math';

import 'package:data_connection_checker_tv/data_connection_checker.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

final GlobalKey<ScaffoldMessengerState> snackBarKey =
    GlobalKey<ScaffoldMessengerState>();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: snackBarKey,
      home: const InfiniteListView(),
    );
  }
}

class InfiniteListView extends StatefulWidget {
  const InfiniteListView({super.key});

  @override
  _InfiniteListViewState createState() => _InfiniteListViewState();
}

class _InfiniteListViewState extends State<InfiniteListView> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final ItemManager _manager = ItemManager();

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.atEdge) {
        if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent) {
          _manager.fetchMoreData();
        }
      }
    });
    _searchController.addListener(() {
      _manager.searchItems(_searchController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Infinite Scroll'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search',
                fillColor: Colors.white,
                filled: true,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderSide:
                      const BorderSide(width: 1, style: BorderStyle.none),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              // onChanged: (value){},
            ),
          ),
        ),
      ),
      body: StreamBuilder<bool>(
          stream: _manager.isLoadingStream,
          builder: (context, snapshotLoading) {
            return RefreshIndicator(
              key: _refreshIndicatorKey,
              onRefresh: () async {
                return _manager.refreshItems();
              },
              child: StreamBuilder<List<Item>>(
                stream: _manager.itemsStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final items = snapshot.data!;
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    controller: _scrollController,
                    itemCount:
                        items.length + (snapshotLoading.data ?? false ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= items.length) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final item = items[index];
                      Color bgColor = _getPriorityColor(item);
                      return Container(
                        key: ValueKey(item.text + item.priority.toString()),
                        padding: const EdgeInsets.all(4),
                        child: ListTile(
                          tileColor: bgColor,
                          title: Text(item.text),
                          subtitle: Text('Priority: ${item.priority}'),
                        ),
                      );
                    },
                  );
                },
              ),
            );
          }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_refreshIndicatorKey.currentState != null) {
            _refreshIndicatorKey.currentState!.show();
          }
          _scrollToTopAndRefresh(context);
        },
        child: const Icon(Icons.home),
      ),
    );
  }

  Color _getPriorityColor(Item item) {
    if (item.viewed) {
      // Return a grey color if the item has been viewed.
      return Colors.grey[300]!;
    }

    // Calculate the color index based on the item's priority.
    // The modulus operator ensures that the priority maps to a value within the range of 0-7,
    // multiplying by 100 to align with the 100 increments in Material Color definitions for blue.
    int colorIndex = 100 + ((item.priority % 8) * 100);

    // Return the corresponding shade of blue from the Colors.blue color map.
    // This uses a bang operator (!) to assert that the resulting color is non-null.
    // Care should be taken that the item's priority does not lead to an invalid color index.
    return Colors.blue[colorIndex]!;
  }

  void _scrollToTopAndRefresh(BuildContext context) async {
    // Animate the scroll view to the top using the controller
    await _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
    );

    // Trigger data refresh
    _manager.refreshItems();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _manager.dispose();
    super.dispose();
  }
}

/// Represents a single item in a list, commonly used to model data in various UI components.
///
/// Each item has descriptive text, a priority level, and a viewed status, which may
/// be used to sort and display items based on user interactions and importance.
class Item {
  /// The descriptive text associated with this item.
  ///
  /// This text is typically displayed in a list in the UI and is used for identifying
  /// the item among others. It can also be used in searches and filtering.
  final String text;

  /// The priority of the item, used for sorting and prioritization.
  ///
  /// A higher priority value indicates a greater level of importance or urgency. This
  /// field can be used to sort items in a list, ensuring that items of higher priority
  /// are displayed before others.
  final int priority;

  /// Indicates whether the item has been viewed by the user.
  ///
  /// This boolean value helps to track user interaction with the item. For example,
  /// items might be highlighted or displayed differently in the UI if they have not
  /// been viewed yet.
  bool viewed;

  /// Constructs an instance of [Item].
  ///
  /// Requires [text] to describe the item and [priority] to determine its importance.
  /// The [viewed] status defaults to `false`, indicating that the item has not been viewed.
  ///
  /// Example:
  /// ```dart
  /// var newItem = Item(text: "Learn Dart", priority: 5, viewed: false);
  /// ```
  Item({required this.text, required this.priority, this.viewed = false});

  /// Returns a string representation of this item, including its properties.
  ///
  /// This method can be particularly useful for debugging purposes or when you
  /// need a simple textual representation of an item.
  ///
  /// Example output: "Item(text: Learn Dart, priority: 5, viewed: false)"
  @override
  String toString() =>
      "Item(text: $text, priority: $priority, viewed: $viewed)";
}

/// Provides methods to simulate fetching items from a backend.
///
/// This class is designed to handle pagination and sorting of data,
/// simulating a more realistic scenario where data is fetched in batches
/// from a server and sorted according to specific criteria.
class ItemRepository {
  /// The current page index for pagination.
  int _page = 0;

  /// Fetches the next batch of items, optionally resetting the pagination or specifying a page.
  ///
  /// This method handles fetching items based on pagination logic. It increments
  /// or resets the internal page counter based on the given parameters and then
  /// retrieves the items for the current page.
  ///
  /// [page] specifies a specific page number to fetch. If provided, pagination continues
  /// from this page. If null, it defaults to the next page based on the current [_page].
  /// [reset] when set to true, resets the pagination to the first page. This is useful
  /// for actions like pull-to-refresh.
  ///
  /// Returns a list of [Item]s for the current or specified page after applying sorting.
  Future<List<Item>> getNextItems({int? page, bool reset = false}) async {
    if (reset) {
      _page = 0; // Reset pagination to the first page.
    } else {
      _page = page ?? _page + 1; // Continue to the next page or specified page.
    }

    return fetchItems(_page);
  }

  /// Fetches and returns a list of items for a given page, applying predefined sorting.
  ///
  /// This function simulates a network call that fetches items from a backend service.
  /// It introduces a delay to mimic network latency and generates a list of items based
  /// on the page number. Each item's content is influenced by the page to ensure uniqueness
  /// across pagination.
  ///
  /// After generating the items, it sorts them based on whether they have been viewed and
  /// their priority. Unviewed items with higher priority come first.
  ///
  /// [page] the page number for which items are to be fetched.
  ///
  /// Returns a sorted list of [Item]s for the specified [page].
  Future<List<Item>> fetchItems(int page) async {
    await Future.delayed(
        const Duration(milliseconds: 1100)); // Simulate network delay

    Random rand = Random();
    var newList = List.generate(15, (index) {
      // Generate items with a text identifier and a random priority.
      return Item(
          text: 'Item ${index + page * 15}',
          priority: rand.nextInt(6), // Random priority between 0 and 5
          viewed: false // Initially, items are not viewed.
          );
    });

    // Sort the items first by 'viewed' status, then by 'priority'.
    newList.sort((a, b) {
      if (a.viewed != b.viewed) {
        return a.viewed ? 1 : -1; // UnViewed items come first.
      }
      return b.priority
          .compareTo(a.priority); // Sort by priority, highest first.
    });

    return newList;
  }
}

/// Manages item data and loading states for the application.
///
/// This class uses RxDart's BehaviorSubject to handle state changes
/// and stream updates to the UI when items are fetched, refreshed, or filtered
/// based on a search query.
class ItemManager {
  final BehaviorSubject<List<Item>> _items =
      BehaviorSubject<List<Item>>.seeded([]);
  final BehaviorSubject<bool> _isLoading = BehaviorSubject<bool>.seeded(false);
  final ItemRepository _repository = ItemRepository();
  String _currentSearchQuery = '';
  int _page = 0;

  /// Stream of items that can be subscribed to for real-time updates to the item list.
  Stream<List<Item>> get itemsStream => _items.stream;

  /// Stream indicating the loading state of the item fetch operations.
  Stream<bool> get isLoadingStream => _isLoading.stream;

  /// Constructs an [ItemManager] and initiates the first fetch operation.
  ItemManager() {
    fetchMoreData();
  }

  /// Fetches data from the repository and updates the items stream.
  ///
  /// This method will increment the page count each call to fetch subsequent data pages.
  /// If there is a search filter active, the fetched data will be filtered accordingly.
  void fetchMoreData() async {
    if (_isLoading.value) {
      return; // Prevents multiple concurrent fetch operations.
    }
    _isLoading.add(true);

    bool hasConnection = await CheckInternet.hasConnection();

    if (hasConnection == false) {
      // No connectivity, show a SnackBar or similar UI element
      snackBarKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text("No internet connection. Unable to fetch data."),
          duration: Duration(seconds: 3),
        ),
      );
      _isLoading.add(false);
      return;
    }

    List<Item> newItems = await _repository.getNextItems(page: _page);
    _page++;

    // Filter new items if a search query is active.
    if (_currentSearchQuery.isNotEmpty) {
      newItems = newItems
          .where((item) => item.text
              .toLowerCase()
              .contains(_currentSearchQuery.toLowerCase()))
          .toList();
    }

    // Adds the new (possibly filtered) items to the current list.
    _items.add([..._items.value, ...newItems]);

    _isLoading.add(false); // Indicates that the loading process is complete.
  }

  /// Refreshes the item list by clearing existing items and re-fetching from the first page.
  ///
  /// This method resets the page counter to zero and fetches fresh data from the repository.
  void refreshItems() async {
    bool hasConnection = await CheckInternet.hasConnection();

    if (hasConnection == false) {
      // No connectivity, show a SnackBar or similar UI element
      snackBarKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text("No internet connection. Unable to fetch data."),
          duration: Duration(seconds: 3),
        ),
      );
      _isLoading.add(false);
      return;
    }

    _page = 0;
    _items.value.clear();

    List<Item> newItems = await _repository.getNextItems(page: _page);
    _items.add(newItems); // Adds newly fetched items to the items stream.
  }

  /// Filters the list of items based on a search query.
  ///
  /// [query] The search string used to filter items. If the query is empty, data is re-fetched.
  void searchItems(String query) {
    _currentSearchQuery = query.toLowerCase();
    if (query.isEmpty) {
      _page = 0;
      _items.value.clear();
      fetchMoreData(); // Refetch data without any filter if the search query is cleared.
    } else {
      // Filter the current list of items according to the search query.
      final filteredItems = _items.value
          .where((item) => item.text.toLowerCase().contains(query))
          .toList();
      _items.add(filteredItems); // Update the stream with the filtered list.
    }
  }

  /// Cleans up resources managed by the manager, particularly the open streams.
  void dispose() {
    _items.close();
    _isLoading.close();
  }
}

class CheckInternet {
  static Future<bool> hasConnection() async {
    final bool connectivity = await DataConnectionChecker().hasConnection;
    bool pingSuccess = false;
    try {
      final result = await InternetAddress.lookup('example.com');
      pingSuccess = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      pingSuccess = false;
    }

    if (connectivity || pingSuccess) {
      return true;
    } else {
      return false;
    }
  }
}
