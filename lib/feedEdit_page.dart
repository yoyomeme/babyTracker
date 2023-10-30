import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:outlined_text/outlined_text.dart';
import 'package:duration_picker/duration_picker.dart';
import 'package:intl/intl.dart';
import 'feed.dart';

class FeedEdit_Page extends StatefulWidget {
  final Feed feed;
  const FeedEdit_Page({Key? key, required this.feed}) : super(key: key);

  @override
  _FeedEdit_PageState createState() => _FeedEdit_PageState();
}


class _FeedEdit_PageState extends State<FeedEdit_Page> {
  TimeOfDay _time = TimeOfDay.now(); // initialize with a default time
  Duration _duration = Duration.zero;

  bool _isLeftImageClicked = false;
  bool _isBottleImageClicked = false;
  bool _isRightImageClicked = false;

  var myTextController = TextEditingController();



  @override
  void initState() {
    super.initState();

    // Assuming Feed has these properties. Adjust according to your Feed class.
    _isLeftImageClicked = widget.feed.left_class == 1;
    _isBottleImageClicked = widget.feed.bottle_class == 1;
    _isRightImageClicked = widget.feed.right_class == 1;

    // Parse the duration string into a Duration object.
    List<String> parts = widget.feed.duration_class.split(":");
    int hours = int.parse(parts[0]);
    int minutes = int.parse(parts[1]);

    _duration = Duration(hours: hours, minutes: minutes);


    // Parse the feed time string into a TimeOfDay object.
    // You might need to adjust this line depending on the format of feedTime_class.
    final format = DateFormat("h:mm a"); // Format for time like '3:08 PM'
    final date = format.parse(widget.feed.feedTime_class);
    _time = TimeOfDay(hour: date.hour, minute: date.minute);

    // Set the notes
    myTextController.text = widget.feed.notes_class!;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Edit Feed : ${widget.feed.id}')),
        body: SingleChildScrollView(
          // Wrap body in SingleChildScrollView told by chatgpt so that user will be able to view the notes while entering the keyboard
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Padding( // Wrap GestureDetector with a Padding widget
                    padding: const EdgeInsets.only(top: 80), // Adjust as needed
                    child: GestureDetector(
                        onTap: _selectTime,
                        child: OutlinedText(
                          text: Text(_time.format(context),
                              style: const TextStyle(
                                  color: Colors.blue,
                                  fontSize: 46.0, // make font size larger
                                  decoration: TextDecoration.none
                              )
                          ),
                          strokes: [
                            OutlinedTextStroke(
                                color: Colors.black,
                                width: 1
                            ),
                          ],
                        )
                    )
                ),

                //from https://pub.dev/packages/duration_picker/example
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: DurationPicker(
                    duration: _duration,
                    baseUnit: BaseUnit.minute,
                    onChange: (val) {
                      setState(() => _duration = val);
                    },
                    snapToMins: 5.0,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {

                  },
                  child: const Text('Set Timer'),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isLeftImageClicked = !_isLeftImageClicked;
                            _isBottleImageClicked = false;
                            _isRightImageClicked = false;

                          });
                        },
                        child: Image.asset(
                          _isLeftImageClicked ? 'lib/images/left.png' : 'lib/images/grayleft.png',
                          height: 100,
                          width: 100,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isBottleImageClicked = !_isBottleImageClicked;
                            _isLeftImageClicked = false;
                            _isRightImageClicked = false;
                          });
                        },
                        child: Image.asset(
                          _isBottleImageClicked ? 'lib/images/bottleimage.png' : 'lib/images/graybottleimage.png',
                          height: 100,
                          width: 100,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isRightImageClicked = !_isRightImageClicked;
                            _isBottleImageClicked = false;
                            _isLeftImageClicked = false;
                          });
                        },
                        child: Image.asset(
                          _isRightImageClicked ? 'lib/images/right.png' : 'lib/images/grayright.png',
                          height: 100,
                          width: 100,
                        ),
                      ),
                    ],
                  ),
                ),
                Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: TextField(
                        controller: myTextController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Enter your notes here ~',
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20.0, 120.0, 10.0, 0.0),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[800],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            minimumSize: const Size(100, 50),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10.0, 120.0, 20.0, 0.0),
                        child: ElevatedButton(
                          onPressed: () {
                            if (!_isLeftImageClicked && !_isBottleImageClicked && !_isRightImageClicked) {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: const Text('Alert'),
                                    content: const Text('Please select a feed type'),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            } else {
                              DateTime now = DateTime.now();
                              String formattedDate = DateFormat('yyyy-MM-ddTHH:mm:ss').format(now);

                              // Calculate hours and minutes
                              int totalMinutes = _duration.inMinutes;
                              int hours = totalMinutes ~/ 60; // Use integer division to get the hours
                              int minutes = totalMinutes % 60; // Use modulus to get the remaining minutes

                              // Pad the hours and minutes with leading zeros if necessary and concatenate
                              String durationString = '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';



                              FirebaseFirestore.instance.collection('feeds').doc(widget.feed.id).update({
                                'feedTime_class': _time.format(context),
                                //'duration_class': _duration.inMinutes.toString(),
                                'duration_class': durationString,
                                'left_class': _isLeftImageClicked ? 1 : 0,
                                'bottle_class': _isBottleImageClicked ? 1 : 0,
                                'right_class': _isRightImageClicked ? 1 : 0,
                                'notes_class': myTextController.text,
                                'timeStamp_class': formattedDate = widget.feed.timeStamp_class,
                              }).then((value) {
                                print("Feed successfully updated");
                              }).catchError((error) {
                                print("Failed to update feed: $error");
                              });
                              Navigator.pop(context);
                              /*
                          showDialog(context: context, builder: (context) {
                            //return const MovieDetails();
                            return Allin();
                          }).then((_) {
                            // Refresh the list when you pop back to this page
                            Provider.of<FeedModel>(context, listen: false).refreshFeeds();
                          });*/
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            minimumSize: const Size(100, 50),
                          ),
                          child: const Text('Save'),
                        ),
                      ),
                    ),
                  ],
                ),

              ],
            ),
          ),
        )
    );
  }

  _selectTime() async {
    final TimeOfDay? newTime = await showTimePicker(
      context: context,
      initialTime: _time,
    );
    if (newTime != null) {
      setState(() {
        _time = newTime;
      });
    }
  }
}
