import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class Movie
{
  late String id; //(1)
  String title;
  int year;
  num duration;
  String? image;

  Movie({required this.title, required this.year, required this.duration, this.image});

  //(2)
  Movie.fromJson(Map<String, dynamic> json, this.id)
      :
        title = json['title'],
        year = json['year'],
        duration = json['duration'];

  Map<String, dynamic> toJson() =>
      {
        'title': title,
        'year': year,
        'duration' : duration
      };
}

class MovieModel extends ChangeNotifier {
  final List<Movie> items = [];

  Movie? get(String? id)
  {
    if (id == null) return null;
    return items.firstWhere((movie) => movie.id == id);
  }

  CollectionReference moviesCollection = FirebaseFirestore.instance.collection('movies');

  bool loading = false;

  MovieModel()
  {
    fetch();

  }

  /*void add(Movie item) {
    items.add(item);
    update();
  }*/

  Future add(Movie item) async
  {

    loading = true;
    update();

    await moviesCollection.add(item.toJson());

    //refresh the db
    await fetch();
  }

  Future updateItem(String id, Movie item) async
  {
    loading = true;
    update();

    await moviesCollection.doc(id).set(item.toJson());

    //refresh the db
    await fetch();
  }

  Future delete(String id) async
  {
    loading = true;
    update();

    await moviesCollection.doc(id).delete();

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

    //get all movies
    var querySnapshot = await moviesCollection.orderBy("title").get();

    //iterate over the movies and add them to the list
    for (var doc in querySnapshot.docs) {
      //note not using the add(Movie item) function, because we don't want to add them to the db
      var movie = Movie.fromJson(doc.data()! as Map<String, dynamic>, doc.id);
      items.add(movie);
    }

    //put this line in to artificially increase the load time, so we can see the loading indicator (when we add it in a few steps time)
    //comment this out when the delay becomes annoying
    //await Future.delayed(const Duration(seconds: 2));

    //we're done, no longer loading
    loading = false;
    update();
  }
}