import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:outlined_text/outlined_text.dart';
import 'package:duration_picker/duration_picker.dart';
import 'package:intl/intl.dart';


class SleepAdd_Page extends StatefulWidget {
  const SleepAdd_Page({Key? key}) : super(key: key);

  @override
  _SleepAdd_PageState createState() => _SleepAdd_PageState();
}

class _SleepAdd_PageState extends State<SleepAdd_Page> {
  TimeOfDay _time = TimeOfDay.now(); // initialize with a default time
  Duration _duration = Duration.zero;

  final bool _isLeftImageClicked = false;
  final bool _isBottleImageClicked = false;
  final bool _isRightImageClicked = false;

  String backgroundImagePath = "lib/images/babysun.png";

  var myTextController = TextEditingController();

  String _calculateEndTime(TimeOfDay startTime, Duration duration) {
    DateTime now = DateTime.now();
    DateTime initial = DateTime(now.year, now.month, now.day, startTime.hour, startTime.minute);
    DateTime endTime = initial.add(duration);
    return DateFormat('hh:mm a').format(endTime);
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
      appBar: AppBar(title: const Text('Sleep Entry')),
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

                              TimeOfDay sleepEndTimeOfDay = TimeOfDay.fromDateTime(sleepEndTime);

                              // Calculate hours and minutes
                              int totalMinutes = _duration.inMinutes;
                              int hours = totalMinutes ~/ 60; // Use integer division to get the hours
                              int minutes = totalMinutes % 60; // Use modulus to get the remaining minutes

                              // Pad the hours and minutes with leading zeros if necessary and concatenate
                              String durationString = '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';

                              FirebaseFirestore.instance.collection('sleeps').add({
                                'sleep_startTime_class': DateFormat('hh:mm a').format(sleepStartTime),
                                'duration_class': durationString,
                                'sleep_endTime_class': DateFormat('hh:mm a').format(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, sleepEndTimeOfDay.hour, sleepEndTimeOfDay.minute)),
                                'notes_class': myTextController.text,
                                'timeStamp_class': formattedDate,
                              }).then((value) {
                                print("sleep successfully added");
                                Navigator.pop(context);
                              }).catchError((error) {
                                print("Failed to add sleep: $error");
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
