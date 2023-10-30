import 'package:week13_2023/diaper_page.dart';
import 'package:week13_2023/feed_page.dart';
import 'package:week13_2023/sleep_page.dart';

import 'package:flutter/material.dart';

class Allin extends StatefulWidget {
  final int pageIndex;
  const Allin({Key? key, required this.pageIndex}) : super(key: key);

  @override
  _AllinState createState() => _AllinState();
}

class _AllinState extends State<Allin> {
  late int pageIndex;

  @override
  void initState() {
    super.initState();
    pageIndex = widget.pageIndex;  // Initialize pageIndex with the value passed from the parent widget
  }

  void _changePage(int index) {
    setState(() {
      pageIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_getAppBarTitle())),
      body: _getBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: pageIndex,
        onTap: _changePage,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.fastfood),
            label: 'Feed',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bed),
            label: 'Sleep',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.baby_changing_station),
            label: 'Diaper',
          ),
        ],
      ),
    );
  }

  String _getAppBarTitle() {
    switch (pageIndex) {
      case 0:
        return 'Feed Page';
      case 1:
        return 'Sleep Page';
      case 2:
        return 'Diaper Page';
      default:
        return 'Feed Page';
    }
  }

  Widget _getBody() {
    switch (pageIndex) {
      case 0:
        return const Feed_Page();
      case 1:
        return const Sleep_Page();
      case 2:
        return const Diaper_Page();
      default:
        return const Feed_Page();
    }
  }
}
