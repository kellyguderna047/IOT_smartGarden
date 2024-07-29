import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'PlantSelectionPage.dart';
import 'PlantWidgetPage.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  MyApp() {
    final initializationSettingsMacOS = DarwinInitializationSettings();
    final initializationSettings = InitializationSettings(
      macOS: initializationSettingsMacOS,
    );

    flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
    );

    // Call the function to check plant conditions on app startup
    checkPlantConditions();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart garden App',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => PlantWidgetPage(),
        '/selection': (context) => PlantSelectionPage(),
      },
    );
  }

  Future<void> sendNotification(int id, String title, String body) async {
    const macOSPlatformChannelSpecifics = DarwinNotificationDetails();
    const notificationDetails = NotificationDetails(
      macOS: macOSPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      id, // Use a unique ID for each notification
      title,
      body,
      notificationDetails,
    );
  }

  Future<void> checkPlantConditions() async {
    try {
      final response = await http.get(Uri.parse(
          'https://get-plants-current-data-rq6iz7nr2q-uc.a.run.app/'));
      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = jsonDecode(response.body);
        List<dynamic> plantList = responseData['data'];

        int notificationId = 0; // Start notification ID at 0

        if (responseData["water_tank"] <= 25) {
          sendNotification(notificationId++, 'Water Tank Alert',
              'The water tank is low on water');
        }

        for (int i = 0; i < plantList.length; i++) {
          if (plantList[i]["water"] == "Too wet") {
            sendNotification(
                notificationId++, 'Plant ${plantList[i]["name"]} Water Alert',
                'Too much water.');
          } else if (plantList[i]["water"] == "Too dry") {
            sendNotification(
                notificationId++, 'Plant ${plantList[i]["name"]} Water Alert',
                'Needs water.');
          }

          if (plantList[i]["light"] == "Too high") {
            sendNotification(
                notificationId++, 'Plant ${plantList[i]["name"]} Light Alert',
                'Too much light.');
          } else if (plantList[i]["light"] == "Too low") {
            sendNotification(
                notificationId++, 'Plant ${plantList[i]["name"]} Light Alert',
                'Needs more light.');
          }

          if (plantList[i]["temperature"] == "Too high") {
            sendNotification(notificationId++,
                'Plant ${plantList[i]["name"]} Temperature Alert', 'Too hot.');
          } else if (plantList[i]["temperature"] == "Too low") {
            sendNotification(notificationId++,
                'Plant ${plantList[i]["name"]} Temperature Alert', 'Too cold.');
          }
        }
      } else {
        throw Exception('Failed to load plants: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching plants: $e');
    }
  }
}