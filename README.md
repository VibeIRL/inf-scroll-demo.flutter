# inf_scroll_demo

A new Flutter project skeleton.

>
> Your Task:
> Build an infinite scroll widget that accepts data from 3+ asynchronous sources*, using RxDart.
> The items in the scroll list can just be text - no images/files required.
> 

1. clone repo
2. make changes (because the current inf scroll code doesn't really work on Chrome/Desktop, and please make it work)
3. Feel free to change all the code in main.dart, to whatever you see fit
3. create a PR on a branch to our repo - or push to your personal repo (the main branch here is protected on GH)
4. it should run with `flutter run -d chrome` or `flutter run -d mac`
5. feel free to use chatgpt (etc) to generate code, but bring some custom solutions too, there are lot of cool features to add to infinite scroll, including search/filter
6. ideally pre-fetch new items + discard old items (outside the viewport) from memory
7. remember that the feed should have some ranking/sorting way that is somewhat predictable so items aren't arbitrarily re-ordered
8. and - you can mock all the i/o - no need for any backend services
5. demo your app to us


thanks

*Some example data sources:

* memory
* local-storage (hive)
* interval (simulate polling)
* websocket (simulate a websocket connection using a mock library)

 

## Basics 

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
