import 'package:flutter/material.dart';

import 'package:sih_app/models/tutor.dart';
import 'package:sih_app/models/student.dart';
import 'package:sih_app/models/tutorship.dart';

import 'package:sih_app/utils/tutor_api_utils.dart';
import 'package:sih_app/utils/tutorship_api_utils.dart';

class MyTutorRequests extends StatefulWidget {
  Tutor loggedInTutor;
  MyTutorRequests({Key? key, required this.loggedInTutor}) : super(key: key);

  @override
  State<MyTutorRequests> createState() => _MyTutorRequestsState();
}

class _MyTutorRequestsState extends State<MyTutorRequests> {
  var _requests =
      <dynamic>[]; // array of tutorships each of which contain a student
  bool _isLoadingRequests = false;

  // api stuff
  Future<void> _loadRequests() async {
    setState(() {
      _isLoadingRequests = true;
    });
    final tutorshipRequests =
        await getMyTutorshipRequests(widget.loggedInTutor, 'PNDG');
    setState(() {
      _requests = tutorshipRequests;
      _isLoadingRequests = false;
    });
  }

  Future<Map<String, dynamic>> _decodeTutorshipData(Tutorship tutorship) async {
    var data = {
      'city': await tutorship.student.decodedCity,
      'languages': await tutorship.student.decodedLanguagesDisplay,
      'subjects': await tutorship.decodedSubjectsDisplay,
    };
    return data;
  }

  _rejectTutorshipRequest(Tutorship tutorship) async {
    updateTutorshipStatus('RJCT', tutorship.id).then((tutorship) =>
        {_showAcceptedRequestSnackBar(tutorship), _loadRequests()});
  }

  _acceptTutorshipRequest(Tutorship tutorship) async {
    var decodedData = await _decodeTutorshipData(tutorship);
    showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Accept request?'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                    'Accept request from ${tutorship.student.name} to teach ${decodedData['subjects']}'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('No', style: TextStyle(color: Colors.black)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
                onPressed: () async {
                  updateTutorshipStatus('ACPT', tutorship.id)
                      .then((tutorship) => {
                            Navigator.of(context).pop(),
                            _showAcceptedRequestSnackBar(tutorship),
                            _loadRequests()
                          });
                },
                child: const Text('Yes'),
                style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all<Color>(Colors.black)))
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  // ui stuff

  Widget _buildRow(int index) {
    var request = _requests[index];
    return Row(children: <Widget>[
      Expanded(
        child: FutureBuilder(
          future: _decodeTutorshipData(request),
          initialData: 'Loading tutor data...',
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text('Data is loading...');
            } else {
              print(snapshot.data);
              Map data = snapshot.data as Map;
              return Card(
                  child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: ListTile(
                  title: Text('${request.student.name}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 21.0)),
                  isThreeLine: true,
                  subtitle: Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: RichText(
                          text: TextSpan(
                              style: const TextStyle(
                                  fontSize: 16.0, color: Colors.black),
                              children: <TextSpan>[
                            TextSpan(
                                text: '${data['city']}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            TextSpan(
                                text:
                                    '\n\nSpeaks ${data['languages']}\n\nWants help with'),
                            TextSpan(
                                text: ' ${data['subjects']}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            TextSpan(
                                text:
                                    '\n\n${request.relativeTimeSinceCreated.toUpperCase()}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey))
                          ]))),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                          onPressed: () => {_rejectTutorshipRequest(request)},
                          icon: Icon(Icons.close, color: Colors.red.shade300)),
                      IconButton(
                          onPressed: () => {_acceptTutorshipRequest(request)},
                          icon: const Icon(Icons.check, color: Colors.indigo)),
                    ],
                  ),
                ),
              ));
            }
          },
        ),
      ),
    ]);
  }

  void _showAcceptedRequestSnackBar(Tutorship tutorship) {
    String message = 'Accepted request from ${tutorship.student.name}';
    var snackBar = SnackBar(
      content: Text(message),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student requests'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _isLoadingRequests ? const Expanded(
                    child: SizedBox(
                        height: 100,
                        child: Center(child: CircularProgressIndicator())),
                  )
                : _requests.isEmpty
                    ? Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Center(
                            child: Text(
                                "No pending requests from students.\n\nWhen a student asks to learn from you, you'll see them here.",
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w300,
                                    color: Colors.grey.shade600)),
                          ),
                        ),
                      )
                    : Expanded(
                        child: ListView.builder(
                        itemCount: _requests.length,
                        itemBuilder: (BuildContext context, int position) {
                          return _buildRow(position);
                        },
                      )),
          ],
        ),
      ),
    );
  }
}
