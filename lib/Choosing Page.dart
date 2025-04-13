import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'User Page.dart';
import 'Home Page.dart';

class ChooseClothingPage extends StatefulWidget {
  const ChooseClothingPage({Key? key}) : super(key: key);

  @override
  _ChooseClothingPage createState() => _ChooseClothingPage();
}

class _ChooseClothingPage extends State<ChooseClothingPage> {
  final databaseRef = FirebaseDatabase.instance.ref().child('clothing_items');
  List<Map<String, dynamic>> clothingItems = [];
  bool _isLoading = true;
  String _errorMessage = '';
  Map<String, dynamic>? _selectedItem;
  List<Map<String, dynamic>> _suggestedItems = [];

  // Lists for classification
  final List<String> topTypes = [
    "Hoodie", "Jacket", "T-Shirt", "Shirt", "T Shirt"
  ];

  final List<String> bottomTypes = [
    "Pant"
  ];

  final List<String> colors = [
    'Beige', 'Black', 'Blue', 'Brown', 'Dark Blue', 'Dark Green', 'Dark Red',
    'Denim Blue', 'Gold', 'Gray', 'Green', 'Grey', 'Khaki', 'Lime', 'Navy',
    'Orange', 'Pink', 'Purple', 'Red', 'Silver', 'Taupe', 'Turquoise', 'White',
    'Yellow'
  ];

  @override
  void initState() {
    super.initState();
    _loadClothingItems();
  }

