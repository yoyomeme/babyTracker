import 'package:flutter/material.dart';
import 'feed.dart';
import 'package:provider/provider.dart';
import 'feedAdd_page.dart';
import 'feedEdit_page.dart';
import 'package:share_plus/share_plus.dart';
import 'package:circular_countdown_timer/circular_countdown_timer.dart';

class Feed_Page extends StatefulWidget {
  const Feed_Page({Key? key}) : super(key: key);

  @override
  _Feed_PageState createState() => _Feed_PageState();
}

class _Feed_PageState extends State<Feed_Page> {
  final TextEditingController _searchController = TextEditingController();
  final Map<String, bool> checkedFeeds = {};  // This will keep track of the checked status of each feed.

  String _searchQuery = ''; // Variable to keep track of the current search query

  bool _feedsEmpty = true;
  final bool _isTimerVisible = false;
  final bool _firstRun = true;
  final bool _dismissed = false;
  int newItemCount = 0;
  int getFeedsLength = 0;
  int _duration = 0;
  final int _ckduration = 0;
  final CountDownController _controller = CountDownController();

  @override
  void initState() {
    super.initState();
    //controller = AnimationController(vsync: this, duration: Duration(seconds: 10));
  }

  void onEnd() {
    print('onEnd');
  }

  @override
  void dispose() {
    //controller.dispose();
    super.dispose();

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 120.0),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search...',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;  // Update the search query when the search text changes
                      });
                    },
                  ),
                ),
                Consumer<FeedModel>(
                  builder: (context, feedModel, child) {
                    // Filter the list based on the search query
                    final List<Feed> filteredFeeds = feedModel.items.where((feed) {
                      return (_searchQuery.isEmpty ||
                          (feed.bottle_class == 1 && 'bottle'.contains(_searchQuery.toLowerCase())) ||
                          (feed.left_class == 1 && 'left'.contains(_searchQuery.toLowerCase())) ||
                          (feed.right_class == 1 && 'right'.contains(_searchQuery.toLowerCase())) ||
                          (feed.notes_class != null && feed.notes_class!.toLowerCase().contains(_searchQuery.toLowerCase())) ||
                          (feed.feedTime_class.toLowerCase().contains(_searchQuery.toLowerCase())));
                    }).toList();

                    //print('duration : ${_duration}, newitemCount : ${newItemCount}, filteredFeeds.length : ${filteredFeeds.length}, _isTimerVisible : ${_isTimerVisible}, getFeedsLength : ${getFeedsLength}');

/*
                    getFeedsLength = filteredFeeds.length;

                    if (_firstRun || !_dismissed) {

                        newItemCount = getFeedsLength;
                        _firstRun = false;
                        _dismissed = false;

                    }

                    else if (newItemCount < getFeedsLength) {

                        newItemCount = getFeedsLength;
                      setState(() {
                        _isTimerVisible = true;

                      });
                      _controller.start();
                      print("SOMETHING GOT HERE xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx");
                    }
*/

                    //SchedulerBinding.instance.addPostFrameCallback((_) {
                      // Update the logic here to start the timer if necessary

                    //});
                    /*
                    // If newItemCount doesn't equal to filteredFeeds.length, that means the new item(s) has been added
                    if (_firstRun || !_dismissed) {
                      newItemCount = filteredFeeds.length;
                      _firstRun = false;
                      _dismissed = true;
                    } else if (newItemCount < filteredFeeds.length || _controller.isStarted) {
                      newItemCount = filteredFeeds.length;
                      _isTimerVisible = true;
                      _controller.start();
                      //_controller.start();
                      print("SOMETHING GOT HERE");
                    }
                    */


                    return feedModel.loading
                        ? const SizedBox(
                      height: 10,
                      child: LinearProgressIndicator(),
                    )
                        :
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: feedModel.refreshFeeds,
                        child: ListView.builder(
                          itemCount: filteredFeeds.length,
                          itemBuilder: (_, index) {
                            if (index < filteredFeeds.length) {
                              //var sortedFeeds = List<Feed>.from(feedModel.items);
                              filteredFeeds.sort((b, a) => DateTime.parse(a.timeStamp_class).compareTo(DateTime.parse(b.timeStamp_class)));
                              var feed = filteredFeeds[index];
                              var image = getLeadingImage(feed);


                              _feedsEmpty = filteredFeeds.isEmpty;
                              // If the list is not empty, update _endTime and _duration with the latest feed's duration
                              if (!_feedsEmpty) {
                                // Assuming the duration_class is in minutes, convert it to milliseconds
                                // Parse duration_class string to Duration
                                List<String> parts = filteredFeeds[0].duration_class.split(':');
                                int hours = int.parse(parts[0]);
                                int minutes = int.parse(parts[1]);
                                Duration duration = Duration(hours: hours, minutes: minutes);
                                // Now convert it to milliseconds
                                _duration = duration.inSeconds;
                                //print('duration : ${_duration}, newitemCount : ${newItemCount}, filteredFeeds.length : ${filteredFeeds.length}, _isTimerVisible : ${_isTimerVisible}');
                              }
                              return Dismissible(
                                key: Key(feed.id),
                                confirmDismiss: (direction) {
                                  return showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: const Text('Confirm'),
                                        content: const Text('Are you sure you want to delete this item?'),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                        actions: <Widget>[
                                          TextButton(
                                            style: ButtonStyle(
                                              backgroundColor: MaterialStateProperty.all<Color>(Colors.lightGreen),
                                            ),
                                            child: const Text('No',style: TextStyle(
                                              color: Colors.white,
                                            ),),
                                            onPressed: () {
                                              Navigator.of(context).pop(false);
                                            },
                                          ),
                                          TextButton(
                                            style: ButtonStyle(
                                              backgroundColor: MaterialStateProperty.all<Color>(Colors.redAccent),
                                            ),
                                            child: const Text('Yes',style: TextStyle(
                                              color: Colors.white,
                                            ),),
                                            onPressed: () {
                                              Navigator.of(context).pop(true);
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                onDismissed: (direction) {
                                  feedModel.delete(feed.id);
                                  setState(() {
                                    _dismissed == true;
                                   });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("${feed.id} dismissed")),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    children: <Widget>[
                                      image,
                                      Expanded(
                                        child: ListTile(
                                          title: Text(feed.feedTime_class),
                                          subtitle: Text("${feed.duration_class} - ${feed.duration_class} Minutes"),
                                          onTap: () {
                                            Navigator.push(context, MaterialPageRoute(
                                                builder: (context) {
                                                  return FeedEdit_Page(feed: feed);
                                                }),
                                            ).then((_) => Provider.of<FeedModel>(context, listen: false).refreshFeeds());
                                          },
                                        ),
                                      ),
                                      // Add your note here
                                      Text('Notes: ${feed.notes_class}', style: const TextStyle(color: Colors.grey)),  // replace 'Your Note' with the actual note.
                                      Checkbox(
                                        value: checkedFeeds[feed.id] ?? false,
                                        onChanged: (value) {
                                          setState(() {
                                            checkedFeeds[feed.id] = value!;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                            return Container(); // return an empty container when index is not less than filteredFeeds.length
                          },
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Positioned(
            top: 50.0,
            left: MediaQuery.of(context).size.width / 2.2,
            //if feed list is empty, and timer is not visible, show "No Feeds" text
            child:

            //_duration == 0 ? Text("Timer : 0 ${_duration}") :
            CircularCountDownTimer(
              duration: _duration,
              initialDuration: 0,
              controller: _controller,
              width: 40,
              height: 40,
              ringColor: Colors.grey[300]!,
              ringGradient: null,
              fillColor: Colors.purpleAccent[100]!,
              fillGradient: null,
              backgroundColor: Colors.purple[500],
              backgroundGradient: null,
              strokeWidth: 8.0,
              strokeCap: StrokeCap.round,
              textStyle: const TextStyle(
                fontSize: 15.0,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textFormat: CountdownTextFormat.S,
              isReverse: true,
              isReverseAnimation: true,
              isTimerTextShown: true,
              autoStart: false,  // Updated here
              onStart: () {
                debugPrint('Countdown Started');
                print(_duration);
              },
              onComplete: () {
                debugPrint('Countdown Ended');
                print(_duration);
                //setState(() {
                  //_isTimerVisible = false;
                  //_controller.restart();
                //});
                // Add any additional action you want to perform when the countdown ends
              },
            ),
          ),
          Positioned(
              top: 26.0,
              left: MediaQuery.of(context).size.width / 2.5,
              child: Text("Item Count: ${Provider.of<FeedModel>(context).items.length}")
          ),
          Positioned(
            top: 26.0,
            left: 16.0,
            child: customIconButton(
              icon: Icons.add,
              color: Colors.white,
              size: 45.0,
              buttonColor: Colors.lightGreen,
              onPressed: () async {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const FeedAdd_Page()))
                    .then((_) => Provider.of<FeedModel>(context, listen: false).refreshFeeds());
                /*Navigator.push(context, MaterialPageRoute(
                    builder: (context) {
                      return FeedAdd_Page();
                    }),
                ).then((_) => Provider.of<FeedModel>(context, listen: false).refreshFeeds());*/
              },
            ),
          ),
          Positioned(
            top: 26.0,
            right: 16.0,
            child: customIconButton(
              icon: Icons.share,
              color: Colors.white,
              size: 45.0,
              onPressed: () {

                if (!checkedFeeds.containsValue(true)) {
                  showDialog(//https://stackoverflow.com/questions/53844052/how-to-make-an-alertdialog-in-flutter
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('No Items Selected'),
                        content: const Text('Please select at least one item to share.'),
                        shape:RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        actions: <Widget>[
                          TextButton(
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all<Color>(Colors.lightBlueAccent),
                            ),
                            child: const Text('OK',style: TextStyle(
                              color: Colors.white,
                            ),),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      );
                    },
                  );
                } else {
                  shareCheckedFeeds(context);
                  setState(() {
                    _controller.start();
                    //_duration = 90;
                    //_controller._duration = _duration;
                    print(_duration);
                  });

                }
              },
            ),
          ),
        ],
      ),
      //),
    //);
    );
  }

  Widget _button({required String title, VoidCallback? onPressed}) {
    return Expanded(
      child: ElevatedButton(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all(Colors.purple),
        ),
        onPressed: onPressed,
        child: Text(
          title,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }


// custom circular button
  Widget customIconButton({
    required IconData icon,
    required Color color,
    required double size,
    required VoidCallback onPressed,
    Color buttonColor = Colors.blue,
  }) {
    return Container(
      height: 75.0,
      width: 75.0,
      decoration: BoxDecoration(
        color: buttonColor,
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            child: Center(
              child: Icon(icon, color: color, size: size),
            ),
          ),
        ),
      ),
    );
  }

  void shareCheckedFeeds(BuildContext context) {
    final feedModel = Provider.of<FeedModel>(context, listen: false);
    String shareText = '';
    for (var feed in feedModel.items) {
      if (checkedFeeds[feed.id] ?? false) {
        shareText += '${feed.feedTime_class} (${feed.duration_class.toString()} - ${feed.duration_class.toString()} Minutes)\n';
      }
    }
    print("Share text: $shareText");
    Share.share(shareText);
  }

  Image getLeadingImage(Feed feed) {
    String assetName;
    if (feed.bottle_class == 1) {
      assetName = 'lib/images/bottleimage.png';
    } else if (feed.left_class == 1) {
      assetName = 'lib/images/left.png';
    } else if (feed.right_class == 1) {
      assetName = 'lib/images/right.png';
    } else {
      assetName = '';  // Default image in case none of the conditions are met
    }
    return Image.asset(
      assetName,
      width: 55.0,  // Set your desired width
      height: 55.0,  // Set your desired height
      fit: BoxFit.cover,
    );
  }


}

