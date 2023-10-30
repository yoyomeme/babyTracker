import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'sleep.dart';

class SleepScatterPlot extends StatefulWidget {
  final SleepModel sleepModel;

  const SleepScatterPlot(this.sleepModel, {super.key});

  @override
  _SleepScatterPlotState createState() => _SleepScatterPlotState();
}

class _SleepScatterPlotState extends State<SleepScatterPlot> {
  Map<String, ui.Image> images = {};

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    var assetNames = ['lib/images/babysun.png', 'lib/images/babynight.png'];
    for (var assetName in assetNames) {
      final byteData = await rootBundle.load(assetName);
      final codec = await ui.instantiateImageCodec(byteData.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      images[assetName] = frame.image;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: images.isNotEmpty ? _SleepScatterPlotPainter(widget.sleepModel, images) : null,
        );
      },
    );
  }
}

class _SleepScatterPlotPainter extends CustomPainter {
  final SleepModel sleepModel;
  final Map<String, ui.Image> images;
  final timeRegex = RegExp(r'^(\d{1,2}):(\d{2}) (AM|PM)$');
  final timeFormat = DateFormat.jm();

  _SleepScatterPlotPainter(this.sleepModel, this.images);

  @override
  void paint(Canvas canvas, Size size) {
    var axisPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2;

    var axisTextPaint = TextPainter(
      textDirection: ui.TextDirection.ltr,
      text: const TextSpan(style: TextStyle(color: Colors.black)),
    );

    // Draw the x-axis
    canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), axisPaint);

    // Draw the y-axis
    canvas.drawLine(const Offset(0, 0), Offset(0, size.height), axisPaint);

    // Draw labels along the x-axis and y-axis
    for (var i = 0; i < sleepModel.items.length; i++) {
      var sleep = sleepModel.items[i];
      //debug
      DateTime sleepDateTime;
      int hour;
      try {
        sleepDateTime = DateTime.parse(sleep.timeStamp_class);
        final sleepTime = DateFormat("h:mm a").parse(sleep.sleep_startTime_class);
        hour = sleepTime.hour;
      } catch (e) {
        print('Exception when parsing sleep timestamps or times: $e');
        continue;
      }
    }

    // Draw labels along the x-axis and y-axis
    for (int i = 0; i <= 7; i++) {
      DateTime date = DateTime.now().subtract(Duration(days: 7 - i));
      String dayName = DateFormat('EEE').format(date); // Get the day name (Mon, Tue, Wed, etc.)

      // Calculate x position
      double x = i / 7 * size.width +20;

      // Paint the date
      axisTextPaint.text = TextSpan(text: DateFormat('MM/dd').format(date), style: const TextStyle(color: Colors.black));
      axisTextPaint.layout();
      // Subtract half the width of the text from x for correct positioning
      axisTextPaint.paint(canvas, Offset(x - axisTextPaint.width / 2, size.height - axisTextPaint.height/1000));

      // Paint the day name below the date
      axisTextPaint.text = TextSpan(text: dayName, style: const TextStyle(color: Colors.black));
      axisTextPaint.layout();
      // Subtract half the width of the text from x for correct positioning
      axisTextPaint.paint(canvas, Offset(x - axisTextPaint.width / 2, size.height - axisTextPaint.height));
    }

    for (int i = 2; i <= 24; i += 2) {  // increment by 2
      axisTextPaint.text = TextSpan(text: '$i', style: const TextStyle(color: Colors.black));
      axisTextPaint.layout();
      axisTextPaint.paint(canvas, Offset(-20, size.height - i / 24 * size.height - axisTextPaint.height / 1));
    }

    // Draw the markers
    for (var i = 0; i < sleepModel.items.length; i++) {
      var sleep = sleepModel.items[i];

      DateTime sleepDateTime;
      int hour;
      try {
        sleepDateTime = DateTime.parse(sleep.timeStamp_class);
        final sleepTime = DateFormat("h:mm a").parse(sleep.sleep_startTime_class);
        hour = sleepTime.hour;
      } catch (e) {
        print('Exception when parsing sleep timestamps or times: $e');
        continue;
      }

      int daysAgo = DateTime.now().difference(sleepDateTime).inDays;
      if (daysAgo > 7) continue;

      // Instead of daysAgo / 7, use (7 - daysAgo) / 7 so day 0 (today) is at the right and day 7 is at the left.
      double x = ((7 - daysAgo) / 7) * size.width;
      // Instead of hour / 24, use (24 - hour) / 24 so 0 hour is at the bottom and 24 hour is at the top.
      double y = ((24 - hour) / 24) * size.height;

      // Define the destination rectangle for the image. This is used to scale the image.
      double imageWidth = 40.0;  // set the width and height to your preferred values
      double imageHeight = 40.0;
      Rect destinationRect = Rect.fromLTWH(x, y - imageHeight, imageWidth, imageHeight);



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
      var image = images[assetName];

      // Draw the image instead of the circle
      canvas.drawImageRect(
          image!,
          Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
          destinationRect,
          Paint()
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
