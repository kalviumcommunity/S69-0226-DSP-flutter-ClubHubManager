import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_event_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  // 1. DEFINE YOUR ADMINS HERE
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Registered!")));
    }
  }

  // 2. FUNCTION TO SHOW ATTENDANCE (ONLY FOR ADMINS)
  void _showAttendance(BuildContext context, String eventId) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StreamBuilder(
          stream: FirebaseFirestore.instance.collection('events').doc(eventId).collection('registrations').snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            return ListView(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text("Registered Attendees", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                ...snapshot.data!.docs.map((doc) => ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(doc['email']),
                )),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserEmail = FirebaseAuth.instance.currentUser?.email;
    // Check if current user is an admin
    final bool isAdmin = adminEmails.contains(currentUserEmail);

    return Scaffold(
      appBar: AppBar(title: const Text("Club Hub Events")),
      // 3. ONLY SHOW ADD BUTTON IF ADMIN
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
                margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                child: ListTile(
                  title: Text(doc['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(doc['description']),
                  trailing: StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance.collection('events').doc(doc.id).collection('registrations').doc(currentUserEmail).snapshots(),
                    builder: (context, regSnapshot) {
                      bool isRegistered = regSnapshot.hasData && regSnapshot.data!.exists;
                      
                      return ElevatedButton(
                        onPressed: isRegistered 
                            ? (isAdmin ? () => _showAttendance(context, doc.id) : null) // Admin can click to see list
                            : () => _registerForEvent(context, doc.id, doc['title']),
                        style: ElevatedButton.styleFrom(backgroundColor: isRegistered ? Colors.green.shade100 : null),
                        child: Text(isRegistered ? (isAdmin ? "View List" : "Registered") : "Join"),
                      );
                    },
                  ),
                ),
              );

              // 4. ONLY ALLOW SWIPE TO DELETE IF ADMIN
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