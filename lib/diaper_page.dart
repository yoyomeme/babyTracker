import 'package:flutter/material.dart';
import 'diaper.dart';
import 'package:provider/provider.dart';
import 'diaperAdd_page.dart';
import 'diaperEdit_page.dart';
import 'package:share_plus/share_plus.dart';



class Diaper_Page extends StatefulWidget {
  const Diaper_Page({Key? key}) : super(key: key);

  @override
  _Diaper_PageState createState() => _Diaper_PageState();
}

class _Diaper_PageState extends State<Diaper_Page> {
  final TextEditingController _searchController = TextEditingController();
  final Map<String, bool> checkedDiapers = {};  // This will keep track of the checked status of each diaper.

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
                Consumer<DiaperModel>(
                  builder: (context, diaperModel, child) {
                    // Filter the list based on the search query
                    final List<Diaper> filteredDiapers = diaperModel.items.where((diaper) {
                      return (_searchQuery.isEmpty ||
                          (diaper.dirty_class == 1 && 'dirty'.contains(_searchQuery.toLowerCase())) ||
                          (diaper.dry_class == 1 && 'dry'.contains(_searchQuery.toLowerCase())) ||
                          (diaper.wet_class == 1 && 'wet'.contains(_searchQuery.toLowerCase())) ||
                          (diaper.notes_class != null && diaper.notes_class!.toLowerCase().contains(_searchQuery.toLowerCase())) ||
                          (diaper.diaper_startTime_class.toLowerCase().contains(_searchQuery.toLowerCase())));
                    }).toList();

                    return diaperModel.loading
                        ? const SizedBox(
                      height: 10,
                      child: LinearProgressIndicator(),
                    )
                        :
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: diaperModel.refreshDiapers,
                        child: ListView.builder(
                          itemCount: filteredDiapers.length,
                          itemBuilder: (_, index) {
                            if (index < filteredDiapers.length) {

                              //var sortedDiapers = List<Diaper>.from(diaperModel.items);
                              filteredDiapers.sort((b, a) => DateTime.parse(a.timeStamp_class).compareTo(DateTime.parse(b.timeStamp_class)));

                              var diaper = filteredDiapers[index];

                              var image = getLeadingImage(diaper);
                              return Dismissible(
                                key: Key(diaper.id),
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
                                  diaperModel.delete(diaper.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("${diaper.id} dismissed")),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    children: <Widget>[
                                      image,
                                      Expanded(
                                        child: ListTile(
                                          title: Text(diaper.diaper_startTime_class),
                                          subtitle: Text("${diaper.duration_class} - ${diaper.duration_class} Minutes"),
                                          onTap: () {
                                            Navigator.push(context, MaterialPageRoute(
                                                builder: (context) {
                                                  return DiaperEdit_Page(diaper: diaper);
                                                }),
                                            ).then((_) => Provider.of<DiaperModel>(context, listen: false).refreshDiapers());
                                          },
                                        ),
                                      ),
                                      // Add your note here
                                      Text('Notes: ${diaper.notes_class}', style: const TextStyle(color: Colors.grey)),  // replace 'Your Note' with the actual note.
                                      Checkbox(
                                        value: checkedDiapers[diaper.id] ?? false,
                                        onChanged: (value) {
                                          setState(() {
                                            checkedDiapers[diaper.id] = value!;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                            return Container(); // return an empty container when index is not less than filteredDiapers.length
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
              child: Text("Item Count: ${Provider.of<DiaperModel>(context).items.length}")
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
                Navigator.push(context, MaterialPageRoute(builder: (context) => const DiaperAdd_Page()))
                    .then((_) => Provider.of<DiaperModel>(context, listen: false).refreshDiapers());
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
                if (!checkedDiapers.containsValue(true)) {
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
                  shareCheckedDiapers(context);
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

  void shareCheckedDiapers(BuildContext context) {
    final diaperModel = Provider.of<DiaperModel>(context, listen: false);
    String shareText = '';
    for (var diaper in diaperModel.items) {
      if (checkedDiapers[diaper.id] ?? false) {
        shareText += '${diaper.diaper_startTime_class} (${diaper.duration_class.toString()} - ${diaper.duration_class.toString()} Minutes)\n';
      }
    }
    print("Share text: $shareText");
    Share.share(shareText);
  }
/*
String? diaper_endTime_class;
  String diaper_startTime_class;
  int? dirty_class;
  int? dry_class;
  String? duration_class;
  String? notes_class;
  String timeStamp_class;
  int? wet_class;
 */
  Image getLeadingImage(Diaper diaper) {
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

