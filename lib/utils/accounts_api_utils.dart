// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sih_app/models/platform_user.dart';
import 'package:uuid/uuid.dart';

import 'package:sih_app/models/account.dart';
import 'package:sih_app/models/School.dart';
import 'package:sih_app/models/student.dart';
import 'package:sih_app/models/tutor.dart';
import 'package:sih_app/utils/student_api_utils.dart';

import 'base_api_utils.dart';

Future<String> getAccountAuthToken(String email, String password) async {
  var headers = {
    'Content-Type': 'application/x-www-form-urlencoded',
  };
  var request =
      http.Request('POST', Uri.parse('$ROOT_URL/accounts/api-token-auth/'));
  request.bodyFields = {
    'username':
        email, //the api requires a username field but we're using an email so it works
    'password': password
  };
  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();
  Map<String, dynamic> body =
      json.decode(await response.stream.bytesToString());

  if (response.statusCode == 200) {
    return body['token'];
  } else {
    throw Exception('Failed to get token');
  }
}

Future<Account?> login(String email, String password) async {
  final loginUri = Uri.parse('$ROOT_URL/accounts/login/');

  var headers = {'Content-Type': 'application/x-www-form-urlencoded'};
  var request = http.Request('POST', loginUri);
  request.bodyFields = {'email': email, 'password': password};
  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();
  Map<String, dynamic> body =
      json.decode(await response.stream.bytesToString());

  if (response.statusCode != 200) {
    print(response.reasonPhrase);
    throw Exception(body);
  }

  Map<String, dynamic> accountInfo = body['user'];
  var account = Account.fromJson(accountInfo);
  account.authToken = await getAccountAuthToken(email, password);
  return account;
}

Future<Account?> registerNewAccount(
    String email, String password, String firstName, String lastName) async {
  var headers = {'Content-Type': 'application/x-www-form-urlencoded'};
  final registerUri = Uri.parse('$ROOT_URL/accounts/register/');
  var request = http.Request('POST', registerUri);
  request.bodyFields = {
    'email': email,
    'password1': password,
    'password2': password,
    'first_name': firstName,
    'last_name': lastName
  };
  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();
  Map<String, dynamic> body =
      json.decode(await response.stream.bytesToString());

  if (response.statusCode == 201) {
    var accountData = body['user'];
    var account = Account.fromJson(accountData);
    account.authToken = await getAccountAuthToken(email, password);
    return account;
  } else {
    print(response.reasonPhrase);
    throw Exception(body);
  }
}

Future<Student?> createStudent(
    Account account,
    String city,
    List<String> languages,
    School studentSchool,
    String board,
    String grade) async {
  // 1. Make an API call to create a student account
  final String parsedLanguages = languages.join(',');
  final String studentUuid = uuid.v4();

  final Uri studentCreationUri = Uri.parse('$ROOT_URL/api/students');
  var studentCreationHeaders = {
    'Content-Type': 'application/x-www-form-urlencoded'
  };
  var studentCreationRequest = http.Request('POST', studentCreationUri);
  studentCreationRequest.bodyFields = {
    'account__id': account.accountId.toString(),
    'city': city,
    'languages': parsedLanguages,
    'board': board,
    'grade': grade,
    'uuid': studentUuid
  };
  studentCreationRequest.headers.addAll(studentCreationHeaders);

  http.StreamedResponse studentCreationResponse =
      await studentCreationRequest.send();
  Map<String, dynamic> studentCreationBody =
      json.decode(await studentCreationResponse.stream.bytesToString());

  if (studentCreationResponse.statusCode != 201) {
    print(studentCreationResponse.reasonPhrase);
    throw Exception(studentCreationBody);
  }

  // 2. Make the student join the school
  await joinStudentToSchool(studentUuid, studentSchool.joinCode)
      .then((student) {
    return student;
  });
}

Future<Tutor> createTutor(
    Account account,
    String city,
    List<String> languages,
    List<String> boards,
    List<String> grades,
    List<String> subjects,
    String highestEducationalLevelId,
    String age) async {
  final String parsedLanguages = languages.join(',');
  final String parsedBoards = boards.join(',');
  final String parsedGrades = grades.join(',');
  final String parsedSubjects = subjects.join(',');
  final String tutorUuid = uuid.v4();

  final Uri tutorCreationUri = Uri.parse('$ROOT_URL/api/tutors');
  var headers = {
    'Authorization':
        'Token ${account.authToken}', // authorization header requires this formatting
    'Content-Type': 'application/x-www-form-urlencoded',
  };
  var request = http.Request('POST', tutorCreationUri);
  request.bodyFields = {
    'uuid': tutorUuid,
    'city': city,
    'languages': parsedLanguages,
    'boards': parsedBoards,
    'subjects': parsedSubjects,
    'grades': parsedGrades,
    'account__id': account.accountId.toString(),
    'age': age,
    'highest_educational_level': highestEducationalLevelId
  };
  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();
  Map<String, dynamic> body =
      json.decode(await response.stream.bytesToString());
  if (response.statusCode != 201) {
    print(response.reasonPhrase);
    throw Exception(body);
  }

  Tutor tutor = Tutor.fromJson(body);
  return tutor;
}

Future<Account> getAccountFromId(int id) async {
  final Uri getAccountUri = Uri.parse('$ROOT_URL/accounts/users?id=$id');
  var request = http.Request('GET', getAccountUri);

  http.StreamedResponse response = await request.send();
  Map<String, dynamic> body =
      json.decode(await response.stream.bytesToString());

  if (response.statusCode == 200) {
    Account account = Account.fromJson(body);
    return account;
  } else {
    throw (response.reasonPhrase.toString());
  }
}

getUserFromAccount(Account account) async {
  int id = account.accountId;
  var request = http.Request(
      'GET', Uri.parse('$ROOT_URL/api/userfromaccount?account_id=$id'));

  http.StreamedResponse response = await request.send();
  Map<String, dynamic> body =
      json.decode(await response.stream.bytesToString());

  if (response.statusCode == 200) {
    bool isStudent = body['type'] == 'student';
    Map<String, dynamic> userDetails = body['user'];
    if (isStudent) {
      return Student.fromJson(userDetails);
    } else {
      List<String> languages = userDetails['languages'].cast<String>();
      List<String> boards = userDetails['boards'].cast<String>();
      List<String> grades = userDetails['grades'].cast<String>();
      List<String> subjects = userDetails['subjects'].cast<String>();
      return Tutor.fromJson(userDetails);
    }
  } else {
    throw (response.reasonPhrase.toString());
  }
}

Future<Account> updateAccountDetails(int accountId,
    {String? firstName, String? lastName}) async {
  Map<String, String> queryParams = {'id': accountId.toString()};

  if (firstName != null && firstName != '') {
    queryParams['first_name'] = firstName;
  }
  if (lastName != null && lastName != '') {
    queryParams['last_name'] = lastName;
  }

  var headers = {'Content-Type': 'application/x-www-form-urlencoded'};
  var request = http.Request(
      'PATCH',
      Uri.parse('$ROOT_URL/accounts/users')
          .replace(queryParameters: queryParams));
  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();

  Map<String, dynamic> body =
      json.decode(await response.stream.bytesToString());
  if (response.statusCode != 200) {
    print(response.reasonPhrase);
    throw Exception(body);
  }

  return Account.fromJson(body);
}
