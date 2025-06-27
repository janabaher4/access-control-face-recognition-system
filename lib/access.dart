import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class AttendanceDetailsScreen extends StatefulWidget {

  final String personName;

  AttendanceDetailsScreen({ required this.personName});

  @override
  _AttendanceDetailsScreenState createState() => _AttendanceDetailsScreenState();
}

class _AttendanceDetailsScreenState extends State<AttendanceDetailsScreen> {
  List<String> detections = [];
  bool isLoading = true;
  String errorMessage = '';
  int totalDetections = 0;
 final uri = Uri.parse('http://127.0.0.1:5000/attendance?ts=${DateTime.now().millisecondsSinceEpoch}'); 
  @override
  void initState() {
    super.initState();
    fetchAttendanceRecords();
  }

  Future<void> fetchAttendanceRecords() async {
    try {
     final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Navigate to the person's data in the JSON structure
        if (data is Map<String, dynamic> && 
            data.containsKey(widget.personName) && 
            data[widget.personName] is Map<String, dynamic>) {
          
          final personData = data[widget.personName] as Map<String, dynamic>;
          
          // Check if the person has detections
          if (personData.containsKey('detections') && 
              personData['detections'] is List) {
            
            final List<dynamic> detectionsData = personData['detections'];
            
            setState(() {
              detections = detectionsData.map((item) => item.toString()).toList();
              totalDetections = personData['total_detections'] ?? detections.length;
              isLoading = false;
            });
          } else {
            setState(() {
              errorMessage = 'No detection records found for ${widget.personName}';
              isLoading = false;
            });
          }
        } else {
          setState(() {
            errorMessage = 'No records found for ${widget.personName}';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Failed to load attendance records';
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching attendance records: $e');
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  // Format the timestamp for display
  String formatDate(String timestamp) {
    try {
      final DateTime dateTime = DateTime.parse(timestamp.replaceAll('"', ''));
      return DateFormat('MMM d, yyyy').format(dateTime);
    } catch (e) {
      return timestamp; // Return original if parsing fails
    }
  }

  String formatTime(String timestamp) {
    try {
      final DateTime dateTime = DateTime.parse(timestamp.replaceAll('"', ''));
      return DateFormat('h:mm:ss a').format(dateTime);
    } catch (e) {
      return timestamp; // Return original if parsing fails
    }
  }

  // Group detections by date
  Map<String, List<String>> groupDetectionsByDate() {
    Map<String, List<String>> grouped = {};
    
    for (String detection in detections) {
      String cleanTimestamp = detection.replaceAll('"', '');
      try {
        DateTime dateTime = DateTime.parse(cleanTimestamp);
        String date = DateFormat('yyyy-MM-dd').format(dateTime);
        
        if (!grouped.containsKey(date)) {
          grouped[date] = [];
        }
        grouped[date]!.add(cleanTimestamp);
      } catch (e) {
        // Skip invalid timestamps
        print('Error parsing timestamp: $detection');
      }
    }
    
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          '${widget.personName}\'s Attendance',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage, style: TextStyle(color: Colors.red)))
              : detections.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_busy,
                            size: 80,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No attendance records found',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(16),
                          color: Colors.white,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Detections: $totalDetections',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'Last seen: ${formatDate(detections.first)}',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: _buildGroupedList(),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildGroupedList() {
    final groupedDetections = groupDetectionsByDate();
    final sortedDates = groupedDetections.keys.toList()..sort((a, b) => b.compareTo(a));
    
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: sortedDates.length,
      itemBuilder: (context, dateIndex) {
        final date = sortedDates[dateIndex];
        final dateDetections = groupedDetections[date]!;
        final formattedDate = formatDate('"$date"');
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Text(
                formattedDate,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.grey[800],
                ),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: dateDetections.length,
              itemBuilder: (context, detectionIndex) {
                final detection = dateDetections[detectionIndex];
                
                return Card(
                  elevation: 2,
                  margin: EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Icon(
                        Icons.person,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      formatTime('"$detection"'),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: Icon(
                      Icons.check_circle,
                      color: Colors.green,
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}