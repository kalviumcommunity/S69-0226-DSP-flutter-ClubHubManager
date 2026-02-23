import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_event_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  Future<void> _registerForEvent(BuildContext context, String eventId, String eventTitle) async {
    final userEmail = FirebaseAuth.instance.currentUser?.email;

    if (userEmail != null) {
      try {
        await FirebaseFirestore.instance
            .collection('events')
            .doc(eventId)
            .collection('registrations')
            .doc(userEmail)
            .set({
          'email': userEmail,
          'registeredAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Registered for $eventTitle!")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserEmail = FirebaseAuth.instance.currentUser?.email;

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
            return const Center(child: Text("No events yet."));
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
                  FirebaseFirestore.instance.collection('events').doc(doc.id).delete();
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  child: ListTile(
                    title: Text(doc['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(doc['description']),
                        const SizedBox(height: 5),
                        Text(
                          "By: ${doc.data().toString().contains('postedBy') ? doc['postedBy'] : 'Anonymous'}",
                          style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.blueGrey),
                        ),
                      ],
                    ),
                    isThreeLine: true,
                    // --- UPDATED JOIN/REGISTERED LOGIC ---
                    trailing: StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('events')
                          .doc(doc.id)
                          .collection('registrations')
                          .doc(currentUserEmail)
                          .snapshots(),
                      builder: (context, regSnapshot) {
                        // If the document exists, it means the user is registered
                        bool isRegistered = regSnapshot.hasData && regSnapshot.data!.exists;

                        return ElevatedButton(
                          onPressed: isRegistered 
                              ? null // Disable the button if already registered
                              : () => _registerForEvent(context, doc.id, doc['title']),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isRegistered ? Colors.green.shade100 : null,
                          ),
                          child: Text(isRegistered ? "Registered" : "Join"),
                        );
                      },
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