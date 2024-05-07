import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import '../models/country.dart';
import '../services/api.dart';
import '../widgets/country_card.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/custom_app_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late ScrollController _scrollController;
  late BehaviorSubject<List<Country>> _dataSubject;
  final List<Country> _data = [];
  late List<Country> _filteredData = [];
  late TextEditingController _searchController;
  final api = Api();
  bool _isLoading = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _dataSubject = BehaviorSubject<List<Country>>();
    _searchController = TextEditingController();
    _scrollController = ScrollController()..addListener(_scrollListener);
    loadData(); // Fetch initial data
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _dataSubject.close();
    _searchController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        !_isSearching) {
      loadData();
    }
  }

  void _onSearchChanged() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _isSearching = query.isNotEmpty;
      _filteredData = _data.where((country) {
        return country.name.toLowerCase().contains(query) ||
            country.capital.toLowerCase().contains(query) ||
            country.currency.toLowerCase().contains(query);
      }).toList();
      _dataSubject.add(_filteredData);
    });
  }

  Future<void> loadData() async {
    if (!_isLoading && !_isSearching) {
      setState(() => _isLoading = true);
      List<Country> newData = await api.fetchDataFromApis();
      setState(() {
        _data.addAll(newData);
        _dataSubject.add(_data);
        _filteredData.addAll(newData);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(MediaQuery.of(context).size.height *
            0.15), // Adjust height as needed
        child: LayoutBuilder(
          builder: (context, constraints) {
            return CustomAppBar(
              title: 'Countries Infinite Scroll',
              searchField: SizedBox(
                width: 300,
                height: 40,
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      body: StreamBuilder<List<Country>>(
        stream: _dataSubject.stream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return LayoutBuilder(builder: (context, constraints) {
              int crossAxisCount = 1;
              if (constraints.maxWidth >= 600) {
                crossAxisCount =
                    2; // Adjust the threshold and number of columns as needed
              }
              return CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(16.0),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 10.0,
                          mainAxisSpacing: 10.0,
                          childAspectRatio: crossAxisCount == 1
                              ? MediaQuery.of(context).size.width /
                                  (MediaQuery.of(context).size.height / 8)
                              : MediaQuery.of(context).size.width /
                                  (MediaQuery.of(context).size.height / 4)),
                      delegate: SliverChildBuilderDelegate(
                          (BuildContext context, int index) {
                        if (index < snapshot.data!.length) {
                          final data = snapshot.data![index];
                          return CountryCard(country: data);
                        }
                        return null;
                      }, childCount: snapshot.data!.length),
                    ),
                  ),
                  if (_isLoading)
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (BuildContext context, int index) {
                          return const Center(child: LoadingIndicator());
                        },
                        childCount: 1,
                      ),
                    ),
                ],
              );
            });
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else {
            return const Center(child: LoadingIndicator());
          }
        },
      ),
    );
  }
}
