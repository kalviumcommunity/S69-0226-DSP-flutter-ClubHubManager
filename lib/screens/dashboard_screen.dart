import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Needed to know who is registering
import 'add_event_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  // --- NEW REGISTRATION LOGIC ---
  Future<void> _registerForEvent(BuildContext context, String eventId, String eventTitle) async {
    final userEmail = FirebaseAuth.instance.currentUser?.email;

    if (userEmail != null) {
      try {
        await FirebaseFirestore.instance
            .collection('events')
            .doc(eventId)
            .collection('registrations') // Creates a folder of people for THIS event
            .doc(userEmail) // Uses email as ID so one person can't join twice
            .set({
          'email': userEmail,
          'registeredAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Registered for $eventTitle!")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error registering: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Club Hub Events")),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddEventScreen()),
        ),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('events')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          if (snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 80, color: Colors.grey),
                  SizedBox(height: 10),
                  Text("No events yet. Be the first to post!", 
                       style: TextStyle(color: Colors.grey, fontSize: 18)),
                ],
              ),
            );
          }

          return ListView(
            children: snapshot.data!.docs.map((doc) {
              return Dismissible(
                key: Key(doc.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) {
                  FirebaseFirestore.instance
                      .collection('events')
                      .doc(doc.id)
                      .delete();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Event deleted")),
                  );
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  child: ListTile(
                    title: Text(
                      doc['title'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(doc['description']),
                        const SizedBox(height: 5),
                        Text(
                          "By: ${doc.data().toString().contains('postedBy') ? doc['postedBy'] : 'Anonymous'}",
                          style: const TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Colors.blueGrey,
                          ),
                        ),
                      ],
                    ),
                    isThreeLine: true,
                    // --- THE NEW JOIN BUTTON ---
                    trailing: ElevatedButton(
                      onPressed: () => _registerForEvent(context, doc.id, doc['title']),
                      child: const Text("Join"),
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}