  Future<void> _loadClothingItems() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
        _selectedItem = null;
        _suggestedItems = [];
      });

      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'User not logged in';
        });
        return;
      }

      databaseRef.orderByChild("userId").equalTo(user.uid).onValue.listen((event) {
        if (event.snapshot.value != null) {
          setState(() {
            clothingItems = [];
            Map<dynamic, dynamic> values = event.snapshot.value as Map<dynamic, dynamic>;

            values.forEach((key, value) {
              Map<String, dynamic> item = Map<String, dynamic>.from(value);
              item['key'] = key;
              clothingItems.add(item);
            });

            clothingItems.sort((a, b) {
              int timestampA = int.tryParse(a['timestamp'] ?? '0') ?? 0;
              int timestampB = int.tryParse(b['timestamp'] ?? '0') ?? 0;
              return timestampB.compareTo(timestampA);
            });

            _isLoading = false;
          });

          print('Loaded ${clothingItems.length} clothing items for user ${user.uid}');
        } else {
          setState(() {
            clothingItems = [];
            _isLoading = false;
            _errorMessage = 'No clothing items found for this user';
          });

          print('No data available for user ${user.uid}');
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading data: ${e.toString()}';
      });

      print('Error loading clothing items: ${e.toString()}');
    }
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

  bool _isTop(String? clothType) {
    if (clothType == null) return false;
    String normalizedType = clothType.trim().toLowerCase();
    return topTypes.any((type) => normalizedType.contains(type.toLowerCase()));
  }

  bool _isBottom(String? clothType) {
    if (clothType == null) return false;
    String normalizedType = clothType.trim().toLowerCase();
    return bottomTypes.any((type) => normalizedType.contains(type.toLowerCase()));
  }

  bool _isLightColor(String? color) {
    if (color == null) return false;
    String baseColor = color.split(' ').first;
    return lightColors.contains(baseColor);
  }

  bool _isDarkColor(String? color) {
    if (color == null) return false;
    String baseColor = color.split(' ').first;
    return darkColors.contains(baseColor);
  }

  void _selectItem(Map<String, dynamic> item) {
    setState(() {
      _selectedItem = item;
      _suggestedItems = _getSuggestedItems(item);
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _buildSuggestionsBottomSheet(),
    );
  }

  List<Map<String, dynamic>> _getSuggestedItems(Map<String, dynamic> selectedItem) {
    String? clothType = selectedItem['clothType'];
    String? dominantColor = selectedItem['dominantColor'];

    List<Map<String, dynamic>> suggestions = [];

    if (_isTop(clothType)) {

      for (var item in clothingItems) {
        if (item['key'] == selectedItem['key']) continue;

        if (_isBottom(item['clothType'])) {
          if (_isLightColor(dominantColor) && _isLightColor(item['dominantColor'])) {
            suggestions.add(item);
          } else if (_isDarkColor(dominantColor) && _isDarkColor(item['dominantColor'])) {
            suggestions.add(item);
          } else if (_isLightColor(dominantColor) && lightPantColors.contains(item['dominantColor']?.split(' ').first)) {
            suggestions.add(item);
          } else if (_isDarkColor(dominantColor) && darkPantColors.contains(item['dominantColor']?.split(' ').first)) {
            suggestions.add(item);
          }
        }
      }
    } else if (_isBottom(clothType)) {
      for (var item in clothingItems) {
        if (item['key'] == selectedItem['key']) continue;

        if (_isTop(item['clothType'])) {
          if (_isLightColor(dominantColor) && _isLightColor(item['dominantColor'])) {
            suggestions.add(item);
          } else if (_isDarkColor(dominantColor) && _isDarkColor(item['dominantColor'])) {
            suggestions.add(item);
          } else if (_isLightColor(dominantColor) && darkColors.contains(item['dominantColor']?.split(' ').first)) {
            suggestions.add(item);
          } else if (_isDarkColor(dominantColor) && lightColors.contains(item['dominantColor']?.split(' ').first)) {
            suggestions.add(item);
          }
        }
      }
    }

    return suggestions;
  }

  Widget _buildSuggestionsBottomSheet() {
    if (_selectedItem == null) return SizedBox();

    String itemType = _isTop(_selectedItem!['clothType']) ? 'top' : 'bottom';
    String suggestionsType = itemType == 'top' ? 'bottoms' : 'tops';

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 100,
                      height: 100,
                      child: _buildItemImage(_selectedItem!['localPath']),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selected ${itemType.toUpperCase()}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          _selectedItem!['clothType']?.replaceAll(RegExp(r'[^a-zA-Z\s]'), '').trim() ?? 'Unknown type',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          _selectedItem!['dominantColor'] ?? 'Unknown color',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              Text(
                'Suggested ${suggestionsType.toUpperCase()} to wear with this ${itemType}:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 16),
              Expanded(
                child: _suggestedItems.isEmpty
                    ? Center(
                  child: Text(
                    'No matching ${suggestionsType} found in your wardrobe',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                )
                    : GridView.builder(
                  controller: scrollController,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _suggestedItems.length,
                  itemBuilder: (context, index) {
                    final item = _suggestedItems[index];
                    final localPath = item['localPath'];

                    return GestureDetector(
                      onTap: (){
                        Navigator.push(context, MaterialPageRoute(builder: (context) => HomePage()));
                      },
                      child: Card(
                        elevation: 3,
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  _buildItemImage(localPath),
                                ],
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['clothType']
                                        ?.replaceAll(RegExp(r'[^a-zA-Z\s]'), '')
                                        .trim() ?? 'Unknown type',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    item['dominantColor'] ?? 'Unknown color',
                                    style: TextStyle(fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Clothing Collection'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadClothingItems,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(child: Text(_errorMessage, style: TextStyle(color: Colors.red)))
          : clothingItems.isEmpty
          ? Center(child: Text('No clothing items found'))
          : GridView.builder(
        padding: EdgeInsets.all(8.0),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: clothingItems.length,
        itemBuilder: (context, index) {
          final item = clothingItems[index];
          final localPath = item['localPath'];

          return GestureDetector(
            onTap: () => _selectItem(item),
            child: Card(
              elevation: 3,
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildItemImage(localPath),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: EdgeInsets.all(4),
                            color: Colors.black.withOpacity(0.6),
                            child: Icon(
                              Icons.style,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['clothType']
                              ?.replaceAll(RegExp(r'[^a-zA-Z\s]'), '')
                              .trim() ?? 'Unknown type',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          item['dominantColor']?.split(' ').first ?? 'Unknown color',
                          style: TextStyle(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          _formatDateTime(item['uploadTime']),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
          return Image.file(
            File(localPath),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              print('Error loading image: $error');
              return _buildErrorImage();
            },
          );
        } else {
          return _buildErrorImage();
        }
      },
    );
  }

  Widget _buildErrorImage() {
    return Container(
      color: Colors.grey[300],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image, color: Colors.grey[600], size: 32),
            SizedBox(height: 8),
            Text(
              'Image not found',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}