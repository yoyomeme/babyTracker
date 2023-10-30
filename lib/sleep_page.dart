import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:week13_2023/sleepAdd_page.dart';
import 'package:week13_2023/sleepEdit_page.dart';

import 'sleep.dart';

class Sleep_Page extends StatefulWidget {
  const Sleep_Page({Key? key}) : super(key: key);

  @override
  _Sleep_PageState createState() => _Sleep_PageState();
}

class _Sleep_PageState extends State<Sleep_Page> {
  final TextEditingController _searchController = TextEditingController();
  final Map<String, bool> checkedSleeps = {};  // This will keep track of the checked status of each sleep.

  String _searchQuery = ''; // Variable to keep track of the current search query

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          // Your body content here
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
                Consumer<SleepModel>(//used chatgpt
                  builder: (context, sleepModel, child) {
                    // Filter the list based on the search query
                    final List<Sleep> filteredSleeps = sleepModel.items.where((sleep) {
                      // split and parse the time
                      final timeParts = sleep.sleep_startTime_class.split(RegExp(r'[: ]'));
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

                      // determine if the time is day or night
                      bool isDay = (startTime.hour >= morningStart.hour && startTime.minute >= morningStart.minute) &&
                          (startTime.hour < eveningStart.hour || (startTime.hour == eveningStart.hour && startTime.minute < eveningStart.minute));

                      // match with the search query
                      bool matchesQuery = (_searchQuery.isEmpty ||
                          (isDay && 'sun'.contains(_searchQuery.toLowerCase())||
                          (isDay && 'day'.contains(_searchQuery.toLowerCase()) ||
                          (!isDay && 'moon'.contains(_searchQuery.toLowerCase()) ||
                          (!isDay && 'night'.contains(_searchQuery.toLowerCase())) ||
                          (sleep.sleep_startTime_class.toLowerCase().contains(_searchQuery.toLowerCase()))))));

                      return matchesQuery;
                    }).toList();

                    return sleepModel.loading
                        ? const SizedBox(
                      height: 10,
                      child: LinearProgressIndicator(),
                    )
                        :
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: sleepModel.refreshSleeps,
                        child: ListView.builder(
                          itemCount: filteredSleeps.length,
                          itemBuilder: (_, index) {
                            if (index < filteredSleeps.length) {
                              var sleep = filteredSleeps[index];
                              var image = getLeadingImage(sleep);
                              return Dismissible(
                                key: Key(sleep.id),
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
                                  sleepModel.delete(sleep.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("${sleep.id} dismissed")),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    children: <Widget>[
                                      image,
                                      Expanded(
                                        child: ListTile(
                                          title: Text(sleep.sleep_startTime_class),
                                          subtitle: Text("${sleep.duration_class} - ${sleep.duration_class} Minutes"),
                                          onTap: () {
                                            Navigator.push(context, MaterialPageRoute(
                                                builder: (context) {
                                                  return SleepEdit_Page(sleep: sleep);
                                                }),
                                            ).then((_) => Provider.of<SleepModel>(context, listen: false).refreshSleeps());
                                          },
                                        ),
                                      ),
                                      // Add your note here
                                      Text('Notes: ${sleep.notes_class}', style: const TextStyle(color: Colors.grey)),  // replace 'Your Note' with the actual note.
                                      Checkbox(
                                        value: checkedSleeps[sleep.id] ?? false,
                                        onChanged: (value) {
                                          setState(() {
                                            checkedSleeps[sleep.id] = value!;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                            return Container(); // return an empty container when index is not less than filteredSleeps.length
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
              top: 26.0,
              left: MediaQuery.of(context).size.width / 2.5,
              child: Text("Item Count: ${Provider.of<SleepModel>(context).items.length}")
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
                Navigator.push(context, MaterialPageRoute(builder: (context) => const SleepAdd_Page()))
                    .then((_) => Provider.of<SleepModel>(context, listen: false).refreshSleeps());
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
                if (!checkedSleeps.containsValue(true)) {
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
                  shareCheckedSleeps(context);
                }
              },
            ),
          ),
        ],
      ),
      //),
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

  void shareCheckedSleeps(BuildContext context) {
    final sleepModel = Provider.of<SleepModel>(context, listen: false);
    String shareText = '';
    for (var sleep in sleepModel.items) {
      if (checkedSleeps[sleep.id] ?? false) {
        shareText += '${sleep.sleep_startTime_class} (${sleep.duration_class.toString()} - ${sleep.duration_class.toString()} Minutes)\n';
      }
    }
    print("Share text: $shareText");
    Share.share(shareText);
  }
/*
'duration_class': duration_class,
'notes_class': notes_class,
'sleep_endTime_class' : sleep_endTime_class,
'sleep_startTime_class': sleep_startTime_class,
'timeStamp_class' : timeStamp_class
 */


  Image getLeadingImage(Sleep sleep) {
    String assetName;

    // parse sleep_startTime_class back into a TimeOfDay object
    final timeParts = sleep.sleep_startTime_class.split(RegExp(r'[: ]')); //split by colon and space
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
      assetName = 'lib/images/babysun.png';
    } else {
      assetName = 'lib/images/babynight.png';
    }

    return Image.asset(
      assetName,
      width: 55.0,  // Set your desired width
      height: 55.0,  // Set your desired height
      fit: BoxFit.cover,
    );
  }






}
