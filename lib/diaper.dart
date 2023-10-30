import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';



class Diaper
{
  late String id; //(1)
  String? image;

  String? diaper_endTime_class;
  String diaper_startTime_class;
  int? dirty_class;
  int? dry_class;
  String? duration_class;
  String? notes_class;
  String timeStamp_class;
  int? wet_class;
  String? imagePath;

  Diaper({required this.diaper_startTime_class, required this.timeStamp_class, this.image, this.diaper_endTime_class, this.dirty_class, this.dry_class, this.duration_class, this.notes_class, this.wet_class, this.imagePath});

  //(2)
  Diaper.fromJson(Map<String, dynamic> json, this.id)
      :
        diaper_endTime_class = json['diaper_endTime_class'],
        diaper_startTime_class = json['diaper_startTime_class'],
        dirty_class = json['dirty_class'],
        dry_class = json['dry_class'],
        duration_class = json['duration_class'],
        notes_class = json['notes_class'],
        timeStamp_class = json['timeStamp_class'],
        wet_class = json['wet_class'],
        imagePath = json['imagePath'];

  Map<String, dynamic> toJson() =>
      {
        'diaper_endTime_class': diaper_endTime_class,
        'diaper_startTime_class': diaper_startTime_class,
        'dirty_class' : dirty_class,
        'dry_class': dry_class,
        'duration_class' : duration_class,
        'notes_class': notes_class,
        'timeStamp_class' : timeStamp_class,
        'wet_class' : wet_class,
        'imagePath' : imagePath
      };
}

class DiaperModel extends ChangeNotifier {
  /// Internal, private state of the list.
  final List<Diaper> items = [];

  Diaper? get(String? id)
  {
    if (id == null) return null;
    return items.firstWhere((diaper) => diaper.id == id);
  }

  //added this
  CollectionReference diapersCollection = FirebaseFirestore.instance.collection('diapers');

  //added this
  bool loading = false;

  //Normally a model would get from a database here, we are just hardcoding some data for this week
  DiaperModel()
  {
    fetch(); //this line won't compile until the next step

  }

  /*void add(Diaper item) {
    items.add(item);
    update();
  }*/

  Future add(Diaper item) async
  {

    loading = true;
    update();

    await diapersCollection.add(item.toJson());

    //refresh the db
    await fetch();
  }

  Future updateItem(String id, Diaper item) async
  {
    loading = true;
    update();

    await diapersCollection.doc(id).set(item.toJson());

    //refresh the db
    await fetch();
  }

  Future delete(String id) async
  {
    loading = true;
    update();

    await diapersCollection.doc(id).delete();

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
      var querySnapshot = await diapersCollection.orderBy("timeStamp_class", descending: true).get();

      //iterate over the diapers and add them to the list
      for (var doc in querySnapshot.docs) {
        var diaper = Diaper.fromJson(doc.data()! as Map<String, dynamic>, doc.id);//note not using the add(Diaper item) function, because we don't want to add them to the db
        items.add(diaper);
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
  Stream<List<Diaper>> itemsStream() {
    return diapersCollection.orderBy("timeStamp_class").snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Diaper.fromJson(doc.data()! as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  Stream<DiaperModel> get diaperModelStream {
    return diapersCollection.orderBy("timeStamp_class").snapshots().map((snapshot) {
      // clear the current list of items
      items.clear();

      // add all the new items
      items.addAll(snapshot.docs.map((doc) {
        return Diaper.fromJson(doc.data()! as Map<String, dynamic>, doc.id);
      }).toList());

      // return this instance of DiaperModel
      return this;
    });
  }

  Future<void> refreshDiapers() async {
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