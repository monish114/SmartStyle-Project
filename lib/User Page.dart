import 'package:flutter/material.dart';

// Three separate global lists for each emotion
final List<String> sadColors = [];
final List<String> happyColors = [];
final List<String> angryColors = [];

List<String> ClothColors = [
  'Beige', 'Black', 'Blue', 'Brown', 'Dark Blue', 'Dark Green', 'Dark Red',
  'Denim Blue', 'Gold', 'Gray', 'Green', 'Grey', 'Khaki', 'Lime', 'Navy',
  'Orange', 'Pink', 'Purple', 'Red', 'Silver', 'Taupe', 'Turquoise', 'White',
  'Yellow'
];

final List<String> lightColors = ['Beige', 'Red', 'Gold','Gray','Grey', 'Khaki', 'Green',
    'Lime', 'Orange', 'Pink', 'Silver', 'Taupe', 'Turquoise', 'White', 'Yellow', 'Blue'];

final List<String> lightPantColors = ['Black', 'Brown', 'Dark Blue',
  'Dark Green', 'Dark Red', 'Denim Blue', 'Navy'];

final List<String> darkPantColors = ['Beige', 'Khaki', 'White', 'Black',
  'Gray', 'Grey', 'Taupe'];

final List<String> darkColors = ['Black', 'Blue', 'Brown', 'Dark Blue',
  'Dark Green', 'Dark Red', 'Denim Blue', 'Navy', 'Purple', 'Khaki'];

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  final List<String> colors = [
    'Beige', 'Black', 'Blue', 'Brown', 'Dark Blue', 'Dark Green', 'Dark Red',
    'Denim Blue', 'Gold', 'Gray', 'Green', 'Grey', 'Khaki', 'Lime', 'Navy',
    'Orange', 'Pink', 'Purple', 'Red', 'Silver', 'Taupe', 'Turquoise', 'White',
    'Yellow'
  ];

  List<String> getEmotionList(String emotion) {
    switch (emotion) {
      case 'Sad':
        return sadColors;
      case 'Happy':
        return happyColors;
      case 'Angry':
        return angryColors;
      default:
        return [];
    }
  }

  bool isColorAvailable(String color, String currentEmotion) {
    if (currentEmotion != 'Sad' && sadColors.contains(color)) {
      return false;
    }
    if (currentEmotion != 'Happy' && happyColors.contains(color)) {
      return false;
    }
    if (currentEmotion != 'Angry' && angryColors.contains(color)) {
      return false;
    }
    return true;
  }

  List<String> getAvailableColors(String emotion) {
    return colors.where((color) => isColorAvailable(color, emotion)).toList();
  }

  void toggleColor(String? color, String emotion) {
    if (color == null) return;

    setState(() {
      List<String> emotionList = getEmotionList(emotion);
      if (emotionList.contains(color)) {
        emotionList.remove(color);
      } else {
        if (isColorAvailable(color, emotion)) {
          emotionList.add(color);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Color Emotions"),
        backgroundColor: Colors.white,
      ),
      body: Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    const Text(
    "Choose colors for each emotion",
    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    ),
    const SizedBox(height: 8),
    const Text(
    "Colors selected for one emotion won't be available for others.",
    style: TextStyle(fontSize: 14, color: Colors.grey),
    ),
    const SizedBox(height: 24),
    Expanded(
    child: SingleChildScrollView(
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    _buildEmotionDropdown('Sad'),
    _buildEmotionDropdown('Happy'),
    _buildEmotionDropdown('Angry'),
    const SizedBox(height: 24),
    _buildSelectionSummary(),
    ],
    ),
    ),
    ),
    ],
    ),
    ),
    );
  }

  Widget _buildEmotionDropdown(String emotion) {
    final List<String> emotionList = getEmotionList(emotion);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Container(
            width: 100,
            child: Text(
              "For $emotion:",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _getEmotionColor(emotion),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButton<String>(
                    isExpanded: true,
                    underline: Container(),
                    hint: const Text("Select a color"),
                    value: null,
                    onChanged: (value) {
                      if (value != null) {
                        toggleColor(value, emotion);
                      }
                    },
                    items: getAvailableColors(emotion)
                        .map<DropdownMenuItem<String>>((String color) {
                      return DropdownMenuItem<String>(
                        value: color,
                        child: Text(color),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: emotionList.map((color) {
                    return Chip(
                      label: Text(color),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () => toggleColor(color, emotion),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getEmotionColor(String emotion) {
    switch (emotion) {
      case 'Sad':
        return Colors.blue;
      case 'Happy':
        return Colors.amber;
      case 'Angry':
        return Colors.red;
      default:
        return Colors.black;
    }
  }

  Widget _buildSelectionSummary() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Your Color Selections",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildEmotionSummary('Sad', sadColors),
            _buildEmotionSummary('Happy', happyColors),
            _buildEmotionSummary('Angry', angryColors),
          ],
        ),
      ),
    );
  }

  Widget _buildEmotionSummary(String emotion, List<String> emotionList) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            child: Text(
              "$emotion:",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _getEmotionColor(emotion),
              ),
            ),
          ),
          Expanded(
            child: Text(
              emotionList.isEmpty ? "No colors selected" : emotionList.join(", "),
            ),
          ),
        ],
      ),
    );
  }
}
