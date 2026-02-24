import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_event_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  // 1. ADD YOUR EMAILS HERE
  final List<String> adminEmails = const [
    "test@college.com", 
    "test2@college.com"
  ];

  Future<void> _registerForEvent(BuildContext context, String eventId, String eventTitle) async {
    final userEmail = FirebaseAuth.instance.currentUser?.email;
    if (userEmail != null) {
      await FirebaseFirestore.instance
          .collection('events')
          .doc(eventId)
          .collection('registrations')
          .doc(userEmail)
          .set({'email': userEmail, 'registeredAt': FieldValue.serverTimestamp()});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Registered!")));
    }
  }

  // SHOW ATTENDANCE LIST
  void _showAttendance(BuildContext context, String eventId) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StreamBuilder(
          stream: FirebaseFirestore.instance.collection('events').doc(eventId).collection('registrations').snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            return Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text("Attendance List", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: ListView(
                    children: snapshot.data!.docs.map((doc) => ListTile(
                      leading: const Icon(Icons.check_circle, color: Colors.green),
                      title: Text(doc['email']),
                    )).toList(),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // EDIT EVENT LOGIC
  void _editEvent(BuildContext context, DocumentSnapshot doc) {
    TextEditingController titleEdit = TextEditingController(text: doc['title']);
    TextEditingController descEdit = TextEditingController(text: doc['description']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Event"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleEdit, decoration: const InputDecoration(labelText: "Title")),
            TextField(controller: descEdit, decoration: const InputDecoration(labelText: "Description")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              FirebaseFirestore.instance.collection('events').doc(doc.id).update({
                'title': titleEdit.text,
                'description': descEdit.text,
              });
              Navigator.pop(context);
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserEmail = FirebaseAuth.instance.currentUser?.email;
    final bool isAdmin = adminEmails.contains(currentUserEmail);

    return Scaffold(
      appBar: AppBar(title: const Text("Club Hub Events")),
      floatingActionButton: isAdmin 
        ? FloatingActionButton(
            child: const Icon(Icons.add),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddEventScreen())),
          )
        : null,
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('events').orderBy('timestamp', descending: true).snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          return ListView(
            children: snapshot.data!.docs.map((doc) {
              Widget cardContent = Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                child: ListTile(
                  title: Row(
                    children: [
                      Expanded(child: Text(doc['title'], style: const TextStyle(fontWeight: FontWeight.bold))),
                      if (isAdmin) 
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                          onPressed: () => _editEvent(context, doc),
                        ),
                    ],
                  ),
                  subtitle: Text(doc['description']),
                  trailing: isAdmin 
                    ? ElevatedButton(
                        onPressed: () => _showAttendance(context, doc.id),
                        child: const Text("View List"),
                      )
                    : StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance.collection('events').doc(doc.id).collection('registrations').doc(currentUserEmail).snapshots(),
                        builder: (context, regSnapshot) {
                          bool isRegistered = regSnapshot.hasData && regSnapshot.data!.exists;
                          return ElevatedButton(
                            onPressed: isRegistered ? null : () => _registerForEvent(context, doc.id, doc['title']),
                            style: ElevatedButton.styleFrom(backgroundColor: isRegistered ? Colors.green.shade100 : null),
                            child: Text(isRegistered ? "Registered" : "Join"),
                          );
                        },
                      ),
                ),
              );

              if (isAdmin) {
                return Dismissible(
                  key: Key(doc.id),
                  direction: DismissDirection.endToStart,
                  background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.symmetric(horizontal: 20), child: const Icon(Icons.delete, color: Colors.white)),
                  onDismissed: (direction) => FirebaseFirestore.instance.collection('events').doc(doc.id).delete(),
                  child: cardContent,
                );
              }
              return cardContent;
            }).toList(),
          );
        },
      ),
    );
  }
}