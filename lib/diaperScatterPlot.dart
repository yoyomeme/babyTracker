import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'diaper.dart';

class DiaperScatterPlot extends StatefulWidget {
  final DiaperModel diaperModel;

  const DiaperScatterPlot(this.diaperModel, {super.key});

  @override
  _DiaperScatterPlotState createState() => _DiaperScatterPlotState();
}

class _DiaperScatterPlotState extends State<DiaperScatterPlot> {
  Map<String, ui.Image> images = {};

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    var assetNames = ['lib/images/drypoop.png', 'lib/images/wetpoop.png', 'lib/images/checkpoop.png', 'lib/images/dry.png', 'lib/images/wet.png'];
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
          painter: images.isNotEmpty ? _DiaperScatterPlotPainter(widget.diaperModel, images) : null,
        );
      },
    );
  }
}

class _DiaperScatterPlotPainter extends CustomPainter {
  final DiaperModel diaperModel;
  final Map<String, ui.Image> images;
  final timeRegex = RegExp(r'^(\d{1,2}):(\d{2}) (AM|PM)$');
  final timeFormat = DateFormat.jm();

  _DiaperScatterPlotPainter(this.diaperModel, this.images);

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
    for (var i = 0; i < diaperModel.items.length; i++) {
      var diaper = diaperModel.items[i];
      //debug
      DateTime diaperDateTime;
      int hour;
      try {
        diaperDateTime = DateTime.parse(diaper.timeStamp_class);
        final diaperTime = DateFormat("h:mm a").parse(diaper.diaper_startTime_class);
        hour = diaperTime.hour;
      } catch (e) {
        print('Exception when parsing diaper timestamps or times: $e');
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
    for (var i = 0; i < diaperModel.items.length; i++) {
      var diaper = diaperModel.items[i];

      DateTime diaperDateTime;
      int hour;
      try {
        diaperDateTime = DateTime.parse(diaper.timeStamp_class);
        final diaperTime = DateFormat("h:mm a").parse(diaper.diaper_startTime_class);
        hour = diaperTime.hour;
      } catch (e) {
        print('Exception when parsing diaper timestamps or times: $e');
        continue;
      }

      int daysAgo = DateTime.now().difference(diaperDateTime).inDays;
      if (daysAgo > 7) continue;

      // Instead of daysAgo / 7, use (7 - daysAgo) / 7 so day 0 (today) is at the right and day 7 is at the left.
      double x = ((7 - daysAgo) / 7) * size.width;
      // Instead of hour / 24, use (24 - hour) / 24 so 0 hour is at the bottom and 24 hour is at the top.
      double y = ((24 - hour) / 24) * size.height;

      // Define the destination rectangle for the image. This is used to scale the image.
      double imageWidth = 40.0;  // set the width and height to your preferred values
      double imageHeight = 40.0;
      Rect destinationRect = Rect.fromLTWH(x, y - imageHeight, imageWidth, imageHeight);



      String? assetName;

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
