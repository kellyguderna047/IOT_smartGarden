import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class PlantWidget extends StatelessWidget {
  final String plantName;
  final String waterLevel;
  final String temperatureLevel;
  final String lightLevel;
  final int index;

  PlantWidget({
    required this.plantName,
    required this.waterLevel,
    required this.temperatureLevel,
    required this.lightLevel,
    required this.index,
  });

  Color getCircleColor(String level) {
    switch (level) {
      case "Too low":
        return Colors.red;
      case "Good":
        return Colors.green;
      case "Too high":
        return Colors.yellow.shade600;
      case "Too dry":
        return Colors.red;
      case "Too wet":
        return Colors.yellow.shade600;
      default:
        return Colors.grey;
    }
  }

  Future<void> sendWateringCommand(int pumpIndex) async {
    const String url = 'https://send-pump-commend-rq6iz7nr2q-uc.a.run.app'; // Replace with your URL

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({'pump_index': pumpIndex}),
      );

      if (response.statusCode == 200) {
        print('Pump command sent successfully');
      } else {
        print('Failed to send pump command: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending pump command: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(10),
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              plantName,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                _buildParameterCircle('Water', waterLevel),
                _buildParameterCircle('Temperature', temperatureLevel),
                _buildParameterCircle('Light', lightLevel),
                _buildPopupButton(context, index),
              ],
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => sendWateringCommand(index),
              child: Text('Water Plant'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParameterCircle(String parameter, String level) {
    return Column(
      children: <Widget>[
        CircleAvatar(
          radius: 35,
          backgroundColor: getCircleColor(level),
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

  Widget _buildPopupButton(BuildContext context, int index) {
    return GestureDetector(
      onTap: () async {
        try {
          final response = await http.get(Uri.parse('https://get-statistics-rq6iz7nr2q-uc.a.run.app/'));

          if (response.statusCode == 200) {
            List<dynamic> data = jsonDecode(response.body)['data'];
            List<PlantStatistics> plantStatisticsList = [];

            for (int i = 0; i < data.length; i++) {
              List<dynamic> waterData = data[i]["water"];
              List<dynamic> temperatureData = data[i]["temperature"];
              List<dynamic> lightData = data[i]["light"];

              List<FlSpot> waterSpots = [];
              List<FlSpot> temperatureSpots = [];
              List<FlSpot> lightSpots = [];

              for (int j = 0; j < waterData.length; j++) {
                double timestamp = double.parse(waterData[j][0]);
                double value = waterData[j][1].toDouble();
                waterSpots.add(FlSpot(timestamp, value));
              }

              for (int j = 0; j < temperatureData.length; j++) {
                double timestamp = double.parse(temperatureData[j][0]);
                double value = temperatureData[j][1].toDouble();
                temperatureSpots.add(FlSpot(timestamp, value));
              }

              for (int j = 0; j < lightData.length; j++) {
                double timestamp = double.parse(lightData[j][0]);
                double value = lightData[j][1].toDouble();
                lightSpots.add(FlSpot(timestamp, value));
              }

              plantStatisticsList.add(PlantStatistics(
                waterSpots: waterSpots,
                waterMin: data[i]["water_min"].toDouble(),
                waterMax: data[i]["water_max"].toDouble(),
                temperatureSpots: temperatureSpots,
                temperatureMin: data[i]["temperature_min"].toDouble(),
                temperatureMax: data[i]["temperature_max"].toDouble(),
                lightSpots: lightSpots,
                lightMin: data[i]["light_min"].toDouble(),
                lightMax: data[i]["light_max"].toDouble(),
              ));
            }

            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('Last Week Statistics'),
                  content: Container(
                    width: double.maxFinite,
                    height: 400,
                    child: DefaultTabController(
                      length: 3,
                      child: Column(
                        children: <Widget>[
                          TabBar(
                            tabs: [
                              Tab(text: "Water"),
                              Tab(text: "Temperature"),
                              Tab(text: "Light"),
                            ],
                          ),
                          Expanded(
                            child: TabBarView(
                              children: [
                                _buildGraph(plantStatisticsList[index].waterSpots, Colors.blue, plantStatisticsList[index].waterMin, plantStatisticsList[index].waterMax),
                                _buildGraph(plantStatisticsList[index].temperatureSpots, Colors.red, plantStatisticsList[index].temperatureMin, plantStatisticsList[index].temperatureMax),
                                _buildGraph(plantStatisticsList[index].lightSpots, Colors.green, plantStatisticsList[index].lightMin, plantStatisticsList[index].lightMax),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: <Widget>[
                    TextButton(
                      child: Text('Close'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                );
              },
            );
          } else {
            throw Exception('Failed to load statistics: ${response.statusCode}');
          }
        } catch (e) {
          print('Error fetching statistics: $e');
          // Handle error as needed
        }
      },
      child: Column(
        children: <Widget>[
          CircleAvatar(
            radius: 35,
            backgroundColor: Colors.blue,
            child: Icon(
              Icons.info,
              color: Colors.white,
              size: 30,
            ),
          ),
          SizedBox(height: 5),
          Text('Statistics'),
        ],
      ),
    );
  }

  Widget _buildGraph(List<FlSpot> spots, Color color, double minValue, double maxValue) {
    if (spots.isEmpty) {
      return Center(child: Text("No data available"));
    }

    return LineChart(
      LineChartData(
        titlesData: FlTitlesData(
          show: true,
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 80,
              getTitlesWidget: (value, meta) {
                DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(value.toInt() * 1000);
                final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm');
                final String formatted = formatter.format(dateTime);
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      formatted,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  angle: 45,
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    value.toString(),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: const Color(0xff37434d), width: 1),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false, // Set to false for linear lines
            color: color,
            barWidth: 4,
            isStrokeCapRound: true,
            belowBarData: BarAreaData(show: false),
          ),
          LineChartBarData(
            spots: [
              FlSpot(spots.first.x, minValue),
              FlSpot(spots.last.x, minValue),
            ],
            isCurved: false,
            color: color.withOpacity(0.5),
            barWidth: 2,
            isStrokeCapRound: true,
            belowBarData: BarAreaData(show: false),
            dotData: FlDotData(show: false),
            dashArray: [5, 5],
          ),
          LineChartBarData(
            spots: [
              FlSpot(spots.first.x, maxValue),
              FlSpot(spots.last.x, maxValue),
            ],
            isCurved: false,
            color: color.withOpacity(0.5),
            barWidth: 2,
            isStrokeCapRound: true,
            belowBarData: BarAreaData(show: false),
            dotData: FlDotData(show: false),
            dashArray: [5, 5],
          ),
        ],
      ),
    );
  }
}

class PlantStatistics {
  final List<FlSpot> waterSpots;
  final double waterMin;
  final double waterMax;
  final List<FlSpot> temperatureSpots;
  final double temperatureMin;
  final double temperatureMax;
  final List<FlSpot> lightSpots;
  final double lightMin;
  final double lightMax;

  PlantStatistics({
    required this.waterSpots,
    required this.waterMin,
    required this.waterMax,
    required this.temperatureSpots,
    required this.temperatureMin,
    required this.temperatureMax,
    required this.lightSpots,
    required this.lightMin,
    required this.lightMax,
  });
}