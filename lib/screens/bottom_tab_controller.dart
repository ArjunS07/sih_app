// ignore_for_file: avoid_print

import 'package:flutter/material.dart';

import 'package:sih_app/utils/accounts_api_utils.dart' as auth_api_utils;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sih_app/models/platform_user.dart';
import 'package:sih_app/models/account.dart';
import 'package:sih_app/models/student.dart';
import 'package:sih_app/models/tutor.dart';

import 'tutorship_chats.dart';
import 'settings.dart';
import 'tutor_search.dart';
import 'my_tutor_requests.dart';

class BottomTabController extends StatefulWidget {
  final SharedPreferences prefs;

  const BottomTabController({Key? key, required this.prefs}) : super(key: key);

  @override
  State<BottomTabController> createState() => _BottomTabControllerState();
}

class _BottomTabControllerState extends State<BottomTabController> {
  int _index = 0;

  var loggedInUser;
  bool isStudent = false;

  bool _isLoading = false;

  Future<Account?> _loadLoggedinAccountFromPrefs() async {
    int? id = widget.prefs.getInt('id');
    print('Prefs id: $id');
    if (id != null) {
      var account = await auth_api_utils.getAccountFromId(id);
      return account;
    }
    return null;
  }

  Future<PlatformUser?> _loadLoggedinUserFromAccount() async {
    var account = await _loadLoggedinAccountFromPrefs();
    if (account != null) {
      var user = await auth_api_utils.getUserFromAccount(account);
      return user;
    } else {
      print("Error finding user for logged in account");
      return null;
    }
  }

  // export
  void loadUserState() async {
    var user = await _loadLoggedinUserFromAccount();
    if (user != null) {
      setState(() {
        print('Setting state...');
        loggedInUser = user;
        isStudent = user is Student;
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    setState(() {
      _isLoading = true;
    });
    super.initState();
    loadUserState();
  }

  Widget _studentTabController() {
    Widget child = TutorshipChats();
    switch (_index) {
      case 0:
        child = TutorshipChats(loggedinStudent: loggedInUser as Student);
        break;
      case 1:
        child = TutorSearch(student: loggedInUser as Student);
        break;
      case 2:
        child = Settings(
          notifyParentReload: loadUserState,
          loggedInStudent: loggedInUser as Student,
        );
        break;
    }
    return Scaffold(
      body: SizedBox.expand(child: child),
      bottomNavigationBar: BottomNavigationBar(
        onTap: (newIndex) => setState(() => _index = newIndex),
        currentIndex: _index,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
              icon: Icon(Icons.people), label: "Volunteers"),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Find"),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: "Settings"),
        ],
      ),
    );
  }

  Widget _tutorTabController() {
    Widget child = TutorshipChats();
    switch (_index) {
      case 0:
        child = TutorshipChats(loggedinTutor: loggedInUser as Tutor);
        break;
      case 1:
        child = MyTutorRequests(loggedInTutor: loggedInUser as Tutor);
        break;
      case 2:
        child = Settings(
            notifyParentReload: loadUserState,
            loggedInTutor: loggedInUser as Tutor);
        break;
    }
    return Scaffold(
      body: SizedBox.expand(child: child),
      bottomNavigationBar: BottomNavigationBar(
        onTap: (newIndex) => setState(() => _index = newIndex),
        currentIndex: _index,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.school), label: "Students"),
          BottomNavigationBarItem(
              icon: Icon(Icons.notifications), label: "Requests"),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: "Settings"),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Scaffold(
          body: SizedBox.expand(child: 
            Center(
              child: CircularProgressIndicator(),
            )))
        : isStudent
            ? _studentTabController()
            : _tutorTabController();
  }
}
