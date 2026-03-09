import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddEventScreen extends StatefulWidget {
  const AddEventScreen({super.key});

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _dateController = TextEditingController();
  DateTime? _selectedDate;

  // Function to open the Date Picker
  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(), // Prevent picking past dates
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.deepPurple, // Header background color
              onPrimary: Colors.white,    // Header text color
              onSurface: Colors.black,    // Body text color
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        // Formatting for display: Day/Month/Year
        _dateController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  // Function to save the event to Firebase
  Future<void> _saveEvent() async {
    // Basic validation
    if (_titleController.text.trim().isEmpty || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a title and select a date")),
      );
      return;
    }

    final userEmail = FirebaseAuth.instance.currentUser?.email ?? "Unknown";

    try {
      await FirebaseFirestore.instance.collection('events').add({
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'eventDate': _selectedDate,      // Actual date object for sorting in Dashboard
        'dateString': _dateController.text, // String version for easy display
        'postedBy': userEmail,
        'eventStatus': 'Active',         // Default status
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context); // Go back to Dashboard after saving
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error saving event: $e")),
        );
      }
    }
  }

  @override
  void dispose() {
    // Clean up controllers when the screen is closed
    _titleController.dispose();
    _descController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Event"),
        backgroundColor: Colors.deepPurple.shade50,
      ),
      body: SingleChildScrollView( // Prevents overflow when keyboard appears
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.event_available, size: 60, color: Colors.deepPurple),
            const SizedBox(height: 20),
            
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: "Event Title",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
            ),
            const SizedBox(height: 15),
            
            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Description",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
            ),
            const SizedBox(height: 15),
            
            TextField(
              controller: _dateController,
              readOnly: true, // User must use the picker
              onTap: _pickDate,
              decoration: const InputDecoration(
                labelText: "Select Date",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
                suffixIcon: Icon(Icons.arrow_drop_down),
              ),
            ),
            const SizedBox(height: 30),
            
            ElevatedButton(
              onPressed: _saveEvent,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(15),
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text("Post Event", style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}