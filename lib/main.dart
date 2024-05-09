import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:rxdart/rxdart.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:collection';
import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'dart:math';

void main() async {
  // Initialize Hive and open a LazyBox.
  await Hive.initFlutter();
  await Hive.openLazyBox<int>('numberBox');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  // Scroll controller and scroll dir flags.
  late final ScrollController _scrollController;
  bool _scrollUp = false;
  bool _scrollDown = false;

  // Data fed to _dataSubject _maxLoadSize items at a time.
  late final BehaviorSubject<List<String>> _dataSubject;

  // Input infrastructure for (1) and (2).
  late final LazyBox<int> _lazyBox;
  late final WebSocketChannel _echoChannel;

  // Streams for inputs (2) and (3).
  late final Stream<String> _echoStream;
  late final Stream<String> _breakingNewsStream;

  // Lists accumulated by stream subscribers.
  final List<String> _echoStrings = [];
  final List<String> _breakingNewsStrings = [];

  // Items displayed across viewport.
  final int _perPage = 10;

  // Set _resizePerPage to same value as _perPage - this variable
  // controls spacing of ListTiles if LayoutBuilder's height constraint
  // becomes too small (if dev tools is opened, for example).
  int _resizePerPage = 10;

  // List of items currently displayed and history flag; _feed
  // needs to accumulate if _keepHistory = true;
  List<String> _feed = [];
  bool _keepHistory = false;

  // Backlog of input data and max load size (which controls
  // the tradeoff between load size and backlog size).
  final DoubleLinkedQueue<String> _dataQueue = DoubleLinkedQueue();
  final int _maxLoadSize = 50;

  // Random number generator to generate input data.
  final Random _rand = Random();


  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_scrollListener);
    _dataSubject = BehaviorSubject<List<String>>();
    _lazyBox = Hive.lazyBox<int>('numberBox');
    _echoChannel = WebSocketChannel.connect(Uri.parse('wss://echo.websocket.events'));
    _echoStream = _echoChannel.stream.cast<String>();
    _breakingNewsStream = _breakingNews();
    _echoStream.listen(
      (val) => _echoStrings.add(val)
    );
    _breakingNewsStream.listen(
      (val) => _breakingNewsStrings.add(val)
    );
    _initialize();
  }

  @override
  void dispose() {
    _dataSubject.close();
    Hive.close();
    _echoChannel.sink.close();
    _scrollController.dispose();
    super.dispose();
  }

  // Populate Hive box for (1), start loop for (2), start loop
  // for maintaining backlog of (2) and (3), then load data.
  void _initialize() async {
    await _populateBox();
    _echoChannelLoop();
    _maintainBacklogLoop(5);
    _loadData();
  }

  // Populate Hive box with ints.
  Future<void> _populateBox() async {
    for (int i = 0; i < 500; i++) {
      await _lazyBox.put(i, i);
    }
  }

  // Loop for sending random amounts of string representations
  // of random ints through echo channel.
  Future<void> _echoChannelLoop() async {
    await _echoChannel.ready;
    while (true) {
      await Future.delayed(Duration(seconds: _rand.nextInt(20)));
      int count = _rand.nextInt(20);
      while (count-- > 0) {
        _echoChannel.sink.add(_rand.nextInt(1000).toString());
      }
    }
  }

  // Build stream that generates 'BREAKING NEWS' events at random.
  Stream<String> _breakingNews() async* {
    while (true) {
      await Future.delayed(Duration(seconds: _rand.nextInt(60)));
      yield 'BREAKING NEWS';
    }
  }

  // Loop for maintaining _dataQueue - pass delay, a number of
  // seconds. The newly available data from (2) and (3) is
  // added to the backlog after each delay interval.
  Future<void> _maintainBacklogLoop(int delay) async {
    late List<String> echo;
    late List<String> news;
    while (true) {
      await Future.delayed(Duration(seconds: delay));

      // Intermediate list to prevent the removal of data from
      // _echoStrings before it is enqueued.
      echo = List.from(_echoStrings);
      _dataQueue.addAll(echo);
      if (echo.length > 0) {
        _echoStrings.removeRange(0, echo.length);
      }

      // Intermediate list to prevent the removal of data from
      // _breakingNewsStrings before it is enqueued.
      news = List.from(_breakingNewsStrings);
      _dataQueue.addAll(news);
      if (news.length > 0) {
        _breakingNewsStrings.removeRange(0, news.length);
      }

      echo = [];
      news = [];
    }
  }

  // Get a batch of data (pass size of batch).
  Future<List<String>> _getData(int size) async {
    // Repopulate Hive box if necessary.
    if (_lazyBox.isEmpty) {
      await _populateBox();
    }

    // key is earliest added key in box, which corresponds in this
    // case to least key in box, and therefore to least value in box.
    int key = _lazyBox.keys.first;

    // If data available from (2) and (3) is less than size items,
    // pad to size with lazy box data.
    int end = key + size - _dataQueue.length - 1;
    while (key <= end) {
      int? val = await _lazyBox.get(key);
      if (val != null) {
        await _lazyBox.delete(key);
        _dataQueue.addLast(val.toString());
      }
      key++;
    }

    List<String> list = [];
    for (int i = 0; i < _maxLoadSize && !_dataQueue.isEmpty; i++) {
      list.add(_dataQueue.removeFirst());
    }

    return list;
  }

  // Load/sort data, add to previous data if keeping history then
  // send to _dataSubject.
  void _loadData() async {
    List<String> newData = await _getData(_maxLoadSize);

    // Order defined by the compare function, from least to greatest:
    //
    //  - 'BREAKING NEWS'
    //  - strings that can be parsed as ints, sorted in int order
    //  - all other strings, sorted in lexicographic order
    newData.sort(
      (a, b) {
        int? parseA = int.tryParse(a);
        int? parseB = int.tryParse(b);
        if (parseA != null && parseB != null) {
          return parseA.compareTo(parseB);
        } else if (a == 'BREAKING NEWS' && b != 'BREAKING NEWS') {
          return -1;
        } else if (a != 'BREAKING NEWS' && b == 'BREAKING NEWS') {
          return 1;
        } else {
          return a.compareTo(b);
        }
      }
    );

    if (_keepHistory) {
      for (var item in newData) {
        _feed.add(item);
      }
      newData = _feed;
    }

    _dataSubject.add(newData);
    if (!_keepHistory && _scrollController.hasClients) {
      // Put new data at top of viewport.
      _scrollController.jumpTo(0.0);
    }
  }

  void _scrollListener() {
    if (
      _scrollDown &&
      _scrollController.offset >= _scrollController.position.maxScrollExtent &&
      !_scrollController.position.outOfRange
    ) {
      // Reached the end, load more data.
      _loadData();
      _scrollDown = false;
    }
  }

  void _toggleKeepHistoryRadio(val) {
    setState(() => {
      _keepHistory = !_keepHistory
    });

    if (val == null) {
      _feed = [];
    } else {
      _feed = List.from(_dataSubject.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Infinite Scroll Example'),
        backgroundColor: Colors.teal.shade400,
        scrolledUnderElevation: 0.0,
        actions: List<Widget>.from([
          RadioMenuButton<bool>(
            value: true,
            toggleable: true,
            groupValue: _keepHistory,
            onChanged: _toggleKeepHistoryRadio,
            child: const Text('Keep History'),
          )
        ])
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxHeight < _resizePerPage * 50) {
            _resizePerPage = (constraints.maxHeight / 50).ceil();
          } else {
            _resizePerPage = _perPage;
          }
          // StreamBuilder nested in LayoutBuilder to access constraints.
          return StreamBuilder<List<String>>(
            stream: _dataSubject,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final data = snapshot.data!;
                return NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification n) {
                    if (n is UserScrollNotification && n.direction == ScrollDirection.forward) {
                      // Was considering using _scrollUp for something, so NotificationListener
                      // still flips flag here - as currently written though, the app doesn't care
                      // whether _scrollUp is true or false (it is never flipped back to false).
                      _scrollUp = true;
                    } else if (n is UserScrollNotification && n.direction == ScrollDirection.reverse) {
                      _scrollDown = true;
                    }
                    return true;
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: data.length >= _resizePerPage ? data.length + 1 : _resizePerPage + 1, // +1 for loading indicator
                    itemBuilder: (context, index) {
                      if (index < data.length) {
                        return SizedBox(
                          height: constraints.maxHeight / (_resizePerPage),
                          child: ListTile(
                            title: Text('${data[index]}'),
                          )
                        );
                      } else if (data.length < _resizePerPage) {
                        return SizedBox(
                          height: constraints.maxHeight / (_resizePerPage),
                          child: ListTile(
                            title: Text(''),
                          )
                        );
                      } else {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                    },
                  )
                );
              } else {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
            },
          );
        }
      ),
    );
  }
}

