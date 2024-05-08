import 'package:flutter/material.dart';
import 'package:inf_scroll_demo/custom_relay_subject.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Infinite Scroll',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late CustomRelaySubject<List<int>> _dataSubject;
  final ScrollController _scrollController = ScrollController();
  int _perPage = 10;
  int _counter = 0;

  @override
  void initState() {
    super.initState();
    _dataSubject = CustomRelaySubject<List<int>>(initialMaxSize: 5);
    _scrollController.addListener(_scrollListener);

    loadData();
  }

  @override
  void dispose() {
    _dataSubject.close();
    _scrollController.dispose();
    super.dispose();
  }

  void loadData() async {
    // Simulating loading data asynchronously

    await Future.delayed(const Duration(seconds: 2), () {
      final newData =
          List.generate(_perPage, (index) => _counter * _perPage + index + 1);
      _dataSubject.add(newData);
      _counter++; // Increment counter for pagination
      setState(() {});
    });

    if (!_scrollController.hasClients) {
      _counter = 0;
      _perPage += _perPage;

      loadData();
    } else {
      _scrollController.animateTo(0.0,
          duration: const Duration(milliseconds: 200), curve: Curves.easeInOut);
    }
  }

  void _scrollListener() {
    if (_scrollController.offset >=
            _scrollController.position.maxScrollExtent &&
        !_scrollController.position.outOfRange) {
      // Reached the end, load more data
      loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Infinite Scroll Example'),
      ),
      body: StreamBuilder<List<int>>(
        stream: _dataSubject.stream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final data = snapshot.data!;
            return ListView.builder(
              controller: _scrollController,
              itemCount: data.length + 1, // +1 for loading indicator
              itemBuilder: (context, index) {
                if (index < data.length) {
                  return ListTile(
                    title: Text('Item ${data[index]}'),
                  );
                } else {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
              },
            );
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }
}
