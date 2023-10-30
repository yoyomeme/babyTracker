import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:outlined_text/outlined_text.dart';
import 'package:duration_picker/duration_picker.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'diaper.dart';
import 'package:path_provider/path_provider.dart';

class DiaperAdd_Page extends StatefulWidget {
  const DiaperAdd_Page({Key? key}) : super(key: key);

  @override
  _DiaperAdd_PageState createState() => _DiaperAdd_PageState();
}

class _DiaperAdd_PageState extends State<DiaperAdd_Page> {
  TimeOfDay _time = TimeOfDay.now(); // initialize with a default time
  Duration _duration = Duration.zero;

  bool _isDirtyClicked = false;
  bool _isDryClicked = false;
  bool _isWetClicked = false;

  var myTextController = TextEditingController();

  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();

  String? _localImageFilePath;
  String? _imageUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Diaper Entry')),
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
                  padding: const EdgeInsets.only(top: 20), // Adjust as needed
                  child: DurationPicker(
                    duration: _duration,
                    baseUnit: BaseUnit.minute,
                    onChange: (val) {
                      setState(() => _duration = val);
                    },
                    snapToMins: 5.0,
                  ),
                ),
                if (_imageUrl != null)
                  SizedBox(
                  width: 200.0, // Set the width
                  height: 200.0, // Set the height
                  child: Image.network(
                    _imageUrl!,
                    fit: BoxFit.cover)),
                ElevatedButton(
                  onPressed: _pickImageFromGallery,
                  child: const Text('Pick an Image from Gallery'),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isDirtyClicked = !_isDirtyClicked;
                          });
                        },
                        child: Image.asset(
                          _isDirtyClicked ? 'lib/images/checkpoop.png' : 'lib/images/poop.png',
                          height: 80,
                          width: 80,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isDryClicked = !_isDryClicked;
                            if (_isDryClicked && _isWetClicked) { // Can't be dry and wet at the same time
                              _isWetClicked = false;
                            }
                          });
                        },
                        child: Image.asset(
                          _isDryClicked ? 'lib/images/dry.png' : 'lib/images/uncheckdry.png',
                          height: 70,
                          width: 70,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isWetClicked = !_isWetClicked;
                            if (_isDryClicked && _isWetClicked) { // Can't be dry and wet at the same time
                              _isDryClicked = false;
                            }
                          });
                        },
                        child: Image.asset(
                          _isWetClicked ? 'lib/images/wet.png' : 'lib/images/uncheckwet.png',
                          height: 70,
                          width: 70,
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
                          onPressed: () async {
                            if (!_isDirtyClicked && !_isDryClicked && !_isWetClicked) {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: const Text('Alert'),
                                    content: const Text('Please select a diaper type'),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
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

                              var diaper = Diaper(diaper_startTime_class:_time.format(context), diaper_endTime_class:_time.format(context), duration_class: _duration.inMinutes.toString(), dirty_class: _isDirtyClicked ? 1 : 0, dry_class: _isDryClicked ? 1 : 0, wet_class: _isWetClicked ? 1 : 0, notes_class: myTextController.text, timeStamp_class: formattedDate);
/*
'diaper_endTime_class': diaper_endTime_class,
        'diaper_startTime_class': diaper_startTime_class,
        'dirty_class' : dirty_class,
        'dry_class': dry_class,
        'duration_class' : duration_class,
        'notes_class': notes_class,
        'timeStamp_class' : timeStamp_class,
        'wet_class' : wet_class
 */
                              //await Provider.of<DiaperModel>(context, listen:false).add(diaper);
                              //Provider.of<DiaperModel>(context, listen: false).addItem(diaper);

                              //Navigator.pop(context);
                              DateTime diaperStartTime = DateTime(now.year, now.month, now.day, _time.hour, _time.minute);
                              DateTime diaperEndTime = diaperStartTime.add(_duration);

                              TimeOfDay diaperEndTimeOfDay = TimeOfDay.fromDateTime(diaperEndTime);


                              // Calculate hours and minutes
                              int totalMinutes = _duration.inMinutes;
                              int hours = totalMinutes ~/ 60; // Use integer division to get the hours
                              int minutes = totalMinutes % 60; // Use modulus to get the remaining minutes

                              // Pad the hours and minutes with leading zeros if necessary and concatenate
                              String durationString = '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';


                              FirebaseFirestore.instance.collection('diapers').add({
                                'diaper_startTime_class': _time.format(context),
                                //'duration_class': _duration.inMinutes.toString(),
                                'duration_class': durationString,
                                'diaper_endTime_class': DateFormat('hh:mm a').format(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, diaperEndTimeOfDay.hour, diaperEndTimeOfDay.minute)),

                                'dirty_class': _isDirtyClicked ? 1 : 0,
                                'dry_class': _isDryClicked ? 1 : 0,
                                'wet_class': _isWetClicked ? 1 : 0,
                                'notes_class': myTextController.text,
                                'timeStamp_class': formattedDate,
                                'imageUrl': _localImageFilePath ?? "",
                              }).then((value) {
                                print("diaper successfully added");
                                Navigator.pop(context);
                              }).catchError((error) {
                                print("Failed to add diaper: $error");
                                Navigator.pop(context);
                              });

                              /*
                          showDialog(context: context, builder: (context) {
                            //return const MovieDetails();
                            return Allin();
                          }).then((_) {
                            // Refresh the list when you pop back to this page
                            Provider.of<DiaperModel>(context, listen: false).refreshDiapers();
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


  void _pickImageFromGallery() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.png'; // unique name based on the timestamp
        final localFilePath = '${appDir.path}/$fileName';
        final localImageFile = await File(pickedFile.path).copy(localFilePath);

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return const AlertDialog(
              title: Text('Processing'),
              content: Text('Please wait patiently while the image is being processed.'),
            );
          },
        );

        // upload image to Firebase Storage
        final storageRef = FirebaseStorage.instance.ref().child('images/$fileName');
        await storageRef.putFile(localImageFile);

        // get download URL and store it in Firestore
        final downloadUrl = await storageRef.getDownloadURL();

        setState(() {
          _imageFile = pickedFile;
          _localImageFilePath = downloadUrl; // store local file path in state
          //_imageUrl = downloadUrl;
        });


/*
        // Upload the image to Firebase Storage
        FirebaseStorage storage = FirebaseStorage.instance;
        Reference ref = storage.ref().child('diaper_images/$fileName');
        UploadTask uploadTask = ref.putFile(File(pickedFile.path));
        await uploadTask.whenComplete(() async {
          // Get download URL and save to Firestore
          String downloadURL = await ref.getDownloadURL();
          setState(() {
            _localImageFilePath = downloadURL; // store the downloadURL in state
          });
        });*/
      }
    } catch (e) {
      print("Error picking image: $e");
    }
  }



}
