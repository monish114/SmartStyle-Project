import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class BookClothPage extends StatefulWidget {
  const BookClothPage({Key? key}) : super(key: key);

  @override
  _BookClothPage createState() => _BookClothPage();
}

class _BookClothPage extends State<BookClothPage> {
  final databaseRef = FirebaseDatabase.instance.ref().child('clothing_items');
  List<Map<String, dynamic>> clothingItems = [];
  bool _isLoading = true;
  String _errorMessage = '';
  DateTime _selectedDate = DateTime.now(); // Default to today
  bool _showOnlyAvailable = true; // Toggle to show all or only available items

  // Lists for dropdown selections
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

      // Check if Firebase is initialized
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      // Get the current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'User not logged in';
        });
        return;
      }

      // Get data from Firebase for the logged-in user
      databaseRef.orderByChild("userId").equalTo(user.uid).onValue.listen((event) {
        if (event.snapshot.value != null) {
          setState(() {
            clothingItems = [];
            Map<dynamic, dynamic> values = event.snapshot.value as Map<dynamic, dynamic>;

            values.forEach((key, value) {
              Map<String, dynamic> item = Map<String, dynamic>.from(value);
              item['key'] = key;

              // Parse bookings if they exist
              if (item['bookings'] != null) {
                item['bookings'] = Map<String, dynamic>.from(item['bookings']);
              } else {
                item['bookings'] = <String, dynamic>{};
              }

              clothingItems.add(item);
            });

            // Sort by timestamp (newest first)
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
      // Show confirmation dialog
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

      // Delete from database
      await databaseRef.child(key).remove();

      // Delete local file if it exists
      final file = File(localPath);
      if (await file.exists()) {
        await file.delete();
      }

      // Refresh the list
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

    // Show edit dialog
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

              // Color Dropdown + Manual Input
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
              // Prepare updated item
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

    // Update item if changes were made
    if (updatedItem != null) {
      try {
        // Update in Firebase
        await databaseRef.child(item['key']).update({
          'clothType': updatedItem['clothType'],
          'dominantColor': updatedItem['dominantColor'],
        });

        // Update local state
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

  Future<void> _bookItem(Map<String, dynamic> item) async {
    final dateFormat = DateFormat('yyyy-MM-dd');
    final formattedDate = dateFormat.format(_selectedDate);

    // Check if the item is already booked for the selected date
    final bookings = item['bookings'] as Map<String, dynamic>? ?? {};
    if (bookings.containsKey(formattedDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('This item is already booked for this date')),
      );
      return;
    }

    // Show booking confirmation dialog
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Book Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Would you like to book this ${item['clothType']} for:'),
            SizedBox(height: 8),
            Text(
              DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Book Now'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You must be logged in to book items')),
        );
        return;
      }

      // Create booking object
      final booking = {
        'userId': user.uid,
        'userName': user.displayName ?? 'Unknown User',
        'bookingTime': DateTime.now().toIso8601String(),
      };

      // Update Firebase and local state
      await databaseRef.child(item['key']).child('bookings').child(formattedDate).set(booking);

      // Update local state
      setState(() {
        final index = clothingItems.indexWhere((i) => i['key'] == item['key']);
        if (index != -1) {
          Map<String, dynamic> bookings =
          Map<String, dynamic>.from(clothingItems[index]['bookings'] ?? {});
          bookings[formattedDate] = booking;
          clothingItems[index]['bookings'] = bookings;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Item booked successfully for ${DateFormat('MMM d, yyyy').format(_selectedDate)}')),
      );
    } catch (e) {
      print('Error booking item: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to book item: ${e.toString()}')),
      );
    }
  }

  Future<void> _cancelBooking(Map<String, dynamic> item) async {
    final dateFormat = DateFormat('yyyy-MM-dd');
    final formattedDate = dateFormat.format(_selectedDate);

    // Check if the item is booked for the selected date
    final bookings = item['bookings'] as Map<String, dynamic>? ?? {};
    if (!bookings.containsKey(formattedDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('This item is not booked for this date')),
      );
      return;
    }

    // Get booking details
    final booking = bookings[formattedDate];

    // Check if current user is the one who booked it
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || booking['userId'] != user.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You can only cancel your own bookings')),
      );
      return;
    }

    // Show cancellation confirmation dialog
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel Booking'),
        content: Text('Are you sure you want to cancel this booking for ${DateFormat('MMM d, yyyy').format(_selectedDate)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Yes, Cancel Booking', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Remove from Firebase
      await databaseRef.child(item['key']).child('bookings').child(formattedDate).remove();

      // Update local state
      setState(() {
        final index = clothingItems.indexWhere((i) => i['key'] == item['key']);
        if (index != -1) {
          Map<String, dynamic> bookings =
          Map<String, dynamic>.from(clothingItems[index]['bookings'] ?? {});
          bookings.remove(formattedDate);
          clothingItems[index]['bookings'] = bookings;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking cancelled successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to cancel booking: ${e.toString()}')),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 90)), // Allow booking up to 3 months ahead
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  bool _isItemAvailableOnSelectedDate(Map<String, dynamic> item) {
    // Check if item is booked for the selected date
    final dateFormat = DateFormat('yyyy-MM-dd');
    final formattedDate = dateFormat.format(_selectedDate);

    final bookings = item['bookings'] as Map<String, dynamic>? ?? {};
    return !bookings.containsKey(formattedDate);
  }

  // Get list of items based on availability filter
  List<Map<String, dynamic>> _getFilteredItems() {
    if (!_showOnlyAvailable) return clothingItems;

    return clothingItems.where((item) => _isItemAvailableOnSelectedDate(item)).toList();
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
    final filteredItems = _getFilteredItems();

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
      body: Column(
        children: [
          // Date selector and filter controls
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Book Clothing Items',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: Icon(Icons.calendar_today),
                        label: Text(
                          'Date: ${DateFormat('MMM d, yyyy').format(_selectedDate)}',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () => _selectDate(context),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Checkbox(
                      value: _showOnlyAvailable,
                      onChanged: (value) {
                        setState(() {
                          _showOnlyAvailable = value ?? true;
                        });
                      },
                    ),
                    Text('Show only available items'),
                    Spacer(),
                    Text(
                      '${filteredItems.length} items',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Main content
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                ? Center(child: Text(_errorMessage, style: TextStyle(color: Colors.red)))
                : filteredItems.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    _showOnlyAvailable
                        ? 'No available items for this date'
                        : 'No clothing items found',
                    style: TextStyle(fontSize: 16),
                  ),
                  if (_showOnlyAvailable)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _showOnlyAvailable = false;
                        });
                      },
                      child: Text('Show all items'),
                    ),
                ],
              ),
            )
                : GridView.builder(
              padding: EdgeInsets.all(8.0),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                final item = filteredItems[index];
                final localPath = item['localPath'];
                final isAvailable = _isItemAvailableOnSelectedDate(item);

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
                            // Image from local path
                            _buildItemImage(localPath),

                            // Action buttons
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

                            // Availability overlay
                            if (!isAvailable)
                              Container(
                                color: Colors.black.withOpacity(0.4),
                                child: Center(
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Booked',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
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
                                  ?.replaceAll(RegExp(r'[^a-zA-Z\s]'), '') // Remove non-letter characters
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
                            SizedBox(height: 8),

                            // Booking button or cancel booking
                            isAvailable
                                ? SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => _bookItem(item),
                                child: Text('Book'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 0),
                                ),
                              ),
                            )
                                : SizedBox(
                              width: double.infinity,
                              child: TextButton(
                                onPressed: () => _cancelBooking(item),
                                child: Text('Cancel Booking'),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  padding: EdgeInsets.symmetric(vertical: 0),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
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