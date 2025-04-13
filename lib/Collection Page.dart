import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class ViewClothsCollection extends StatefulWidget {
  const ViewClothsCollection({Key? key}) : super(key: key);

  @override
  _ViewCollectionState createState() => _ViewCollectionState();
}

class _ViewCollectionState extends State<ViewClothsCollection> {
  final databaseRef = FirebaseDatabase.instance.ref().child('clothing_items');
  List<Map<String, dynamic>> clothingItems = [];
  bool _isLoading = true;
  String _errorMessage = '';

  final List<String> clothTypes = [
    "Hoodie", "Jacket", "Pant", "T-Shirt", "Shirt", "T Shirt"
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


  Future<void> _deleteItem(String key, String localPath) async {
    try {
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Delete Item'),
          content: Text('Are you sure you want to delete this item?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      await databaseRef.child(key).remove();

      final file = File(localPath);
      if (await file.exists()) {
        await file.delete();
      }

      setState(() {
        clothingItems.removeWhere((item) => item['key'] == key);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Item deleted successfully')),
      );
    } catch (e) {
      print('Error deleting item: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete item: ${e.toString()}')),
      );
    }
  }

  Future<void> _editItem(Map<String, dynamic> item) async {
    String selectedClothType = clothTypes.firstWhere(
          (type) => item['clothType'].contains(type),
      orElse: () => '',
    );

    String selectedColor = colors.firstWhere(
          (color) => item['dominantColor']?.split(' ').first == color,
      orElse: () => '',
    );

    final clothTypeController = TextEditingController(text: selectedClothType);
    final dominantColorController = TextEditingController(text: selectedColor);

    final updatedItem = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Clothing Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Clothing Type Dropdown + Manual Input
              DropdownButtonFormField<String>(
                value: selectedClothType.isEmpty ? null : selectedClothType,
                decoration: InputDecoration(labelText: 'Clothing Type'),
                items: clothTypes.map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(type),
                )).toList(),
                onChanged: (value) {
                  clothTypeController.text = value ?? '';
                },
              ),

              DropdownButtonFormField<String>(
                value: selectedColor.isEmpty ? null : selectedColor,
                decoration: InputDecoration(labelText: 'Dominant Color'),
                items: colors.map((color) => DropdownMenuItem(
                  value: color,
                  child: Text(color),
                )).toList(),
                onChanged: (value) {
                  dominantColorController.text = value ?? '';
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final updatedItem = {
                ...item,
                'clothType': clothTypeController.text.trim(),
                'dominantColor': dominantColorController.text.trim(),
              };
              Navigator.of(context).pop(updatedItem);
            },
            child: Text('Save'),
          ),
        ],
      ),
    );

    if (updatedItem != null) {
      try {
        await databaseRef.child(item['key']).update({
          'clothType': updatedItem['clothType'],
          'dominantColor': updatedItem['dominantColor'],
        });

        setState(() {
          final index = clothingItems.indexWhere((i) => i['key'] == item['key']);
          if (index != -1) {
            clothingItems[index] = updatedItem;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Item updated successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update item: ${e.toString()}')),
        );
      }
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

          return Card(
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
                        right: 0,
                        top: 0,
                        child: Row(
                          children: [
                            // Edit button
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _editItem(item),
                                child: Container(
                                  padding: EdgeInsets.all(8),
                                  child: Icon(
                                    Icons.edit,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    borderRadius: BorderRadius.only(
                                      bottomLeft: Radius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Delete button
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _deleteItem(item['key'], localPath),
                                child: Container(
                                  padding: EdgeInsets.all(8),
                                  child: Icon(
                                    Icons.delete_outline,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    borderRadius: BorderRadius.only(
                                      bottomLeft: Radius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
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
                            .trim()  ?? 'Unknown type',
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