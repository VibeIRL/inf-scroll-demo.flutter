import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VIBEirl Inf. Scroll Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      home: const MultiSourceInfiniteScrollPage(),
    );
  }
}

// The infinite scroll page, utilizing multiple asynchronous data sources.
class MultiSourceInfiniteScrollPage extends StatefulWidget {
  const MultiSourceInfiniteScrollPage({super.key});

  @override
  _MultiSourceInfiniteScrollPageState createState() =>
      _MultiSourceInfiniteScrollPageState();
}

// The internal state of the infinite scroll page.
class _MultiSourceInfiniteScrollPageState
    extends State<MultiSourceInfiniteScrollPage> {
  // BehaviorSubject to manage the data stream.
  late BehaviorSubject<List<String>> _mergedDataSubject;
  // Scroll controller to manage user scrolling actions.
  late ScrollController _scrollController;
  // List to store the data fetched from multiple sources.
  final List<String> _dataList = [];
  List<String> _filteredDataList = [];
  // Number of items fetched per request from each source.
  final int _perPage = 10;
  // Counters to track the data fetched from each source.
  int _source1Counter = 0;
  int _source2Counter = 0;
  int _source3Counter = 0;
  // Flags to indicate if data is currently being loaded or pre-fetched.
  bool _isLoading = false;
  bool _prefetching = false;
  Timer? _pollingTimer;

  // Maximum items to keep in memory.
  final int _maxKeep = 60;
  // Number of old items to remove at once.
  final int _pruneSize = 20;
  // Threshold to start prefetching when this many items remain.
  final int _prefetchThreshold = 15;

  @override
  void initState() {
    super.initState();
    // Initialize the BehaviorSubject.
    _mergedDataSubject = BehaviorSubject<List<String>>();
    // Initialize the ScrollController and add a listener to it.
    _scrollController = ScrollController()..addListener(_scrollListener);
    // Start polling for data updates periodically (every 10 seconds in this case).
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _loadDataFromAllSources();
    });
    // Load the initial data from all sources.
    _loadInitialData();
  }

  @override
  void dispose() {
    // Cancel the polling timer.
    _pollingTimer?.cancel();
    // Close the BehaviorSubject and dispose of the ScrollController.
    _mergedDataSubject.close();
    _scrollController.dispose();
    super.dispose();
  }

  // Load initial data from all available sources.
  void _loadInitialData() {
    _loadDataFromAllSources();
  }

  // Load data from all sources concurrently.
  void _loadDataFromAllSources() {
    if (_isLoading) return;

    // Set the loading flag to true.
    setState(() {
      _isLoading = true;
    });

    // Simulate loading data from three sources concurrently using Future.wait.
    Future.wait([
      _loadDataFromSource1(),
      _loadDataFromSource2(),
      _loadDataFromSource3(),
    ]).then((allResults) {
      // Flatten the results into a single list and append them to the existing data.
      _appendData(allResults.expand((results) => results).toList());
      // Update the BehaviorSubject stream with the latest data.
      _filteredDataList = List<String>.from(_dataList);
      _mergedDataSubject.add(List<String>.from(_filteredDataList));
      // Reset the loading flag.
      setState(() {
        _isLoading = false;
      });
    }).catchError((e) {
      // Reset the loading flag in case of an error.
      setState(() {
        _isLoading = false;
      });
    });
  }

  // Append new data to the existing list and prune old items.
  void _appendData(List<String> newData) {
    _dataList.addAll(newData);
    _pruneOldItems();
  }

  // Prune old items outside the visible region.
  void _pruneOldItems() {
    // Prune a fixed number of old items if data exceeds the maximum allowed.
    if (_dataList.length > _maxKeep) {
      _dataList.removeRange(0, _pruneSize);
    }
  }

  // Simulate asynchronous data fetching from Source 1.
  Future<List<String>> _loadDataFromSource1() async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    return List.generate(
      _perPage,
      (index) => 'Source 1 - Item ${_source1Counter * _perPage + index + 1}',
    );
  }

  // Simulate asynchronous data fetching from Source 2.
  Future<List<String>> _loadDataFromSource2() async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    return List.generate(
      _perPage,
      (index) => 'Source 2 - Item ${_source2Counter * _perPage + index + 1}',
    );
  }

  // Simulate asynchronous data fetching from Source 3.
  Future<List<String>> _loadDataFromSource3() async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    return List.generate(
      _perPage,
      (index) => 'Source 3 - Item ${_source3Counter * _perPage + index + 1}',
    );
  }

  // Scroll listener to prefetch more data when nearing the end of the list.
  void _scrollListener() {
    // Check if we are nearing the end of the list to start prefetching.
    if (!_prefetching &&
        _scrollController.position.maxScrollExtent -
                _scrollController.position.pixels <=
            _prefetchThreshold * 48) { // Approximate item height in pixels
      _prefetching = true;
      _source1Counter++;
      _source2Counter++;
      _source3Counter++;
      _loadDataFromAllSources();
      _prefetching = false;
    }
  }

  // Search function to filter data.
  void _search(String query) {
    if (query.isEmpty) {
      _filteredDataList = List<String>.from(_dataList);
    } else {
      _filteredDataList = _dataList
          .where((item) => item.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    _mergedDataSubject.add(List<String>.from(_filteredDataList));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Create an AppBar with a title and search bar.
      appBar: AppBar(
        title: const Text('Multi-Source Infinite Scroll'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: "Search...",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(),
              ),
              onChanged: _search,
            ),
          ),
        ),
      ),
      // Build a StreamBuilder that listens to the merged data stream.
      body: StreamBuilder<List<String>>(
        stream: _mergedDataSubject.stream,
        builder: (context, snapshot) {
          // If data is available, display it in a ListView.
          if (snapshot.hasData) {
            final data = snapshot.data!;
            return ListView.builder(
              // Attach the ScrollController to the ListView.
              controller: _scrollController,
              // Add an extra item for the loading indicator.
              itemCount: data.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                // Display the data items.
                if (index < data.length) {
                  return ListTile(
                    title: Text(data[index]),
                  );
                } else {
                  // Show a loading indicator when fetching data.
                  return const Center(child: CircularProgressIndicator());
                }
              },
            );
          } else {
            // Display a loading indicator when the data is initially loaded.
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
