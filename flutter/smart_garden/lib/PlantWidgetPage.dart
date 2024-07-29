import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io'; // Needed for File handling
import 'package:file_picker/file_picker.dart';
import 'PlantWidget.dart';

class PlantWidgetPage extends StatefulWidget {
  @override
  _PlantWidgetPageState createState() => _PlantWidgetPageState();
}

class _PlantWidgetPageState extends State<PlantWidgetPage> {
  List<Map<String, dynamic>> plantData = [];
  double waterTank = 0.0;
  Timer? _timer;
  File? _image;
  String _resultText = ''; // Variable to hold the result text
  bool _showResult = false; // Variable to control the visibility of the result overlay

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Duration(seconds: 3), (timer) {
      fetchPlants();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> fetchPlants() async {
    try {
      final response = await http.get(Uri.parse('https://get-plants-current-data-rq6iz7nr2q-uc.a.run.app/'));
      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = jsonDecode(response.body);
        List<dynamic> plantList = responseData['data'];
        setState(() {
          plantData = List<Map<String, dynamic>>.from(plantList);
          waterTank = responseData["water_tank"];
        });
      } else {
        throw Exception('Failed to load plants: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching plants: $e');
    } finally {
      setState(() {
        if (plantData.isEmpty) {
          Navigator.pushReplacementNamed(context, '/selection');
        }
      });
    }
  }

  Future<void> _pickImage() async {
    File? file = null;
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      file = File(result.files.single.path!);
    } else {
      file = null;
    }
    setState(() {
      if (file != null) {
        _image = file;
      } else {
        print('No image selected.');
      }
    });
  }

  Future<void> _sendImageToServer(BuildContext context) async {
    if (_image == null) return;

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('https://arpy8-plant-detection-api.hf.space/predict'),
    );
    request.files.add(await http.MultipartFile.fromPath('file', _image!.path));

    var response = await request.send();

    if (response.statusCode == 200) {
      var responseBody = await response.stream.bytesToString();
      setState(() {
        _resultText = responseBody;
        _showResult = true; // Show the result overlay
      });
    } else {
      setState(() {
        _resultText = 'Failed to predict the disease.';
        _showResult = true; // Show the result overlay
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Selected Plants'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/selection');
          },
        ),
      ),
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: plantData.length >= 1
                    ? ListView.builder(
                  itemCount: plantData.length,
                  itemBuilder: (context, index) {
                    Map<String, dynamic> plant = plantData[index];
                    return PlantWidget(
                      plantName: plant['name'] ?? 'Unknown',
                      lightLevel: plant['light'] ?? 'Unknown',
                      temperatureLevel: plant['temperature'] ?? 'Unknown',
                      waterLevel: plant['water'] ?? 'Unknown',
                      index: index,
                    );
                  },
                )
                    : Center(child: Text('')),
              ),
              SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildParameterCircleWaterTank('Water tank', waterTank),
                    _buildAIButton(context),
                  ],
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
          if (_showResult)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: Container(
                    margin: EdgeInsets.all(20),
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Stack(
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'AI Prediction Result',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 10),
                            Text(
                              _resultText,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                        Positioned(
                          top: 10,
                          right: 20, // Adjusted right position to move "x" further right
                          child: IconButton(
                            icon: Icon(Icons.close),
                            onPressed: () {
                              setState(() {
                                _showResult = false; // Hide the result overlay
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color getCircleColor(double level) {
    if (level <= 20) {
      return Colors.red;
    } else if (level <= 40) {
      return Colors.yellow;
    } else {
      return Colors.green;
    }
  }

  Widget _buildParameterCircleWaterTank(String parameter, double level) {
    return Column(
      children: <Widget>[
        CircleAvatar(
          backgroundColor: getCircleColor(level),
          radius: 40,
          child: Text(
            '$level',
            style: TextStyle(color: Colors.white, fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: 5),
        Text(parameter),
      ],
    );
  }

  Widget _buildAIButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        _showImageUploadOptions(context);
      },
      child: Column(
        children: <Widget>[
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.grey,
            child: Text(
              'Click to check',
              style: TextStyle(color: Colors.white, fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 5),
          Text('AI'),
        ],
      ),
    );
  }

  void _showImageUploadOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Upload or Drag and Drop Image'),
              SizedBox(height: 20),
              DragTarget<File>(
                onAccept: (file) async {
                  setState(() {
                    _image = file;
                  });
                  if (_image != null) {
                    await _sendImageToServer(context);
                  }
                },
                builder: (context, candidateData, rejectedData) {
                  return Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: Center(
                      child: Text(
                        'Drag and Drop Image Here\nOr Select from Files',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  await _pickImage();
                  if (_image != null) {
                    await _sendImageToServer(context);
                  }
                  Navigator.pop(context);
                },
                child: Text('Select from Files'),
              ),
            ],
          ),
        );
      },
    );
  }
}
