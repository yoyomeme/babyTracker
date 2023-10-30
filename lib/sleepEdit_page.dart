import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:outlined_text/outlined_text.dart';
import 'package:duration_picker/duration_picker.dart';
import 'package:intl/intl.dart';
import 'sleep.dart';

class SleepEdit_Page extends StatefulWidget {
  final Sleep sleep;
  const SleepEdit_Page({Key? key, required this.sleep}) : super(key: key);

  @override
  _SleepEdit_PageState createState() => _SleepEdit_PageState();
}


class _SleepEdit_PageState extends State<SleepEdit_Page> {
  TimeOfDay _time = TimeOfDay.now(); // initialize with a default time
  Duration _duration = Duration.zero;

  final bool _isLeftImageClicked = false;
  final bool _isBottleImageClicked = false;
  final bool _isRightImageClicked = false;

  String backgroundImagePath = "lib/images/babysun.png";

  var myTextController = TextEditingController();

  //chatgpt solve the am to pm bug for me
  String _calculateEndTime(TimeOfDay startTime, Duration duration) {
    DateTime now = DateTime.now();
    DateTime initial = DateTime(now.year, now.month, now.day, startTime.hour, startTime.minute);
    DateTime endTime = initial.add(duration);
    return DateFormat('hh:mm a').format(endTime);
  }


  @override
  void initState() {
    super.initState();

    // Assuming Sleep has these properties. Adjust according to your Sleep class.
    //_isLeftImageClicked = widget.sleep.left_class == 1;
    //_isBottleImageClicked = widget.sleep.bottle_class == 1;
    //_isRightImageClicked = widget.sleep.right_class == 1;

    // Parse the duration string into a Duration object.
    List<String> parts = widget.sleep.duration_class!.split(":");
    int hours = int.parse(parts[0]);
    int minutes = int.parse(parts[1]);

    _duration = Duration(hours: hours, minutes: minutes);


    // Parse the sleep time string into a TimeOfDay object.
    // You might need to adjust this line depending on the format of sleepTime_class.
    final format = DateFormat("h:mm a"); // Format for time like '3:08 PM'
    final date = format.parse(widget.sleep.sleep_startTime_class);
    _time = TimeOfDay(hour: date.hour, minute: date.minute);

    // Set the notes
    myTextController.text = widget.sleep.notes_class!;
  }


  @override
  Widget build(BuildContext context) {
    // Check if the time is within 6:00 AM - 6:00 PM
    if ((_time.hour >= 6 && _time.hour < 18) || (_time.hour == 18 && _time.minute == 0)) {
      backgroundImagePath = "lib/images/babysun.png";
    } else {
      backgroundImagePath = "lib/images/babynight.png";
    }

    return Scaffold(
        appBar: AppBar(title: Text('Edit Sleep : ${widget.sleep.id}')),
        body: Stack(
          children: <Widget>[
            Positioned.fill(
            child: Opacity(
              opacity: 0.75,
              child: Image.asset(
                backgroundImagePath,
                fit: BoxFit.contain,
              ),
            ),
          ),
          SingleChildScrollView(
            // Wrap body in SingleChildScrollView was told by chatgpt so that user will be able to view the notes while entering the keyboard
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
                  Padding( // Add padding widget
                    padding: const EdgeInsets.only(top: 20), // Adjust as needed
                    child:
                    DurationPicker(
                      duration: _duration,
                      baseUnit: BaseUnit.minute,
                      onChange: (val) {
                        setState(() => _duration = val);
                      },
                      snapToMins: 1.0,
                    ),
                  ),
                  Padding( // Add padding widget
                    padding: const EdgeInsets.only(top: 20), // Adjust as needed
                    child: Text('End Time: ${_calculateEndTime(_time, _duration)}',
                        style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 26.0, // make font size larger
                            decoration: TextDecoration.none
                        )  // adjust the font size as needed
                    ),
                  ),
                  Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 143),
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
                          padding: const EdgeInsets.fromLTRB(20.0, 243.0, 10.0, 0.0),
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
                          padding: const EdgeInsets.fromLTRB(10.0, 243.0, 20.0, 0.0),
                          child: ElevatedButton(
                            onPressed: () async {

                              DateTime now = DateTime.now();
                              String formattedDate = DateFormat('yyyy-MM-ddTHH:mm:ss').format(now);
                              DateTime sleepStartTime = DateTime(now.year, now.month, now.day, _time.hour, _time.minute);
                              DateTime sleepEndTime = sleepStartTime.add(_duration);

                              // Calculate hours and minutes
                              int totalMinutes = _duration.inMinutes;
                              int hours = totalMinutes ~/ 60; // Use integer division to get the hours
                              int minutes = totalMinutes % 60; // Use modulus to get the remaining minutes

                              // Pad the hours and minutes with leading zeros if necessary and concatenate
                              String durationString = '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';


                              FirebaseFirestore.instance.collection('sleeps').doc(widget.sleep.id).update({
                                'sleep_startTime_class': DateFormat('hh:mm a').format(sleepStartTime),
                                'duration_class': durationString,
                                'sleep_endTime_class': DateFormat('hh:mm a').format(sleepEndTime),
                                'notes_class': myTextController.text,
                                'timeStamp_class': formattedDate = widget.sleep.timeStamp_class,
                              }).then((value) {
                                print("sleep successfully updated");
                                Navigator.pop(context);
                              }).catchError((error) {
                                print("Failed to update sleep: $error");
                                Navigator.pop(context);
                              });


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
          ),
        ],
      ),
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
