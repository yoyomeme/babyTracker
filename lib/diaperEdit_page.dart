import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:outlined_text/outlined_text.dart';
import 'package:duration_picker/duration_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'diaper.dart';
import 'dart:io';

class DiaperEdit_Page extends StatefulWidget {
  final Diaper diaper;
  const DiaperEdit_Page({Key? key, required this.diaper}) : super(key: key);

  @override
  _DiaperEdit_PageState createState() => _DiaperEdit_PageState();
}


class _DiaperEdit_PageState extends State<DiaperEdit_Page> {
  TimeOfDay _time = TimeOfDay.now(); // initialize with a default time
  Duration _duration = Duration.zero;

  bool _isDirtyClicked = false;
  bool _isDryClicked = false;
  bool _isWetClicked = false;

  var myTextController = TextEditingController();

  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();

  late String _localImageFilePath = '';

  String? _imageUrl;


  @override
  void initState() {
    super.initState();

    // Assuming Diaper has these properties. Adjust according to your Diaper class.
    _isDirtyClicked = widget.diaper.dirty_class == 1;
    _isDryClicked = widget.diaper.dry_class == 1;
    _isWetClicked = widget.diaper.wet_class == 1;

    // Parse the duration string into a Duration object.
    List<String> parts = widget.diaper.duration_class!.split(":");
    int hours = int.parse(parts[0]);
    int minutes = int.parse(parts[1]);

    _duration = Duration(hours: hours, minutes: minutes);


    // Parse the diaper time string into a TimeOfDay object.
    // You might need to adjust this line depending on the format of diaperTime_class.
    final format = DateFormat("h:mm a"); // Format for time like '3:08 PM'
    final date = format.parse(widget.diaper.diaper_startTime_class);
    _time = TimeOfDay(hour: date.hour, minute: date.minute);

    // Set the notes
    myTextController.text = widget.diaper.notes_class!;

    FirebaseFirestore.instance.collection('diapers').doc(widget.diaper.id).get().then((document) {
      if (document.exists) {
        setState(() {
          _imageUrl = document.get('imageUrl'); // make sure the field name is 'imagePath'
        });
      } else {
        print('No document found');
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Edit Diaper : ${widget.diaper.id}')),
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
                FutureBuilder(
                  future: Future.delayed(const Duration(seconds: 2)),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        width: 20.0, // Set the width
                        height: 20.0, // Set the height
                        child: CircularProgressIndicator(),
                      );
                    } else {
                      return _imageUrl != null && _imageUrl != ""
                          ? SizedBox(
                        width: 200.0, // Set the width
                        height: 200.0, // Set the height
                        child: Image.network(
                          _imageUrl!,
                          fit: BoxFit.cover, // To maintain the aspect ratio of the image
                          loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                            if (loadingProgress == null) {
                              return child;
                            }
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                        ),
                      )
                          : const SizedBox.shrink();
                    }
                  },
                ),

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
                          onPressed: () {
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



                              FirebaseFirestore.instance.collection('diapers').doc(widget.diaper.id).update({
                                'diaper_startTime_class': _time.format(context),
                                //'duration_class': _duration.inMinutes.toString(),
                                'duration_class': durationString,
                                'dirty_class': _isDirtyClicked ? 1 : 0,
                                'dry_class': _isDryClicked ? 1 : 0,
                                'wet_class': _isWetClicked ? 1 : 0,
                                'notes_class': myTextController.text,
                                'timeStamp_class': formattedDate = widget.diaper.timeStamp_class,
                                //'imagePath': _localImageFilePath == null ? "" : _localImageFilePath,
                              }).then((value) {
                                print("Diaper successfully updated");
                              }).catchError((error) {
                                print("Failed to update diaper: $error");
                              });
                              Navigator.pop(context);
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

        // upload image to Firebase Storage
        final storageRef = FirebaseStorage.instance.ref().child('images/$fileName');
        await storageRef.putFile(localImageFile);

        // get download URL and store it in Firestore
        final downloadUrl = await storageRef.getDownloadURL();

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return const AlertDialog(
              title: Text('Processing'),
              content: Text('Please wait patiently while the image is being processed.'),
            );
          },
        );

        // store download URL in Firestore
        await FirebaseFirestore.instance.collection('diapers').doc(widget.diaper.id).update({
          'imageUrl': downloadUrl,
        });

        setState(() {
          _imageFile = pickedFile;
          _localImageFilePath = localFilePath; // store local file path in state
          _imageUrl = downloadUrl; // set _imageUrl to the new download URL
        });
      }
    } catch (e) {
      print("Error picking image: $e");
    }
  }




}
