// ignore_for_file: avoid_print

import 'package:flutter/material.dart';

import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:search_choices/search_choices.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

import 'package:sih_app/utils/accounts_api_utils.dart';
import 'package:sih_app/utils/choices.dart';
import 'package:sih_app/models/choice.dart';
import 'package:sih_app/utils/persistence_utils.dart' as persistence_utils;
import 'package:sih_app/utils/extensions/numeric_range_formatter.dart';

import 'package:sih_app/screens/bottom_tab_controller.dart';
import 'package:sih_app/utils/widgets/standard_alert_dialog.dart';

class TutorDetails extends StatefulWidget {
  final String email;
  final String firstName;
  final String lastName;
  final String password;
  const TutorDetails(
      {Key? key,
      required this.email,
      required this.firstName,
      required this.lastName,
      required this.password})
      : super(key: key);

  @override
  State<TutorDetails> createState() => _TutorDetailsState();
}

class _TutorDetailsState extends State<TutorDetails> {
  late List<Choice> _languageChoices = [];
  late List<String> _selectedLanguagesIds = [];

  late List<Choice> _boardChoices = [];
  late List<String> _selectedBoardIds = [];

  late List<Choice> _cityChoices = [];
  String _selectedCityId = '';

  late List<Choice> _gradeChoices = [];
  late List<String> _selectedGradeIds = [];

  late List<Choice> _subjectChoices = [];
  late List<String> _selectedSubjectIds = [];

  late List<Choice> _highestEducationalLevelChoices = [];
  String _selectedEducationalLevel = '';

  var _ageTextController = TextEditingController();

  var _isLoading = false;

  void getChoices() async {
    _languageChoices = await loadChoices('languages');
    _boardChoices = await loadChoices('boards');
    _cityChoices = await loadChoices('cities');
    _gradeChoices = await loadChoices('grades');
    _subjectChoices = await loadChoices('subjects');
    _highestEducationalLevelChoices = await loadChoices('educational_level');

    setState(() {
      _languageChoices = _languageChoices;
      _boardChoices = _boardChoices;
      _cityChoices = _cityChoices;
      _gradeChoices = _gradeChoices;
      _subjectChoices = _subjectChoices;
      _highestEducationalLevelChoices = _highestEducationalLevelChoices;
    });
    // _languageChoices = await getChoicesMap('languages').values.toList();
    // _cityChoices = await getChoicesMap('cities');
    // _gradeChoices = await getChoicesMap('grades');
  }

  @override
  void initState() {
    super.initState();
    getChoices();
  }

