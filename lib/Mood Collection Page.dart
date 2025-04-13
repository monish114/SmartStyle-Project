import 'dart:io';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'weather.dart';
import 'Home Page.dart';
import 'User Page.dart' as UserPage;
import 'User Page.dart';

class MoodCollectionPage extends StatefulWidget {
  final String mood;

  const MoodCollectionPage({Key? key, required this.mood}) : super(key: key);

  @override
  _MoodCollectionPageState createState() => _MoodCollectionPageState();
}

class _MoodCollectionPageState extends State<MoodCollectionPage> {
  final databaseRef = FirebaseDatabase.instance.ref().child('clothing_items');
  final random = Random();

  List<Map<String, dynamic>> moodBasedClothingItems = [];
  List<List<Map<String, dynamic>>> outfitSuggestions = []; // Store two outfit suggestions
  bool _isLoading = true;
  String _errorMessage = '';
  String _detectedMood = '';

  List<String> sadColors = [];
  List<String> happyColors = [];
  List<String> angryColors = [];

  @override
  void initState() {
    super.initState();
    _fetchUserColorPreferences();
  }

  // New method to fetch user color preferences
  Future<void> _fetchUserColorPreferences() async {
    try {
      // Get the current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'User not authenticated';
        });
        return;
      }

      DatabaseReference userPrefsRef = FirebaseDatabase.instance.ref().child("user_preferences").child(user.uid);

      DataSnapshot snapshot = await userPrefsRef.get();
      if (snapshot.exists) {
        Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;

        setState(() {
          sadColors = List<String>.from(data['sadColors'] ?? UserPage.sadColors);
          happyColors = List<String>.from(data['happyColors'] ?? UserPage.happyColors);
          angryColors = List<String>.from(data['angryColors'] ?? UserPage.angryColors);

          if (sadColors.isEmpty) sadColors = ['Navy', 'Dark Blue', 'Blue'];
          if (happyColors.isEmpty) happyColors = ['Yellow', 'Orange', 'Khaki'];
          if (angryColors.isEmpty) angryColors = ['Red', 'Black', 'Dark Red'];
        });
      } else {

        setState(() {
          sadColors = List<String>.from(UserPage.sadColors);
          happyColors = List<String>.from(UserPage.happyColors);
          angryColors = List<String>.from(UserPage.angryColors);

          if (sadColors.isEmpty) sadColors = ['Navy', 'Dark Blue', 'Blue'];
          if (happyColors.isEmpty) happyColors = ['Yellow', 'Orange', 'Khaki'];
          if (angryColors.isEmpty) angryColors = ['Red', 'Black', 'Dark Red'];
        });
      }

      _loadMoodBasedClothingItems();

    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching color preferences: ${e.toString()}';
        _isLoading = false;
      });
      print('Error fetching color preferences: ${e.toString()}');

      sadColors = ['Silver', 'Blue', 'Grey'];
      happyColors = ['Yellow', 'Orange', 'Pink'];
      angryColors = ['Red', 'Black', 'Dark Red'];
      _loadMoodBasedClothingItems();
    }
  }

  Future<void> _loadMoodBasedClothingItems() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return;
      }

      DatabaseReference databaseRef = FirebaseDatabase.instance.ref().child("clothing_items");

      databaseRef.orderByChild("userId").equalTo(user.uid).onValue.listen((event) {
        if (event.snapshot.value != null) {
          setState(() {
            moodBasedClothingItems = [];
          });

          final data = Map<String, dynamic>.from(event.snapshot.value as Map);
          // Process the data...

          String mood = widget.mood.trim().toLowerCase();
          print("Fetched weather condition: $weatherCondition");

          List<String> recommendedTopColors = [];
          List<String> recommendedTopCloths = [];
          String recommendedPantColor = '';

          if (mood == 'sad' && weatherCondition == "Clear") {
            if (lightColors.any((color) => sadColors.contains(color))) {
              recommendedPantColor = lightPantColors[random.nextInt(lightPantColors.length)]; // Select a color from the list
            }
            else if (darkColors.any((color) => sadColors.contains(color))) {
              recommendedPantColor = darkPantColors[random.nextInt(darkPantColors.length)]; // Select a color from the list
            }
            else {
              recommendedPantColor = 'Black';
            }
            print("Recommended Colors: $recommendedTopColors");
            recommendedTopCloths = ['T-Shirt','T Shirt'];
            _detectedMood = 'Sad';
          } else if (mood == 'sad' && weatherCondition == "Clear" && temp! <= 17) {
            if (lightColors.any((color) => sadColors.contains(color))) {
              recommendedPantColor = lightPantColors[random.nextInt(lightPantColors.length)]; // Select a color from the list
            }
            else if (darkColors.any((color) => sadColors.contains(color))) {
              recommendedPantColor = darkPantColors[random.nextInt(darkPantColors.length)]; // Select a color from the list
            }
            else {
              recommendedPantColor = 'Black';
            }
            print("Recommended Colors: $recommendedTopColors");
            recommendedTopCloths = ['Hoodie', 'T-Shirt', 'T Shirt'];
            _detectedMood = 'Sad';
          } else if (mood == 'sad' && weatherCondition == "Clouds") {
            if (lightColors.any((color) => sadColors.contains(color))) {
              recommendedPantColor = lightPantColors[random.nextInt(lightPantColors.length)]; // Select a color from the list
            }
            else if (darkColors.any((color) => sadColors.contains(color))) {
              recommendedPantColor = darkPantColors[random.nextInt(darkPantColors.length)]; // Select a color from the list
            }
            else {
              recommendedPantColor = 'Black';
            }
            recommendedTopCloths = ['Hoodie', 'T-Shirt', 'T Shirt'];
            _detectedMood = 'Sad';
          } else if (mood == 'sad' && weatherCondition == "Haze") {
            if (lightColors.any((color) => sadColors.contains(color))) {
              recommendedPantColor = lightPantColors[random.nextInt(lightPantColors.length)]; // Select a color from the list
            }
            else if (darkColors.any((color) => sadColors.contains(color))) {
              recommendedPantColor = darkPantColors[random.nextInt(darkPantColors.length)]; // Select a color from the list
            }
            else {
              recommendedPantColor = 'Black';
            }
            recommendedTopCloths = ['T-Shirt', 'T Shirt', 'Hoodie'];
            _detectedMood = 'Sad';
          } else if (mood == 'sad' && weatherCondition == "Rain") {
            if (lightColors.any((color) => sadColors.contains(color))) {
              recommendedPantColor = lightPantColors[random.nextInt(lightPantColors.length)]; // Select a color from the list
            }
            else if (darkColors.any((color) => sadColors.contains(color))) {
              recommendedPantColor = darkPantColors[random.nextInt(darkPantColors.length)]; // Select a color from the list
            }
            else {
              recommendedPantColor = 'Black';
            }
            recommendedTopCloths = ['Hoodie', 'Jacket', 'T-Shirt', 'T Shirt'];
            _detectedMood = 'Sad';
          } else if (mood == 'sad' && weatherCondition == "Thunderstorm") {
            if (lightColors.any((color) => sadColors.contains(color))) {
              recommendedPantColor = lightPantColors[random.nextInt(lightPantColors.length)]; // Select a color from the list
            }
            else if (darkColors.any((color) => sadColors.contains(color))) {
              recommendedPantColor = darkPantColors[random.nextInt(darkPantColors.length)]; // Select a color from the list
            }
            else {
              recommendedPantColor = 'Black';
            }
            recommendedTopCloths = ['Hoodie', 'T-Shirt', 'Jacket'];
            _detectedMood = 'Sad';
          } else if (mood == 'sad' && weatherCondition == "Snow") {
            if (lightColors.any((color) => sadColors.contains(color))) {
              recommendedPantColor = lightPantColors[random.nextInt(lightPantColors.length)]; // Select a color from the list
            }
            else if (darkColors.any((color) => sadColors.contains(color))) {
              recommendedPantColor = darkPantColors[random.nextInt(darkPantColors.length)]; // Select a color from the list
            }
            else {
              recommendedPantColor = 'Black';
            }
            recommendedTopCloths = ['Hoodie', 'Jacket'];
            _detectedMood = 'Sad';
          } else if (mood == 'happy' && weatherCondition == "Clouds") {
            if (lightColors.any((color) => happyColors.contains(color))) {
              recommendedPantColor = lightPantColors[random.nextInt(lightPantColors.length)]; // Select a color from the list
            }
            else if (darkColors.any((color) => happyColors.contains(color))) {
              recommendedPantColor = darkPantColors[random.nextInt(darkPantColors.length)]; // Select a color from the list
            }
            else {
              recommendedPantColor = 'Black';
            }
            recommendedTopCloths = ['Hoodie', 'T-Shirt', 'T Shirt'];
            _detectedMood = 'Happy';
          } else if (mood == 'happy' && weatherCondition == "Clear") {
            if (lightColors.any((color) => happyColors.contains(color))) {
              recommendedPantColor = lightPantColors[random.nextInt(lightPantColors.length)]; // Select a color from the list
            }
            else if (darkColors.any((color) => happyColors.contains(color))) {
              recommendedPantColor = darkPantColors[random.nextInt(darkPantColors.length)]; // Select a color from the list
            }
            else {
              recommendedPantColor = 'Black';
            }
            print("Recommended Colors: $recommendedTopColors");
            recommendedTopCloths = ['T-Shirt', 'T Shirt'];
            _detectedMood = 'Happy';
          } else if (mood == 'happy' && weatherCondition == "Clear" && temp! <= 17) {
            if (lightColors.any((color) => happyColors.contains(color))) {
              recommendedPantColor = lightPantColors[random.nextInt(lightPantColors.length)]; // Select a color from the list
            }
            else if (darkColors.any((color) => happyColors.contains(color))) {
              recommendedPantColor = darkPantColors[random.nextInt(darkPantColors.length)]; // Select a color from the list
            }
            else {
              recommendedPantColor = 'Black';
            }
            print("Recommended Colors: $recommendedTopColors");
            recommendedTopCloths = ['T-Shirt','Hoodie', 'T Shirt'];
            _detectedMood = 'Happy';
          } else if (mood == 'happy' && weatherCondition == "Thunderstorm") {
            if (lightColors.any((color) => happyColors.contains(color))) {
              recommendedPantColor = lightPantColors[random.nextInt(lightPantColors.length)]; // Select a color from the list
            }
            else if (darkColors.any((color) => happyColors.contains(color))) {
              recommendedPantColor = darkPantColors[random.nextInt(darkPantColors.length)]; // Select a color from the list
            }
            else {
              recommendedPantColor = 'Black';
            }
            recommendedTopCloths = ['Hoodie', 'T-Shirt', 'T Shirt'];
            _detectedMood = 'Happy';
          } else if (mood == 'happy' && weatherCondition == "Haze") {
            if (lightColors.any((color) => happyColors.contains(color))) {
              recommendedPantColor = lightPantColors[random.nextInt(lightPantColors.length)]; // Select a color from the list
            }
            else if (darkColors.any((color) => happyColors.contains(color))) {
              recommendedPantColor = darkPantColors[random.nextInt(darkPantColors.length)]; // Select a color from the list
            }
            else {
              recommendedPantColor = 'Black';
            }
            recommendedTopCloths = ['T-Shirt', 'T Shirt'];
            _detectedMood = 'Happy';
          } else if (mood == 'happy' && weatherCondition == "Rain") {
            if (lightColors.any((color) => happyColors.contains(color))) {
              recommendedPantColor = lightPantColors[random.nextInt(lightPantColors.length)]; // Select a color from the list
            }
            else if (darkColors.any((color) => happyColors.contains(color))) {
              recommendedPantColor = darkPantColors[random.nextInt(darkPantColors.length)]; // Select a color from the list
            }
            else {
              recommendedPantColor = 'Black';
            }
            recommendedTopCloths = ['Hoodie', 'Jacket', 'T-Shirt', 'T Shirt'];
            _detectedMood = 'Happy';
          } else if (mood == 'happy' && weatherCondition == "Snow") {
            if (lightColors.any((color) => happyColors.contains(color))) {
              recommendedPantColor = lightPantColors[random.nextInt(lightPantColors.length)]; // Select a color from the list
            }
            else if (darkColors.any((color) => happyColors.contains(color))) {
              recommendedPantColor = darkPantColors[random.nextInt(darkPantColors.length)]; // Select a color from the list
            }
            else {
              recommendedPantColor = 'Black';
            }
            recommendedTopCloths = ['Hoodie', 'Jacket'];
            _detectedMood = 'Happy';
          } else if (mood == 'angry' && weatherCondition == "Snow") {
            if (lightColors.any((color) => angryColors.contains(color))) {
              recommendedPantColor = lightPantColors[random.nextInt(lightPantColors.length)]; // Select a color from the list
            }
            else if (darkColors.any((color) => angryColors.contains(color))) {
              recommendedPantColor = darkPantColors[random.nextInt(darkPantColors.length)]; // Select a color from the list
            }
            else {
              recommendedPantColor = 'Black';
            }
            recommendedTopCloths = ['Hoodie', 'Jacket'];
            _detectedMood = 'Angry';
          } else if (mood == 'angry' && weatherCondition == "Clouds") {
            if (lightColors.any((color) => angryColors.contains(color))) {
              recommendedPantColor = lightPantColors[random.nextInt(lightPantColors.length)]; // Select a color from the list
            }
            else if (darkColors.any((color) => angryColors.contains(color))) {
              recommendedPantColor = darkPantColors[random.nextInt(darkPantColors.length)]; // Select a color from the list
            }
            else {
              recommendedPantColor = 'Black';
            }
            recommendedTopCloths = ['Hoodie', 'T-Shirt'];
            _detectedMood = 'Angry';
          } else if (mood == 'angry' && weatherCondition == "Clear") {
            if (lightColors.any((color) => angryColors.contains(color))) {
              recommendedPantColor = lightPantColors[random.nextInt(lightPantColors.length)]; // Select a color from the list
            }
            else if (darkColors.any((color) => angryColors.contains(color))) {
              recommendedPantColor = darkPantColors[random.nextInt(darkPantColors.length)]; // Select a color from the list
            }
            else {
              recommendedPantColor = 'Black';
            }
            print("Recommended Colors: $recommendedTopColors");
            recommendedTopCloths = ['T-Shirt', 'T Shirt'];
            _detectedMood = 'Angry';
          } else if (mood == 'angry' && weatherCondition == "Clear" && temp! <= 17) {
            if (lightColors.any((color) => angryColors.contains(color))) {
              recommendedPantColor = lightPantColors[random.nextInt(lightPantColors.length)]; // Select a color from the list
            }
            else if (darkColors.any((color) => angryColors.contains(color))) {
              recommendedPantColor = darkPantColors[random.nextInt(darkPantColors.length)]; // Select a color from the list
            }
            else {
              recommendedPantColor = 'Black';
            }
            print("Recommended Colors: $recommendedTopColors");
            recommendedTopCloths = ['T-Shirt', 'Hoodie'];
            _detectedMood = 'Angry';
          } else if (mood == 'angry' && weatherCondition == "Thunderstorm") {
            if (lightColors.any((color) => angryColors.contains(color))) {
              recommendedPantColor = lightPantColors[random.nextInt(lightPantColors.length)]; // Select a color from the list
            }
            else if (darkColors.any((color) => angryColors.contains(color))) {
              recommendedPantColor = darkPantColors[random.nextInt(darkPantColors.length)]; // Select a color from the list
            }
            else {
              recommendedPantColor = 'Black';
            }
            recommendedTopCloths = ['Hoodie', 'T-Shirt', 'T Shirt'];
            _detectedMood = 'Angry';
          } else if (mood == 'angry' && weatherCondition == "Rain") {
            if (lightColors.any((color) => angryColors.contains(color))) {
              recommendedPantColor = lightPantColors[random.nextInt(lightPantColors.length)]; // Select a color from the list
            }
            else if (darkColors.any((color) => angryColors.contains(color))) {
              recommendedPantColor = darkPantColors[random.nextInt(darkPantColors.length)]; // Select a color from the list
            }
            else {
              recommendedPantColor = 'Black';
            }
            recommendedTopCloths = ['Hoodie', 'Jacket', 'T-Shirt', 'T Shirt'];
            _detectedMood = 'Angry';
          } else if (mood == 'angry' && weatherCondition == "Haze") {
            if (lightColors.any((color) => angryColors.contains(color))) {
              recommendedPantColor = lightPantColors[random.nextInt(lightPantColors.length)]; // Select a color from the list
            }
            else if (darkColors.any((color) => angryColors.contains(color))) {
              recommendedPantColor = darkPantColors[random.nextInt(darkPantColors.length)]; // Select a color from the list
            }
            else {
              recommendedPantColor = 'Black';
            }
            recommendedTopCloths = ['T-Shirt', 'T Shirt'];
            _detectedMood = 'Angry';
          } else if (mood == 'neutral' && weatherCondition == "Thunderstorm") {
            if (lightColors.any((color) => ClothColors.contains(color))) {
              recommendedPantColor = lightPantColors[random.nextInt(lightPantColors.length)]; // Select a color from the list
            }
          else if (darkColors.any((color) => ClothColors.contains(color))) {
            recommendedPantColor = darkPantColors[random.nextInt(darkPantColors.length)]; // Select a color from the list
          }
          else {
            recommendedPantColor = 'Black';
          }
            recommendedTopCloths = ['Hoodie', 'T-Shirt', 'T Shirt'];
            _detectedMood = 'Neutral';
          } else if (mood == 'neutral' && weatherCondition == "Haze") {
            if (lightColors.any((color) => ClothColors.contains(color))) {
              recommendedPantColor = lightPantColors[random.nextInt(lightPantColors.length)]; // Select a color from the list
            }
            else if (darkColors.any((color) => ClothColors.contains(color))) {
              recommendedPantColor = darkPantColors[random.nextInt(darkPantColors.length)]; // Select a color from the list
            }
            else {
              recommendedPantColor = 'Black';
            }
            recommendedTopCloths = ['T-Shirt', 'T Shirt'];
            _detectedMood = 'Neutral';
          } else if (mood == 'neutral' && weatherCondition == "Clouds") {
            if (lightColors.any((color) => ClothColors.contains(color))) {
              recommendedPantColor = lightPantColors[random.nextInt(lightPantColors.length)]; // Select a color from the list
            }
            else if (darkColors.any((color) => ClothColors.contains(color))) {
              recommendedPantColor = darkPantColors[random.nextInt(darkPantColors.length)]; // Select a color from the list
            }
            else {
              recommendedPantColor = 'Black';
            }
            recommendedTopCloths = ['Hoodie', 'T-Shirt', 'T Shirt'];
            _detectedMood = 'Neutral';
          } else if (mood == 'neutral' && weatherCondition == "Clear") {
            if (lightColors.any((color) => ClothColors.contains(color))) {
              recommendedPantColor = lightPantColors[random.nextInt(lightPantColors.length)];
            }
            else if (darkColors.any((color) => ClothColors.contains(color))) {
              recommendedPantColor = darkPantColors[random.nextInt(darkPantColors.length)];
            }
            else {
              recommendedPantColor = 'Black';
            }
            recommendedTopCloths = ['T-Shirt', 'T Shirt'];
            _detectedMood = 'Neutral';
          } else if (mood == 'neutral' && weatherCondition == "Clear" && temp! <= 17) {
            if (lightColors.any((color) => ClothColors.contains(color))) {
              recommendedPantColor = lightPantColors[random.nextInt(lightPantColors.length)]; // Select a color from the list
            }
            else if (darkColors.any((color) => ClothColors.contains(color))) {
              recommendedPantColor = darkPantColors[random.nextInt(darkPantColors.length)]; // Select a color from the list
            }
            else {
              recommendedPantColor = 'Black';
            }
            recommendedTopCloths = ['T-Shirt','Hoodie', 'T Shirt'];
            _detectedMood = 'Neutral';
          } else if (mood == 'neutral' && weatherCondition == "Snow") {
            if (lightColors.any((color) => ClothColors.contains(color))) {
              recommendedPantColor = lightPantColors[random.nextInt(lightPantColors.length)]; // Select a color from the list
            }
            else if (darkColors.any((color) => ClothColors.contains(color))) {
              recommendedPantColor = darkPantColors[random.nextInt(darkPantColors.length)]; // Select a color from the list
            }
            else {
              recommendedPantColor = 'Black';
            }
            recommendedTopCloths = ['Hoodie', 'Jacket'];
            _detectedMood = 'Neutral';
          } else if (mood == 'neutral' && weatherCondition == "Rain") {
            if (lightColors.any((color) => ClothColors.contains(color))) {
              recommendedPantColor = lightPantColors[random.nextInt(lightPantColors.length)]; // Select a color from the list
            }
            else if (darkColors.any((color) => ClothColors.contains(color))) {
              recommendedPantColor = darkPantColors[random.nextInt(darkPantColors.length)]; // Select a color from the list
            }
            else {
              recommendedPantColor = 'Black';
            }
            recommendedTopCloths = ['Hoodie', 'Jacket', 'T-Shirt', 'T Shirt'];
            _detectedMood = 'Neutral';
          } else {
            if (lightColors.any((color) => ClothColors.contains(color))) {
              recommendedPantColor = lightPantColors[random.nextInt(lightPantColors.length)]; // Select a color from the list
            }
            else if (darkColors.any((color) => ClothColors.contains(color))) {
              recommendedPantColor = darkPantColors[random.nextInt(darkPantColors.length)]; // Select a color from the list
            }
            else {
              recommendedPantColor = 'Black';
            }
            recommendedTopCloths = ['T-Shirt', 'Hoodie'];
            _detectedMood = 'Undefined';
            print("Unrecognized mood: ${widget.mood}");
          }

          // Use fallback if the emotion list is empty
          if (recommendedTopColors.isEmpty) {
            if (mood == 'sad') {
              recommendedTopColors = ['Navy', 'Dark Blue', 'Blue'];
            } else if (mood == 'happy') {
              recommendedTopColors = ['Yellow', 'Orange', 'Khaki'];
            } else if (mood == 'angry') {
              recommendedTopColors = ['Red', 'Black', 'Dark Red'];
            } else {
              recommendedTopColors = [
                'Beige', 'Black', 'Blue', 'Brown', 'Dark Blue', 'Dark Green', 'Dark Red',
                'Denim Blue', 'Gold', 'Gray', 'Green', 'Grey', 'Khaki', 'Lime', 'Navy',
                'Orange', 'Pink', 'Purple', 'Red', 'Silver', 'Taupe', 'Turquoise', 'White',
                'Yellow'
              ];
            }
          }

          // Rest of your existing code for processing clothing items
          List<Map<String, dynamic>> topItems = [];
          List<Map<String, dynamic>> pantItems = [];

          data.forEach((key, value) {
            Map<String, dynamic> item = Map<String, dynamic>.from(value);
            item['key'] = key;

            bool isTopClothing = recommendedTopCloths.any((clothType) =>
                (item['clothType'] ?? '').toLowerCase().contains(clothType.toLowerCase()));

            if (isTopClothing) {
              // Check if item color matches any recommended color
              String itemColor = (item['dominantColor'] ?? '').toLowerCase();
              bool isMatch = recommendedTopColors.any((color) =>
                  itemColor.contains(color.toLowerCase()));

              item['isMatch'] = isMatch;

              // Only add items that match the recommended colors
              if (isMatch) {
                topItems.add(item);
              }
            } else if ((item['clothType'] ?? '').toLowerCase().contains('pant')) {
              item['isMatch'] = (item['dominantColor'] ?? '').toLowerCase().contains(recommendedPantColor.toLowerCase());
              pantItems.add(item);
            }
          });

          topItems.sort((a, b) => a['isMatch'] == b['isMatch']
              ? int.parse(b['timestamp'] ?? '0').compareTo(int.parse(a['timestamp'] ?? '0'))
              : (a['isMatch'] ? -1 : 1));

          pantItems.sort((a, b) => a['isMatch'] == b['isMatch']
              ? int.parse(b['timestamp'] ?? '0').compareTo(int.parse(a['timestamp'] ?? '0'))
              : (a['isMatch'] ? -1 : 1));

          outfitSuggestions = _generateOutfitSuggestions(topItems, pantItems);
          setState(() {
            moodBasedClothingItems = outfitSuggestions.expand((outfit) => outfit).toList();
            _isLoading = false;
          });

          print('Generated ${outfitSuggestions.length} outfit suggestions');
        } else {
          setState(() {
            moodBasedClothingItems = [];
            outfitSuggestions = [];
            _isLoading = false;
            _errorMessage = 'No clothing items found for this mood';
          });

          print('No data available');
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading data: ${e.toString()}';
      });

      print('Error loading mood-based clothing items: ${e.toString()}');
    }
  }

  // The rest of your existing code remains unchanged
  // Including _generateOutfitSuggestions, _formatDateTime, _selectOutfit, build, etc.

  // Generate two different outfit suggestions
  List<List<Map<String, dynamic>>> _generateOutfitSuggestions(
      List<Map<String, dynamic>> topItems, List<Map<String, dynamic>> pantItems) {
    List<List<Map<String, dynamic>>> suggestions = [];

    // Make copies to avoid affecting the original lists
    List<Map<String, dynamic>> tops = List.from(topItems);
    List<Map<String, dynamic>> pants = List.from(pantItems);

    // First suggestion
    List<Map<String, dynamic>> suggestion1 = [];

    // Add a top for suggestion 1
    if (tops.isNotEmpty) {
      suggestion1.add(tops.first);
      // Optionally remove this item from consideration for the second outfit
      if (tops.length > 1) {
        tops.removeAt(0);
      }
    } else {
      // If no tops available, create a placeholder
      suggestion1.add({
        'clothType': 'T-Shirt',
        'dominantColor': 'Any color',
        'isPlaceholder': true,
        'key': 'placeholder-top-1'
      });
    }

    // Add pants for suggestion 1
    if (pants.isNotEmpty) {
      suggestion1.add(pants.first);
      // Optionally remove this item from consideration for the second outfit
      if (pants.length > 1) {
        pants.removeAt(0);
      }
    } else {
      // If no pants available, create a placeholder
      suggestion1.add({
        'clothType': 'Pants',
        'dominantColor': 'Any color',
        'isPlaceholder': true,
        'key': 'placeholder-pants-1'
      });
    }

    suggestions.add(suggestion1);

    // Second suggestion (try to use different items)
    List<Map<String, dynamic>> suggestion2 = [];

    // Add a top for suggestion 2
    if (tops.isNotEmpty) {
      suggestion2.add(tops.first);
    } else if (topItems.isNotEmpty) {
      // If we've used all tops for suggestion 1, reuse a different one if possible
      suggestion2.add(topItems[topItems.length > 1 ? 1 : 0]);
    } else {
      // If no tops available, create a placeholder
      suggestion2.add({
        'clothType': 'T-Shirt',
        'dominantColor': 'Any color',
        'isPlaceholder': true,
        'key': 'placeholder-top-2'
      });
    }

    // Add pants for suggestion 2
    if (pants.isNotEmpty) {
      suggestion2.add(pants.first);
    } else if (pantItems.isNotEmpty) {
      // If we've used all pants for suggestion 1, reuse a different one if possible
      suggestion2.add(pantItems[pantItems.length > 1 ? 1 : 0]);
    } else {
      // If no pants available, create a placeholder
      suggestion2.add({
        'clothType': 'Pants',
        'dominantColor': 'Any color',
        'isPlaceholder': true,
        'key': 'placeholder-pants-2'
      });
    }

    suggestions.add(suggestion2);

    return suggestions;
  }

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) return 'Unknown date';

    try {
      DateTime dateTime = DateTime.parse(dateTimeStr);
      return DateFormat('MMM d, yyyy h:mm a').format(dateTime);
    } catch (e) {
      return 'Invalid date';
    }
  }

  // Navigate back to home page and pass the selected outfit
  void _selectOutfit(int outfitIndex) {
    if (outfitIndex < outfitSuggestions.length) {
      // Navigate to HomePage with the selected outfit
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => HomePage(),
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Outfit ${outfitIndex + 1} selected')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Outfit Suggestions'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadMoodBasedClothingItems,
            tooltip: 'Refresh Suggestions',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(child: Text(_errorMessage, style: TextStyle(color: Colors.red)))
          : outfitSuggestions.isEmpty
          ? Center(child: Text('No outfit suggestions available'))
          : Column(
        children: [
          // Mood Detection Banner
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            color: Colors.grey[200],
            child: Column(
              children: [
                Text(
                  'Mood Detected: $_detectedMood',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 5),
                Text(
                  'Select an outfit that matches your mood',
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Outfit suggestions
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: outfitSuggestions.length,
              itemBuilder: (context, outfitIndex) {
                final outfit = outfitSuggestions[outfitIndex];

                return Card(
                  margin: EdgeInsets.only(bottom: 20),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () => _selectOutfit(outfitIndex),
                    borderRadius: BorderRadius.circular(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Outfit header
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Outfit Suggestion ${outfitIndex + 1}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),

                        // Outfit items
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            children: [
                              for (int i = 0; i < outfit.length; i++)
                                _buildOutfitItemRow(outfit[i], i == 0 ? 'Top' : 'Pants'),
                            ],
                          ),
                        ),

                        // Selection button
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: ElevatedButton(
                            onPressed: () => _selectOutfit(outfitIndex),
                            child: Text('Select This Outfit'),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Build a row for an outfit item
  Widget _buildOutfitItemRow(Map<String, dynamic> item, String itemType) {
    final bool isPlaceholder = item['isPlaceholder'] == true;
    final String localPath = item['localPath'] ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Item image
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: isPlaceholder
                ? Center(
              child: Icon(
                itemType == 'Top' ? Icons.accessibility : Icons.account_box,
                size: 40,
                color: Colors.grey,
              ),
            )
                : _buildItemImage(localPath),
          ),

          SizedBox(width: 16),

          // Item details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$itemType:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  isPlaceholder
                      ? item['clothType'] ?? 'Any $itemType'
                      : item['clothType'] ?? 'Unknown type',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  isPlaceholder
                      ? item['dominantColor'] ?? 'Any color'
                      : item['dominantColor']?.split(' ').first ?? 'Unknown color',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemImage(String localPath) {
    return FutureBuilder<bool>(
      future: File(localPath).exists(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final fileExists = snapshot.data == true;

        if (fileExists) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(localPath),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                print('Error loading image: $error');
                return _buildErrorImage();
              },
            ),
          );
        } else {
          return _buildErrorImage();
        }
      },
    );
  }

  Widget _buildErrorImage() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image, color: Colors.grey[600], size: 24),
            SizedBox(height: 4),
            Text(
              'No image',
              style: TextStyle(color: Colors.grey[600], fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}