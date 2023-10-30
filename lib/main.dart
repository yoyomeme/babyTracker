import 'dart:async';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:week13_2023/sleep.dart';
import 'package:week13_2023/sleepScatterPlot.dart';
import 'allin.dart';
import 'diaper.dart';
import 'diaperScatterPlot.dart';
import 'feedScatterPlot.dart';
import 'movie.dart';
import 'feed.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:fl_chart/fl_chart.dart';




Future main() async {
  WidgetsFlutterBinding.ensureInitialized();

  var app = await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print("\n\nConnected to Firebase App ${app.options.projectId}\n\n");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget
{
  const MyApp({Key? key}) : super(key: key);



  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => MovieModel()),
        ChangeNotifierProvider(create: (context) => FeedModel()),
        ChangeNotifierProvider(create: (context) => SleepModel()),
        ChangeNotifierProvider(create: (context) => DiaperModel()),
      ],
      child: MaterialApp(
          title: 'Baby Tracker',
          theme: ThemeData(
            primarySwatch: Colors.blue,
          ),
          home: const MyHomePage(title: 'Baby Tracker')
      ),
    );
  }
}

class MyHomePage extends StatefulWidget
{
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

enum SelectedPlot {feed, sleep, diaper}
SelectedPlot selectedPlot = SelectedPlot.feed;

class _MyHomePageState extends State<MyHomePage>
{
  late StreamSubscription _feedStreamSubscription;
  bool isFeedCardClicked = true;
  bool isSleepCardClicked = false;
  bool isDiaperCardClicked = false;

