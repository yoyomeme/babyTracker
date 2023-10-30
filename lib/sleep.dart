import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class Sleep
{
  late String id; //(1)
  String? image;


  String? duration_class;
  String? notes_class;
  String? sleep_endTime_class;
  String sleep_startTime_class;
  String timeStamp_class;

  Sleep({required this.sleep_startTime_class, required this.timeStamp_class, this.image, this.duration_class, this.notes_class, this.sleep_endTime_class});

  //(2)
  Sleep.fromJson(Map<String, dynamic> json, this.id)
      :
        duration_class = json['duration_class'],
        notes_class = json['notes_class'],
        sleep_endTime_class = json['sleep_endTime_class'],
        sleep_startTime_class = json['sleep_startTime_class'],
        timeStamp_class = json['timeStamp_class'];

  Map<String, dynamic> toJson() =>
      {
        'duration_class': duration_class,
        'notes_class': notes_class,
        'sleep_endTime_class' : sleep_endTime_class,
        'sleep_startTime_class': sleep_startTime_class,
        'timeStamp_class' : timeStamp_class
      };
}

class SleepModel extends ChangeNotifier {
  /// Internal, private state of the list.
  final List<Sleep> items = [];

  Sleep? get(String? id)
  {
    if (id == null) return null;
    return items.firstWhere((sleep) => sleep.id == id);
  }

  //added this
  CollectionReference sleepsCollection = FirebaseFirestore.instance.collection('sleeps');

  //added this
  bool loading = false;

  //Normally a model would get from a database here, we are just hardcoding some data for this week
  SleepModel()
  {
    fetch(); //this line won't compile until the next step

  }

  /*void add(Sleep item) {
    items.add(item);
    update();
  }*/

  Future add(Sleep item) async
  {

    loading = true;
    update();

    await sleepsCollection.add(item.toJson());

    //refresh the db
    await fetch();
  }

  Future updateItem(String id, Sleep item) async
  {
    loading = true;
    update();

    await sleepsCollection.doc(id).set(item.toJson());

    //refresh the db
    await fetch();
  }

  Future delete(String id) async
  {
    loading = true;
    update();

    await sleepsCollection.doc(id).delete();

    //refresh the db
    await fetch();
  }

  // This call tells the widgets that are listening to this model to rebuild.
  void update()
  {
    notifyListeners();
  }

  Future fetch() async
  {
    //clear any existing data we have gotten previously, to avoid duplicate data
    items.clear();

    //indicate that we are loading
    loading = true;
    notifyListeners(); //tell children to redraw, and they will see that the loading indicator is on

    try {
      var querySnapshot = await sleepsCollection.orderBy("timeStamp_class", descending: true).get();

      //iterate over the sleeps and add them to the list
      for (var doc in querySnapshot.docs) {
        var sleep = Sleep.fromJson(doc.data()! as Map<String, dynamic>, doc.id);//note not using the add(Sleep item) function, because we don't want to add them to the db
        items.add(sleep);
        print('adding sleep item : ${sleep.timeStamp_class} , ${sleep.sleep_startTime_class}');
      }
      //put this line in to artificially increase the load time, so we can see the loading indicator (when we add it in a few steps time)
      //comment this out when the delay becomes annoying

      //await Future.delayed(const Duration(seconds: 2)); // artificial delay
    } catch (error) {
      print("Error fetching data: $error");
      // handle error according to your needs, e.g. show a message to the user
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // listen to the itemsStream() in your _MyHomePageState and update the UI whenever there's new data.
  Stream<List<Sleep>> itemsStream() {
    return sleepsCollection.orderBy("timeStamp_class").snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Sleep.fromJson(doc.data()! as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  Stream<SleepModel> get sleepModelStream {
    return sleepsCollection.orderBy("timeStamp_class").snapshots().map((snapshot) {
      // clear the current list of items
      items.clear();

      // add all the new items
      items.addAll(snapshot.docs.map((doc) {
        return Sleep.fromJson(doc.data()! as Map<String, dynamic>, doc.id);
      }).toList());

      // return this instance of SleepModel
      return this;
    });
  }

  Future<void> refreshSleeps() async {
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