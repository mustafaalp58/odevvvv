import 'package:flutter/material.dart';
import 'package:hava_durumu_app_v1/screens/loading_screen.dart';
import 'package:hava_durumu_app_v1/screens/main_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: LoadingScreen(),
    );
  }
}
import 'package:location/location.dart';

class LocationHelper{
  double latitude;
  double longitude;

  Future<void> getCurrentLocation() async{
    Location location = Location();

    bool _serviceEnabled;
    PermissionStatus _permissionGranted;
    LocationData _locationData;

    
    _serviceEnabled = await location.serviceEnabled();
    if(!_serviceEnabled){
      _serviceEnabled = await location.requestService();
      if(!_serviceEnabled){
        return;
      }
    }

    
    _permissionGranted = await location.hasPermission();
    if(_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();

      if(_permissionGranted!=PermissionStatus.granted){
        return;
      }
    }

    
    _locationData = await location.getLocation();
    latitude = _locationData.latitude;
    longitude = _locationData.longitude;

  }


}
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart';

import 'location.dart';

const apiKey = "************************************";

class WeatherDisplayData{
  Icon weatherIcon;
  AssetImage weatherImage;

  WeatherDisplayData({@required this.weatherIcon, this.weatherImage});
}


class WeatherData{
  WeatherData({@required this.locationData});

  LocationHelper locationData;
  double currentTemperature;
  int currentCondition;
  String city;

  Future<void> getCurrentTemperature() async{
    Response response = await get("http://api.openweathermap.org/data/2.5/weather?lat=${locationData.latitude}&lon=${locationData.longitude}&appid=${apiKey}&units=metric");
    
    if(response.statusCode == 200){
      String data = response.body;
      var currentWeather = jsonDecode(data);

      try{
        currentTemperature = currentWeather['main']['temp'];
        currentCondition = currentWeather['weather'][0]['id'];
        city = currentWeather['name'];
      }catch(e){
        print(e);
      }
      
    }
    else{
      print("API den değer gelmiyor!");
    }
    
  }

  WeatherDisplayData getWeatherDisplayData(){
    if(currentCondition <600){
      
      return WeatherDisplayData(
          weatherIcon: Icon(
        FontAwesomeIcons.cloud,
        size: 75.0,
        color:Colors.white
      ),
        weatherImage: AssetImage('assets/bulutlu.png'));
    }
    else{
      
      var now = new DateTime.now();
      if(now.hour >=19){
        return WeatherDisplayData(
            weatherIcon: Icon(
                FontAwesomeIcons.moon,
                size: 75.0,
                color:Colors.white
            ),
            weatherImage: AssetImage('assets/gece.png'));
      }else{
        return WeatherDisplayData(
            weatherIcon: Icon(
                FontAwesomeIcons.sun,
                size: 75.0,
                color:Colors.white
            ),
            weatherImage: AssetImage('assets/gunesli.png'));

      }
    }
  }


}
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hava_durumu_app_v1/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    
    await tester.pumpWidget(MyApp());

    
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:hava_durumu_app_v1/screens/main_screen.dart';
import 'package:hava_durumu_app_v1/utils/location.dart';
import 'package:hava_durumu_app_v1/utils/weather.dart';

class LoadingScreen extends StatefulWidget {
  @override
  _LoadingScreenState createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  LocationHelper locationData;
  Future<void> getLocationData() async{
    locationData = LocationHelper();
    await locationData.getCurrentLocation();

    if(locationData.latitude == null || locationData.longitude == null){
      print("Konum bilgileri gelmiyor.");

    }
    else{
      print("latitude: " + locationData.latitude.toString());
      print("longitude: " + locationData.longitude.toString());
    }

  }

  void getWeatherData() async {
    await getLocationData();

    WeatherData weatherData = WeatherData(locationData: locationData);
    await weatherData.getCurrentTemperature();

    if(weatherData.currentTemperature == null ||
    weatherData.currentCondition == null){
      print("API den sıcaklık veya durum bilgisi boş dönüyor.");
    }

    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context){
      return MainScreen(weatherData: weatherData,);
    }));


  }

  @override
  void initState() {
    
    super.initState();
    getWeatherData();

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.purple, Colors.blue]
          ),
        ),
        child: Center(
          child: SpinKitFadingCircle(
            color: Colors.white,
            size: 150.0,
            duration: Duration(milliseconds: 1200),
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hava_durumu_app_v1/utils/weather.dart';

class MainScreen extends StatefulWidget {

  final WeatherData weatherData;

  MainScreen({@required this.weatherData});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int temperature;
  Icon weatherDisplayIcon;
  AssetImage backgroundImage;
  String city;
  void updateDisplayInfo(WeatherData weatherData){
  setState(() {
    temperature = weatherData.currentTemperature.round();
    city = weatherData.city;
    WeatherDisplayData weatherDisplayData = weatherData.getWeatherDisplayData();
    backgroundImage = weatherDisplayData.weatherImage;
    weatherDisplayIcon = weatherDisplayData.weatherIcon;
  });
  }

  @override
  void initState() {
    
    super.initState();
    updateDisplayInfo(widget.weatherData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        constraints: BoxConstraints.expand(),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: backgroundImage,
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 40,),
            Container(
              child: weatherDisplayIcon,
            ),
            SizedBox(height: 15,),
            Center(
              child: Text('$temperature°',
              style: TextStyle(
                color: Colors.white,
                fontSize: 80.0,
                letterSpacing: -5
              ),
              ),
            ),
            SizedBox(height: 15,),
            Center(
              child: Text(city,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 50.0,
                    letterSpacing: -5
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