  @override
  void initState() {
    super.initState();
    var feedModel = Provider.of<FeedModel>(context, listen: false);
    _feedStreamSubscription = feedModel.itemsStream().listen((_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    super.dispose();
    _feedStreamSubscription.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer4<MovieModel, FeedModel, SleepModel, DiaperModel>(
      builder: (_, movieModel, feedModel, sleepModel, diaperModel, __) =>
          buildScaffold(context, movieModel, feedModel, sleepModel, diaperModel),
    );
  }

  List<BarChartGroupData> sampleData(FeedModel feedModel) {
    // feeds list of FeedModel data.
    var feeds = feedModel.items;



    // Create a map to store the count of entries for each minute.
    Map<int, int> data = {};

    for (Feed feed in feeds) {
      // Convert the feedTime_class to DateTime (assuming it's a string representing a DateTime).
      var time = DateTime.parse(feed.timeStamp_class);
      int minute = time.minute;
      if (data.containsKey(minute)) {
        data[minute] = (data[minute] ?? 0) + 1;
      } else {
        data[minute] = 1;
      }
    }

    // Generate the BarChartGroupData list from the collected data.
    return data.entries.map((entry) {
      return BarChartGroupData(
        x: entry.key,  // minutes
        barRods: [
          BarChartRodData(
            y: entry.value.toDouble(),  // count of entries
            colors: [Colors.blue],
          ),
        ],
      );
    }).toList();
  }


  Scaffold buildScaffold(BuildContext context, MovieModel movieModel, FeedModel feedModel, SleepModel sleepModel, DiaperModel diaperModel) {


    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      //from chatgpt by asking pulsing button
      floatingActionButton: AvatarGlow(
        startDelay: const Duration(milliseconds: 1000),
        glowColor: Colors.green,
        endRadius: 60.0,
        duration: const Duration(milliseconds: 2000),
        repeat: true,
        showTwoGlows: true,
        repeatPauseDuration: const Duration(milliseconds: 100),
        shape: BoxShape.circle,
        animate: true,
        curve: Curves.fastOutSlowIn,
        child: RawMaterialButton(
          onPressed: () {
            int pageIndex;
            if (isFeedCardClicked) {
              pageIndex = 0;
            } else if (isSleepCardClicked) {
              pageIndex = 1;
            } else if (isDiaperCardClicked) {
              pageIndex = 2;
            } else {
              pageIndex = 0; // Default pageIndex value
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Allin(pageIndex: pageIndex),
              ),
            );

            //showDialog(context: context, builder: (context) {
              //return const Allin();
            //});
          },
          elevation: 0.0,
          fillColor: Colors.white,
          padding: const EdgeInsets.all(5.0),
          shape: const CircleBorder(),
          constraints: const BoxConstraints.tightFor(
            width: 70.0,
            height: 70.0,
          ),
          child: CircleAvatar(
            backgroundColor: Colors.lightBlue[100],
            radius: 50.0,
            backgroundImage: AssetImage(isFeedCardClicked ? 'lib/images/bottleimage.png' :
            isSleepCardClicked ? 'lib/images/babynight.png' :
            isDiaperCardClicked ? 'lib/images/checkpoop.png' : 'lib/images/bottleimage.png'),
          ),
        ),
      ),

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(40, 40, 60, 40),
                child: selectedPlot == SelectedPlot.feed//https://play.google.com/store/apps/details?id=com.nighp.babytracker_android&hl=en_AU&gl=US
                    ? FeedScatterPlot(feedModel)
                    : selectedPlot == SelectedPlot.sleep
                    ? SleepScatterPlot(sleepModel)
                    : DiaperScatterPlot(diaperModel),
                /*
                    selectedPlot == SelectedPlot.feed
                    ? FeedScatterPlot(feedModel)
                    : selectedPlot == SelectedPlot.sleep
                    ? SleepScatterPlot(sleepModel)
                    : DiaperScatterPlot(diaperModel),*/
              ),
            ),
            movieModel.loading
                ? const SizedBox(
              height: 10, // adjust the height
              child: LinearProgressIndicator(),
            )
            :
            Expanded(
              child: Column(
                children: [
                  GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedPlot = SelectedPlot.feed;
                      isFeedCardClicked = true;
                      isSleepCardClicked = false;
                      isDiaperCardClicked = false;
                      print("Feed plot");
                    });
                  },
                child: getAnimatedColorChangeContainer(
                  isCardClicked: isFeedCardClicked,
                    child: Column(
                      children: <Widget>[
                        ListTile(
                          leading: Builder(
                            builder: (BuildContext context) {
                              String assetName;
                              if (feedModel.items.isNotEmpty) {
                                var feed = feedModel.items.first;
                                if (feed.bottle_class == 1) {
                                  assetName = 'lib/images/bottleimage.png';
                                } else if (feed.left_class == 1) {
                                  assetName = 'lib/images/left.png';
                                } else if (feed.right_class == 1) {
                                  assetName = 'lib/images/right.png';
                                } else {
                                  assetName = 'lib/images/graybottleimage.png';  // Default image in case none of the conditions are met
                                }
                              } else {
                                assetName = 'lib/images/graybottleimage.png';  // Default image if there is no feed data
                              }
                              return Image.asset(assetName);
                            },
                          ),
                          title: const Text('Latest Feed'),
                          subtitle: Text(feedModel.items.isNotEmpty ? 'Time: ${feedModel.items.first.feedTime_class} Duration: ${feedModel.items.first.duration_class}' : 'No feed data'),
                        ),
                      ],
                    ),
                  ),
              ),
    GestureDetector(
    onTap: () {
    setState(() {
    selectedPlot = SelectedPlot.sleep;
    isFeedCardClicked = false;
    isSleepCardClicked = true;
    isDiaperCardClicked = false;
    print("Sleep plot");
    });
    },
    child: getAnimatedColorChangeContainer(
      isCardClicked: isSleepCardClicked,
                    child: Column(
                      children: <Widget>[
                        ListTile(
                          leading: Builder(builder: (BuildContext context) {
                            if (sleepModel.items.isNotEmpty) {
                              // parse sleep_startTime_class back into a TimeOfDay object
                              final timeParts = sleepModel.items.first.sleep_startTime_class.split(RegExp(r'[: ]')); //split by colon and space
                              final hours = int.parse(timeParts[0]);
                              final minutes = int.parse(timeParts[1]);
                              final period = timeParts[2]; // AM or PM

                              int hourIn24 = period.toLowerCase() == "am" ? hours : hours + 12;
                              if (hourIn24 == 24) hourIn24 = 0; // if it's 12AM, convert to 0
                              if (hourIn24 == 12) hourIn24 = 12; // if it's 12PM, convert to 12

                              final startTime = TimeOfDay(hour: hourIn24, minute: minutes);

                              // define morning and evening start times
                              const morningStart = TimeOfDay(hour: 6, minute: 0);
                              const eveningStart = TimeOfDay(hour: 18, minute: 0);

                              // check if the sleep start time is within the morning or evening interval
                              if ((startTime.hour >= morningStart.hour && startTime.minute >= morningStart.minute) &&
                                  (startTime.hour < eveningStart.hour || (startTime.hour == eveningStart.hour && startTime.minute < eveningStart.minute))) {
                                return Image.asset('lib/images/babysun.png');
                              } else {
                                return Image.asset('lib/images/babynight.png');
                              }
                            } else {
                              return Image.asset('lib/images/graybabynight.png');
                            }
                          }),
                          title: const Text('Latest Sleep'),
                          subtitle: Text(sleepModel.items.isNotEmpty ? 'Time: ${sleepModel.items.first.sleep_startTime_class} Duration: ${sleepModel.items.first.duration_class}' : 'No sleep data'),
                        ),
                      ],
                    ),
                  ),
    ),
    GestureDetector(
    onTap: () {
    setState(() {
    selectedPlot = SelectedPlot.diaper;
    isFeedCardClicked = false;
    isSleepCardClicked = false;
    isDiaperCardClicked = true;
    print("Diaper plot");
    });
    },
    child:  getAnimatedColorChangeContainer(
      isCardClicked: isDiaperCardClicked,
                    child: Column(
                      children: <Widget>[
                        ListTile(
                          leading: Builder(builder: (BuildContext context) {
                            if (diaperModel.items.isNotEmpty) {
                              final diaper = diaperModel.items.first;
                              String assetName;
                              if (diaper.dirty_class == 1 && diaper.dry_class == 1) {
                                assetName = 'lib/images/drypoop.png';
                              } else if (diaper.dirty_class == 1 && diaper.wet_class == 1) {
                                assetName = 'lib/images/wetpoop.png';
                              } else if (diaper.dirty_class == 1) {
                                assetName = 'lib/images/checkpoop.png';
                              } else if (diaper.dry_class == 1) {
                                assetName = 'lib/images/dry.png';
                              } else if (diaper.wet_class == 1) {
                                assetName = 'lib/images/wet.png';
                              } else {
                                assetName = 'lib/images/poop.png';  // Default image in case none of the conditions are met
                              }
                              return SizedBox(
                                width: 60,
                                child: Image.asset(assetName),
                              );
                            } else {
                              return SizedBox(
                                width: 60,
                                child: Image.asset('lib/images/poop.png'),
                              );
                            }
                          }),
                          title: const Text('Latest Diaper Change'),
                          subtitle: Text(diaperModel.items.isNotEmpty ? 'Time: ${diaperModel.items.first.diaper_startTime_class} Duration: ${diaperModel.items.first.duration_class}' : 'No diaper change data'),

                        ),
                      ],
                    ),
                  ),
    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  //implemented by chatgpt
  Widget getAnimatedColorChangeContainer({required bool isCardClicked, required Widget child, Duration duration = const Duration(milliseconds: 500)}) {
    return AnimatedContainer(
      duration: duration,
      color: isCardClicked ? Colors.lightBlue[300] : Colors.white,
      child: Card(color: isCardClicked ? Colors.lightBlue[50] : Colors.white,child: child),
    );
  }


  Future<void> refreshMovies() async {
    // Add your refresh code here.
    // For example, you might make an API call to get updated data.
    // For now we'll just wait for a second.
    Provider.of<MovieModel>(context, listen: false).fetch();
    //await Future.delayed(Duration(seconds: 1));
  }
  Future<void> refreshFeeds() async {
    // Add your refresh code here.
    // For example, you might make an API call to get updated data.
    // For now we'll just wait for a second.
    Provider.of<FeedModel>(context, listen: false).fetch();
  }

}

//A little helper widget to avoid runtime errors -- we can't just display a Text() by itself if not inside a MaterialApp, so this workaround does the job
class FullScreenText extends StatelessWidget {
  final String text;

  const FullScreenText({Key? key, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(textDirection:TextDirection.ltr, child: Column(children: [ Expanded(child: Center(child: Text(text))) ]));
  }
}
