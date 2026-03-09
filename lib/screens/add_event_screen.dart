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

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  Future<void> _saveEvent() async {
    if (_titleController.text.isEmpty || _selectedDate == null) return;

    final userEmail = FirebaseAuth.instance.currentUser?.email ?? "Unknown";

    await FirebaseFirestore.instance.collection('events').add({
      'title': _titleController.text,
      'description': _descController.text,
      'eventDate': _selectedDate, // Saving as a Timestamp for sorting
      'dateString': _dateController.text, // Saving for display
      'postedBy': userEmail,
      'eventStatus': 'Active',
      'timestamp': FieldValue.serverTimestamp(),
    });

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add New Event")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: "Event Title")),
            TextField(controller: _descController, decoration: const InputDecoration(labelText: "Description")),
            TextField(
              controller: _dateController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: "Event Date",
                suffixIcon: Icon(Icons.calendar_today),
              ),
              onTap: _pickDate,
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _saveEvent, child: const Text("Post Event")),
          ],
        ),
      ),
    );
  }
}