import 'package:rxdart/rxdart.dart';

class CustomRelaySubject<T> {
  late ReplaySubject<T> _replaySubject;

  CustomRelaySubject({int? initialMaxSize}) {
    _replaySubject = ReplaySubject<T>(maxSize: initialMaxSize);
  }

  void setMaxStreamSize(int maxSize) {
    List<T> oldData = _replaySubject.values;
    _replaySubject.close();
    _replaySubject = ReplaySubject<T>(maxSize: maxSize);
    for (int i = 0; i < oldData.length; i++) {
      _replaySubject.add(oldData[i]);
    }
  }

  void add(T value) {
    _replaySubject.add(value);
  }

  Stream<T> get stream => _replaySubject.stream;

  void close() {
    _replaySubject.close();
  }
}
