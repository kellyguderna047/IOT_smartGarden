import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';

class PlantSelectionPage extends StatefulWidget {
  @override
  _PlantSelectionPageState createState() => _PlantSelectionPageState();
}

class _PlantSelectionPageState extends State<PlantSelectionPage> {
  List<String> plants = []; // List to store plant names
  List<Map<String, dynamic>> selectedPlants = []; // List to store selected plants with possible null values

  @override
  void initState() {
    super.initState();
    fetchPlants();
  }

  void submitPlants() async {
    try {
      const String url = 'https://set-selected-plants-rq6iz7nr2q-uc.a.run.app';

      final response = await http.post(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(selectedPlants),
      );
      if (response.statusCode == 200) {
        setState(() {});
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      } else {
        print('Failed to submit plants: ${response.statusCode}');
      }
    } catch (e) {
      print('Error submitting plants: $e');
    }
  }

  Future<void> fetchPlants() async {
    try {
      final response = await http.get(Uri.parse('https://get-all-plants-rq6iz7nr2q-uc.a.run.app/'));
      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = jsonDecode(response.body);
        List<String> plantNames = List<String>.from(responseData['data']);
        List<Map<String, dynamic>> selected = List<Map<String, dynamic>>.from(responseData['selected']);
        setState(() {
          plants = plantNames;
          selectedPlants = selected;
        });
      } else {
        throw Exception('Failed to load plants: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching plants: $e');
    }
  }

  void addPlant() {
    setState(() {
      int? nullIndex = selectedPlants.indexWhere((element) => element["name"] == null);
      if (nullIndex != -1) {
        selectedPlants[nullIndex]["name"] = plants.isNotEmpty ? plants[0] : '';
        selectedPlants[nullIndex]["waterOnlyAtNight"] = false;
        selectedPlants[nullIndex]["waterByWeather"] = false;
      } else {
        selectedPlants.add({
          "name": plants.isNotEmpty ? plants[0] : '',
          "pump": true,
          "waterOnlyAtNight": false,
          "waterByWeather": false,
        });
      }
    });
  }

  void removePlant(int index) {
    setState(() {
      selectedPlants[index]["name"] = null;
      selectedPlants[index]["pump"] = null;
      selectedPlants[index]["waterOnlyAtNight"] = null;
      selectedPlants[index]["waterByWeather"] = null;
    });
  }

  void removeRow(int index) {
    setState(() {
      selectedPlants.removeAt(index);
    });
  }

