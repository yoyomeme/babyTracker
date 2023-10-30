import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class Feed
{
  late String id; //(1)
  String? image;

  int? bottle_class;
  String duration_class;
  String feedTime_class;
  int? left_class;
  String? notes_class;
  int? right_class;
  String timeStamp_class;

  Feed({required this.duration_class, required this.feedTime_class, required this.timeStamp_class, this.image, this.left_class, this.bottle_class, this.right_class, this.notes_class});

  //(2)
  Feed.fromJson(Map<String, dynamic> json, this.id)
      :
  bottle_class = json['bottle_class'],
  duration_class = json['duration_class'],
  feedTime_class = json['feedTime_class'],
  left_class = json['left_class'],
  notes_class = json['notes_class'],
  right_class = json['right_class'],
  timeStamp_class = json['timeStamp_class'];

  Map<String, dynamic> toJson() =>
      {
        'bottle_class': bottle_class,
        'duration_class': duration_class,
        'feedTime_class' : feedTime_class,
        'left_class': left_class,
        'notes_class' : notes_class,
        'right_class': right_class,
        'timeStamp_class' : timeStamp_class
      };
}

class FeedModel extends ChangeNotifier {
  /// Internal, private state of the list.
  final List<Feed> items = [];


  Feed? get(String? id)
  {
    if (id == null) return null;
    return items.firstWhere((feed) => feed.id == id);
  }

  //added this
  CollectionReference feedsCollection = FirebaseFirestore.instance.collection('feeds');

  //added this
  bool loading = false;

  FeedModel()
  {

    fetch(); //this line won't compile until the next step

  }

  /*void add(Feed item) {
    items.add(item);
    update();
  }*/

  Future add(Feed item) async
  {

    loading = true;
    update();

    await feedsCollection.add(item.toJson());

    print('Item added. New length: ${items.length}');
    //refresh the db
    await fetch();
  }

  Future<void> addItem(Feed item) async {
    loading = true;
    update();

    DocumentReference docRef = await feedsCollection.add(item.toJson());

    item.id = docRef.id; // Set the id to the newly created document's id
    items.insert(0, item); // Insert the new item at the beginning of the list

    print('Item added. New length: ${items.length}');

    loading = false;
    update();
  }


  Future updateItem(String id, Feed item) async
  {
    loading = true;
    update();

    await feedsCollection.doc(id).set(item.toJson());

    //refresh the db
    await fetch();
  }

  Future delete(String id) async
  {
    loading = true;
    update();

    await feedsCollection.doc(id).delete();

    //refresh the db
    await fetch();
  }

  // This call tells the widgets that are listening to this model to rebuild.
  void update()
  {
    print('Calling notifyListeners...');
    notifyListeners();
    print('Finished calling notifyListeners...');

  }

  Future fetch() async
  {
    //clear any existing data we have gotten previously, to avoid duplicate data
    items.clear();

    //indicate that we are loading
    loading = true;
    notifyListeners(); //tell children to redraw, and they will see that the loading indicator is on

    //try {
      var querySnapshot = await feedsCollection.orderBy("timeStamp_class", descending: true).get();

      //iterate over the feeds and add them to the list
      for (var doc in querySnapshot.docs) {
        var feed = Feed.fromJson(doc.data()! as Map<String, dynamic>, doc.id);//note not using the add(Feed item) function, because we don't want to add them to the db
        items.add(feed);
        print('adding feed item : ${feed.timeStamp_class}');
      }
      //put this line in to artificially increase the load time, so we can see the loading indicator (when we add it in a few steps time)
      //comment this out when the delay becomes annoying

      //await Future.delayed(const Duration(seconds: 2)); // artificial delay
    //} catch (error) {
      //print("Error fetching data: $error");
      // handle error according to your needs, e.g. show a message to the user
    //} finally {
      loading = false;
      update();
    //}
  }

  // listen to the itemsStream() in your _MyHomePageState and update the UI whenever there's new data.
  Stream<List<Feed>> itemsStream() {
    return feedsCollection.orderBy("timeStamp_class").snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Feed.fromJson(doc.data()! as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  Stream<FeedModel> get feedModelStream {
    return feedsCollection.orderBy("timeStamp_class").snapshots().map((snapshot) {
      // clear the current list of items
      items.clear();

      // add all the new items
      items.addAll(snapshot.docs.map((doc) {
        return Feed.fromJson(doc.data()! as Map<String, dynamic>, doc.id);
      }).toList());

      // notify listeners that items have changed
      notifyListeners();

      // return this instance of FeedModel
      return this;
    });
  }

  Future<void> refreshFeeds() async {
    // Add your refresh code here.
    // For example, you might make an API call to get updated data.
    // For now we'll just wait for a second.
    //await Future.delayed(Duration(seconds: 1));

    // Fetch the feeds again here
    fetch();

    // Notify listeners to rebuild UI
    notifyListeners();
  }

}