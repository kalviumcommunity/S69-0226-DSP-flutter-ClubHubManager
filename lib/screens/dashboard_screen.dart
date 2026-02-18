import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_event_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Club Hub Events")),
      // This button opens the Add Event page
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddEventScreen())),
      ),
      // This part reads data from Firebase in REAL TIME
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('events').orderBy('timestamp', descending: true).snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          return ListView(
            children: snapshot.data!.docs.map((doc) {
              return ListTile(
                title: Text(doc['title']),
                subtitle: Text(doc['description']),
                trailing: const Icon(Icons.event),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}