  void _addNewPlant() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (BuildContext context) {
        return _AddPlantDialog(plants: plants);
      },
    );

    if (result != null) {
      try {
        final response = await http.post(
          Uri.parse('https://add-new-plant-rq6iz7nr2q-uc.a.run.app'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(result),
        );

        if (response.statusCode == 200) {
          setState(() {
            plants.add(result["name"]!);
          });
        } else {
          throw Exception('Failed to add plant: ${response.statusCode}');
        }
      } catch (e) {
        print('Error adding new plant: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Plants'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Titles Row
            Row(
              children: [
                Expanded(
                  flex: 7,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      'Plant Type',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      'Automatic \n Watering',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      'Water\n Only \n at Night',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      'Water by \n Weather',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            // Plant selection list
            Expanded(
              child: ListView.builder(
                itemCount: selectedPlants.length,
                itemBuilder: (context, index) {
                  String? currentValue = selectedPlants[index]["name"];
                  bool isAutomaticWatering = selectedPlants[index]["pump"] ?? false;
                  bool waterOnlyAtNight = selectedPlants[index]["waterOnlyAtNight"] ?? false;
                  bool waterByWeather = selectedPlants[index]["waterByWeather"] ?? false;

                  return Row(
                    children: [
                      Expanded(
                        flex: 10,
                        child: DropdownButtonFormField<String>(
                          value: currentValue,
                          onChanged: (newValue) {
                            setState(() {
                              selectedPlants[index]["name"] = newValue;
                            });
                          },
                          items: plants.map((plant) {
                            return DropdownMenuItem<String>(
                              value: plant,
                              child: Text(plant),
                            );
                          }).toList(),
                          decoration: InputDecoration(labelText: 'Select Plant ${index + 1}'),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Checkbox(
                          value: isAutomaticWatering,
                          onChanged: (bool? value) {
                            setState(() {
                              selectedPlants[index]["pump"] = value ?? false;
                            });
                          },
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Checkbox(
                          value: waterOnlyAtNight,
                          onChanged: (bool? value) {
                            setState(() {
                              selectedPlants[index]["waterOnlyAtNight"] = value ?? false;
                            });
                          },
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Checkbox(
                          value: waterByWeather,
                          onChanged: (bool? value) {
                            setState(() {
                              selectedPlants[index]["waterByWeather"] = value ?? false;
                            });
                          },
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.remove_circle),
                        onPressed: () {
                          removePlant(index);
                        },
                      ),
                      if (index == selectedPlants.length - 1)
                        IconButton(
                          icon: Icon(Icons.delete_forever),
                          onPressed: () {
                            removeRow(index);
                          },
                        ),
                    ],
                  );
                },
              ),
            ),
            // Buttons
            ElevatedButton(
              onPressed: addPlant,
              child: Text('Add Plant'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _addNewPlant,
              child: Text('Add New Plant'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: submitPlants,
              child: Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddPlantDialog extends StatefulWidget {
  final List<String> plants;

  _AddPlantDialog({required this.plants});

  @override
  __AddPlantDialogState createState() => __AddPlantDialogState();
}

class __AddPlantDialogState extends State<_AddPlantDialog> {
  String plantName = '';
  String waterAmount = 'normal amount of water';
  String lightAmount = 'normal amount of light';
  String temperature = 'normal temperature';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add New Plant'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(labelText: 'Plant Name'),
              onChanged: (value) {
                setState(() {
                  plantName = value;
                });
              },
            ),
            DropdownButtonFormField<String>(
              value: waterAmount,
              onChanged: (value) {
                setState(() {
                  waterAmount = value!;
                });
              },
              items: [
                DropdownMenuItem(
                  child: Text('Small amount of water'),
                  value: 'small amount of water',
                ),
                DropdownMenuItem(
                  child: Text('Normal amount of water'),
                  value: 'normal amount of water',
                ),
                DropdownMenuItem(
                  child: Text('Large amount of water'),
                  value: 'large amount of water',
                ),
              ],
              decoration: InputDecoration(labelText: 'Water Amount'),
            ),
            DropdownButtonFormField<String>(
              value: lightAmount,
              onChanged: (value) {
                setState(() {
                  lightAmount = value!;
                });
              },
              items: [
                DropdownMenuItem(
                  child: Text('Small amount of light'),
                  value: 'small amount of light',
                ),
                DropdownMenuItem(
                  child: Text('Normal amount of light'),
                  value: 'normal amount of light',
                ),
                DropdownMenuItem(
                  child: Text('Large amount of light'),
                  value: 'large amount of light',
                ),
              ],
              decoration: InputDecoration(labelText: 'Light Amount'),
            ),
            DropdownButtonFormField<String>(
              value: temperature,
              onChanged: (value) {
                setState(() {
                  temperature = value!;
                });
              },
              items: [
                DropdownMenuItem(
                  child: Text('Cool temperature'),
                  value: 'cool temperature',
                ),
                DropdownMenuItem(
                  child: Text('Normal temperature'),
                  value: 'normal temperature',
                ),
                DropdownMenuItem(
                  child: Text('Warm temperature'),
                  value: 'warm temperature',
                ),
              ],
              decoration: InputDecoration(labelText: 'Temperature'),
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop({
              'name': plantName,
              'water': waterAmount,
              'light': lightAmount,
              'temperature': temperature,
            });
          },
          child: Text('Add Plant'),
        ),
      ],
    );
  }
}
