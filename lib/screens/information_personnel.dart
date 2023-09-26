import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:prototype_1/styles/colors.dart';
import 'package:prototype_1/widget/bottom_navbar.dart';
import 'package:prototype_1/widget/plain_button.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

class InformationPersonnel extends StatefulWidget {
  const InformationPersonnel({Key? key}) : super(key: key);

  @override
  State<InformationPersonnel> createState() => _InformationPersonnelState();
}

class _InformationPersonnelState extends State<InformationPersonnel> with SingleTickerProviderStateMixin {
  List<bool> isSelected = [true, false];

  @override
  void initState() {
    super.initState();
    fetchData(context);
  }

  Map<String, dynamic> dataInfo = {};
  Map<String, dynamic> dataHealth = {};

  Future<void> fetchDatas(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    const url =
        'https://dvpm9zw6vc.execute-api.eu-west-3.amazonaws.com/onboarding/grapghql';
    final token = prefs.getString('token');
    final uncodeToken = JWT.decode(token!);
    final id = uncodeToken.payload['id'];
    const headers = {
    'Content-Type': 'application/json',
    'User-Agent': 'insomnia/2023.5.8',
    'Edgar-Auth-Key': 'TWFydmluTGVQbHVzQmVhdURlTGFUZXJyZTwz',
    };
    final body = '{"query":"query getInfoBNyId($id: String!) {\\n\\tgetInfoById(id: $id) {\\n\\t\\tid\\n\\t\\tsurname\\n\\t\\tbirthdate\\n\\t\\tsex\\n\\t\\tweight\\n\\t\\theight\\n\\t}\\n}","operationName":"getInfoBNyId","variables":{"id":"6511f3c6455f0ef1c6312084"}}';

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: body,
    );

  }

  Future<void> fetchData(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final uncodeToken = JWT.decode(token!);
    final payload = uncodeToken.payload;
    final id = payload['patient']['id'];
    const url = 'https://dvpm9zw6vc.execute-api.eu-west-3.amazonaws.com/graphql';
    const headers = {
      'Content-Type': 'application/json',
      'Edgar-Auth-Key': 'TWFydmluTGVQbHVzQmVhdURlTGFUZXJyZTwz',
    };
    const query = 'query getInfoById(\$id: String!) { getInfoById(id: \$id) { id surname birthdate sex weight height } }';
    const operationName = 'getInfoById';
    final variables = jsonEncode({'id': '6511f3c6455f0ef1c6312084'});
    const queryHealth = 'query getHealthById(\$id: String!) { getHealthById(id: \$id) { id patients_treatments patients_allergies patients_illness } }';
    const operationNameHealth = 'getHealthById';
    final variablesHealth = jsonEncode({'id': '6511f44505a62680a7e63a78'});
    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode({
        'query': query,
        'operationName': operationName,
        'variables': jsonDecode(variables),
      }),
    );
    final responseHealth = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode({
        'query': queryHealth,
        'operationName': operationNameHealth,
        'variables': jsonDecode(variablesHealth),
      }),
    );

    if (response.statusCode == 200 && responseHealth.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      setState(() {
        dataInfo = responseData['data']['getInfoById'];
        dataHealth = jsonDecode(responseHealth.body)['data']['getHealthById'];
        populateInfoMedical();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to fetch data'),
        ),
      );
    }
  }

  Map<String, Object> infoMedical = {};

  void populateInfoMedical() {
    infoMedical = {
      'Nom': dataInfo['surname'] ?? 'Inconnu',
      'Sex': dataInfo['sex'].toString() ?? 'Inconnu',
      'Anniversaire': dataInfo['birthdate'] ?? 'Inconnu',
      'Taille': dataInfo['height'] ?? 'Inconnu',
      'Poids': dataInfo['weight'] ?? 'Inconnu',
      'Medecin_traitant': dataHealth['patients_primary_doctor'] ?? 'Inconnu',
      'Traitement_en_cours': 'Aucun',
      'Allergies': 'Aucune',
      'Maladies':  'Aucune',
    };
  }

    
    @override
    Widget cardInformation(BuildContext context) {
      return isSelected[1] 
        ? Card(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            color: AppColors.blue700, 
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32),
            ),
            child: Column(
              children: [
                ...infoMedical.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
                    child: Row(
                      children: <Widget>[
                        Text(
                          entry.key.replaceAll('_', ' '),
                          style: const TextStyle(color: Colors.white),
                        ),
                        const Text(
                          ':',
                          style: TextStyle(color: Colors.white),
                        ),
                        const Spacer(),
                        Text(
                          '${entry.value}',
                          style: const TextStyle(color: AppColors.green400),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                const SizedBox(height: 20),
                GreenPlainButton(
                  text: 'Modifier',
                  onPressed: () {},
                ),
                const SizedBox(height: 20),
              ],
            ),
          )
        : Container();
    }

  @override
   Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const BottomNavBar(
        index: 3,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.only(top: 50),
              width: 120,
              child: Image.asset('assets/images/logo/full-width-colored-edgar-logo.png'),
            ),
            const SizedBox(height: 20),
            ToggleButtons(
              constraints: BoxConstraints.tightFor(width: MediaQuery.of(context).size.width * 0.40),
              borderRadius: BorderRadius.circular(50),
              borderWidth: 1,
              borderColor: AppColors.blue700,
              color: AppColors.blue700,
              selectedColor: AppColors.blue700,
              hoverColor: AppColors.blue700,

              fillColor: AppColors.blue700,
              onPressed: (int index) {
                setState(() {
                  for (int buttonIndex = 0; buttonIndex < isSelected.length; buttonIndex++) {
                    if (buttonIndex == index) {
                      isSelected[buttonIndex] = true;
                    } else {
                      isSelected[buttonIndex] = false;
                    }
                  }
                });
              },
              isSelected: isSelected,
              children: <Widget>[
                Text(
                  'Information\nPersonnel', 
                  style: TextStyle(color: isSelected[0] ? Colors.white : AppColors.blue900, 
                  ),
                ),
                Text(
                  'Information\nMedical', 
                  style: TextStyle(color: isSelected[1] ? Colors.white : AppColors.blue900)
                ),
              ],
            ),
            const SizedBox(height: 20),
            cardInformation(context),
          ]
          ),
      )
    );
  }
}