  void _submitRegistration(context) async {
    // Check that none of the selected lists are empty
    print('Board IDs: $_selectedBoardIds');
    print('Language IDs: $_selectedLanguagesIds');
    print('Grade IDs: $_selectedGradeIds');
    print('Subject IDs: $_selectedSubjectIds');
    print('Highest Educational Level: $_selectedEducationalLevel');
    print('City ID: $_selectedCityId');

    if (_selectedBoardIds == [] ||
        _selectedLanguagesIds == [] ||
        _selectedGradeIds == [] ||
        _selectedSubjectIds == [] ||
        _selectedEducationalLevel == '' ||
        _ageTextController.text == '') {
      print('Missing field');
      return;
    }
    setState(() {
      _isLoading = true;
    });

    print('Email: ${widget.email}');
    var account = await registerNewAccount(
            widget.email, widget.password, widget.firstName, widget.lastName)
        .catchError((error) {
      setState(() {
        _isLoading = false;
      });
      showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
                title: const Text('Error'),
                content: Text('$error'),
                actions: <Widget>[
                  TextButton(
                    child: const Text('OK'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ));
      print('Error creating account');
    });
    if (account != null) {
      persistence_utils.upDateSharedPreferences(
          account.authToken!, account.accountId);
      print('Creating tutor account');
      createTutor(
              account,
              _selectedCityId,
              _selectedLanguagesIds,
              _selectedBoardIds,
              _selectedGradeIds,
              _selectedSubjectIds,
              _selectedEducationalLevel,
              _ageTextController.text)
          .then((tutor) {
        setState(() {
          _isLoading = false;
        });
        persistence_utils.getPrefs().then((prefs) => {
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => BottomTabController(prefs: prefs)))
            });
      });
    }
  }

  Widget _bodyWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 32.0),
      child: CustomScrollView(
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(left: 4.0),
                      child: Text('What languages do you speak?',
                          style: TextStyle(
                              fontSize: 16.0, fontWeight: FontWeight.bold)),
                    )),
                MultiSelectDialogField(
                    buttonText: Text(
                      'Select languages',
                      style: TextStyle(
                          fontSize: 16.0, color: Colors.grey.shade900),
                    ),
                    buttonIcon: const Icon(Icons.language),
                    title: const Text('Your languages'),
                    selectedColor: Colors.black,
                    searchable: true,
                    items: _languageChoices
                        .map((language) =>
                            MultiSelectItem(language.id, language.name))
                        .toList(),
                    listType: MultiSelectListType.LIST,
                    onConfirm: (values) {
                      _selectedLanguagesIds = [];
                      for (var value in values) {
                        _selectedLanguagesIds.add(value.toString());
                      }
                    }),
                const SizedBox(height: 40.0),
                Padding(
                  padding: const EdgeInsets.only(left: 4.0),
                  child: Column(children: [
                    const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('What city do you live in?',
                            style: TextStyle(
                                fontSize: 16.0, fontWeight: FontWeight.bold))),
                    SearchChoices.single(
                      icon: const Icon(Icons.pin_drop),
                      items: _cityChoices
                          .map((city) => DropdownMenuItem(
                              value: city.id, child: Text(city.name)))
                          .toList(),
                      value: _selectedCityId,
                      padding: 0.0,
                      style: const TextStyle(
                          fontSize: 16.0,
                          color: Colors.black,
                          fontWeight: FontWeight.w500),
                      hint: "Select your city",
                      searchHint: "Select your city",
                      onChanged: (value) {
                        setState(() {
                          _selectedCityId = value;
                        });
                      },
                      isExpanded: true,
                    )
                  ]),
                ),
                const SizedBox(height: 30.0),
                Padding(
                  padding: const EdgeInsets.only(left: 4.0),
                  child: Column(children: [
                    const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('How old are you?',
                            style: TextStyle(
                                fontSize: 16.0, fontWeight: FontWeight.bold))),
                    TextField(
                      controller: _ageTextController,
                      keyboardType: TextInputType.number,
                      autocorrect: false,
                      decoration: InputDecoration(
                          suffixIcon: Icon(Icons.cake) //Icon at the end
                          ),
                    )
                  ]),
                ),
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.only(left: 4.0),
                  child: Column(children: [
                    const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                            'What is your highest educational qualification?',
                            style: TextStyle(
                                fontSize: 16.0, fontWeight: FontWeight.bold))),
                    SearchChoices.single(
                      icon: const Icon(Icons.school),
                      items: _highestEducationalLevelChoices
                          .map((educationalLevel) => DropdownMenuItem(
                              value: educationalLevel.id,
                              child: Text(educationalLevel.name)))
                          .toList(),
                      value: _selectedEducationalLevel,
                      padding: 0.0,
                      style: const TextStyle(
                          fontSize: 16.0,
                          color: Colors.black,
                          fontWeight: FontWeight.w500),
                      hint: "Select your city",
                      searchHint: "Select your city",
                      onChanged: (value) {
                        setState(() {
                          _selectedEducationalLevel = value;
                        });
                        print(_selectedEducationalLevel);
                      },
                      isExpanded: true,
                    )
                  ]),
                ),
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.only(left: 4.0),
                  child: Column(children: [
                    const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('What boards can you teach?',
                            style: TextStyle(
                                fontSize: 16.0, fontWeight: FontWeight.bold))),
                    MultiSelectDialogField(
                        buttonText: Text(
                          'Select boards',
                          style: TextStyle(
                              fontSize: 16.0, color: Colors.grey.shade900),
                        ),
                        buttonIcon: const Icon(Icons.meeting_room),
                        title: const Text('Your boards'),
                        selectedColor: Colors.black,
                        searchable: true,
                        items: _boardChoices
                            .map((board) =>
                                MultiSelectItem(board.id, board.name))
                            .toList(),
                        listType: MultiSelectListType.LIST,
                        onConfirm: (values) {
                          _selectedBoardIds = [];
                          for (var value in values) {
                            _selectedBoardIds.add(value.toString());
                          }
                        })
                  ]),
                ),
                const SizedBox(height: 40.0),
                Padding(
                  padding: const EdgeInsets.only(left: 4.0),
                  child: Column(
                    children: [
                      const Align(
                          alignment: Alignment.centerLeft,
                          child: Text('What grades can you teach?',
                              style: TextStyle(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.bold))),
                      MultiSelectDialogField(
                          buttonText: Text(
                            'Select grades',
                            style: TextStyle(
                                fontSize: 16.0, color: Colors.grey.shade900),
                          ),
                          buttonIcon: const Icon(Icons.pin),
                          title: const Text('Select grades'),
                          selectedColor: Colors.black,
                          searchable: true,
                          items: _gradeChoices
                              .map((grade) =>
                                  MultiSelectItem(grade.id, grade.name))
                              .toList(),
                          listType: MultiSelectListType.LIST,
                          onConfirm: (values) {
                            _selectedGradeIds = [];
                            for (var value in values) {
                              _selectedGradeIds.add(value.toString());
                            }
                          }),
                    ],
                  ),
                ),
                const SizedBox(height: 40.0),
                Column(children: [
                  const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('What subjects can you teach?',
                          style: TextStyle(
                              fontSize: 16.0, fontWeight: FontWeight.bold))),
                  MultiSelectDialogField(
                      buttonText: Text(
                        'Select subjects',
                        style: TextStyle(
                            fontSize: 16.0, color: Colors.grey.shade900),
                      ),
                      buttonIcon: const Icon(Icons.science),
                      title: const Text('Your subjects'),
                      selectedColor: Colors.black,
                      searchable: true,
                      items: _subjectChoices
                          .map((subject) =>
                              MultiSelectItem(subject.id, subject.name))
                          .toList(),
                      listType: MultiSelectListType.LIST,
                      onConfirm: (values) {
                        for (var value in values) {
                          _selectedSubjectIds.add(value.toString());
                        }
                      }),
                ]),
                const SizedBox(height: 25.0),
                const Spacer(),
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      primary: Colors.black,
                    ),
                    onPressed: () => {
                          // Check that none of the values are empty
                          if (_selectedLanguagesIds.isNotEmpty &&
                              _selectedCityId != null &&
                              _selectedBoardIds.isNotEmpty &&
                              _selectedGradeIds.isNotEmpty &&
                              _selectedSubjectIds.isNotEmpty)
                            {_submitRegistration(context)}
                          else
                            {
                              // Show an error message
                              showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                        title: const Text('Error'),
                                        content: const Text(
                                            'Please select at least one language, city, board, grade and subject'),
                                        actions: [
                                          ElevatedButton(
                                              onPressed: () =>
                                                  Navigator.of(context).pop(),
                                              child: const Text('OK'))
                                        ],
                                      ))
                            }
                        },
                    child: const Text('Complete registration')),
                const SizedBox(height: 15)
              ],
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Enter your details'),
        ),
        body: ModalProgressHUD(inAsyncCall: _isLoading, child: _bodyWidget()));
  }
}
