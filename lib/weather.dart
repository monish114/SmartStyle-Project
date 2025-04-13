import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

String? weatherCondition;
int? temp;

const apiKey = 'enter user API';
const openWeatherMapURL = 'https://api.openweathermap.org/data/2.5/weather';

class WeatherModel {
  Future<dynamic> getCityWeather(String cityName) async {
    var url = '$openWeatherMapURL?q=$cityName&appid=$apiKey&units=metric';
    NetworkHelper networkHelper = NetworkHelper(url);
    var weatherData = await networkHelper.getData();
    return weatherData;
  }

  Future<dynamic> getlocationWeather() async {
    Location location = Location();
    await location.getCurrentLocation();

    NetworkHelper networkHelper = NetworkHelper(
        "$openWeatherMapURL?lat=${location.latitude}&lon=${location.longitude}&appid=$apiKey&units=metric");

    var weatherData = await networkHelper.getData();
    return weatherData;
  }

  String getWeatherCondition(var condition) {
    if (condition == 'Rain') {
      return 'Rain';
    } else if (condition == 'Rain') {
      return 'Rain';
    } else if (condition == 'Thunderstorm') {
      return 'Thunderstorm';
    } else if (condition == 'Snow') {
      return 'Snow';
    } else if (condition == 'Haze') {
      return 'Haze';
    } else if (condition == 'Clear') {
      return 'Clear';
    } else if (condition == 'Clouds') {
      return 'Clouds';
    } else {
      return 'ENTER CORRECT LOCATION';
    }
  }
}

class NetworkHelper {
  NetworkHelper(this.url);
  final String url;

  Future getData() async {
    try {
      http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var decodedData = jsonDecode(response.body);
        return decodedData;
      } else {
        print("Failed to fetch weather data: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Error fetching weather data: $e");
      return null;
    }
  }
}

class Location {
  double? latitude;
  double? longitude;

  Future<void> getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.deniedForever) {
          print("Location permissions are permanently denied. Please enable them in settings.");
          return;
        }
      }
      if (permission == LocationPermission.denied) {
        print("Location permission denied.");
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best);

      latitude = position.latitude;
      longitude = position.longitude;
      print("Location: $latitude, $longitude"); // Debugging purpose
    } catch (e) {
      print("Error getting location: $e");
    }
  }
}



class CityScreen extends StatefulWidget {
  @override
  _CityScreenState createState() => _CityScreenState();
}

class _CityScreenState extends State<CityScreen> {
  late String cityName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Align(
                alignment: Alignment.topLeft,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Icon(
                    Icons.arrow_circle_left_sharp,
                    color: Colors.blue,
                    size: 50.0,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.all(20.0),
                child: TextField(
                  style: TextStyle(
                    color: Colors.black,
                  ),
                  onChanged: (value) {
                    cityName = value;
                  },
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context, cityName);
                },
                child: Text(
                  'Get Weather',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LocationScreen extends StatefulWidget {
  LocationScreen({this.locationWeather, this.networkHelper});
  final locationWeather;
  final networkHelper;
  @override
  _LocationScreenState createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  WeatherModel weather = WeatherModel();
  String? cityName;
  String? weatherMessage;

  @override
  @override
  void initState() {
    super.initState();
    if (widget.locationWeather == null) {
      getLiveLocationWeather();
    } else {
      updateUi(widget.locationWeather);
    }
  }

  void getLiveLocationWeather() async {
    var weatherData = await weather.getlocationWeather();
    updateUi(weatherData);
  }


  void updateUi(dynamic weatherData) {
    setState(() {
      if (weatherData == null) {
        temp = 0;
        weatherCondition = 'error';
        weatherMessage = 'Unable to get weather data';
        cityName = '';
        return;
      }
      double temperature = weatherData['main']['temp'];
      temp = temperature.toInt();
      var condition = weatherData['weather'][0]['main'];
      cityName = weatherData['name'];
      weatherCondition = weather.getWeatherCondition(condition);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.blue[550], // Blue background
        borderRadius: BorderRadius.circular(15), // Rounded corners
      ),
      padding: EdgeInsets.all(20), // Padding inside the box
      margin: EdgeInsets.all(10), // Space around the box
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Align(
              alignment: Alignment.center,
              child: TextButton(
                onPressed: () async {
                  var typedName = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return CityScreen();
                      },
                    ),
                  );
                  if (typedName != null) {
                    var weatherData = await weather.getCityWeather(typedName);
                    updateUi(weatherData);
                  }
                },
                child: Text(
                  "Today's Weather Data",
                  style: TextStyle(color: Colors.white, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(10.0),
              child: Text(
                "$weatherCondition and $temp °C In $cityName!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white, // White text
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WeatherInfoWidget extends StatelessWidget {
  final String? weatherCondition;

  WeatherInfoWidget({this.weatherCondition});

  @override
  Widget build(BuildContext context) {
    return Text(
      weatherCondition?.trim() ?? "Null",
    );
  }
}

