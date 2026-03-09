import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_event_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  // 1. ADMIN EMAILS
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
          .set({
            'email': userEmail, 
            'status': 'Registered', 
            'registeredAt': FieldValue.serverTimestamp()
          });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Registered!")));
    }
  }

  Future<void> _finalizeEvent(String eventId, String newStatus) async {
    final eventRef = FirebaseFirestore.instance.collection('events').doc(eventId);
    await eventRef.update({'eventStatus': newStatus});

    if (newStatus == 'Completed') {
      final regs = await eventRef.collection('registrations').where('status', isEqualTo: 'Registered').get();
      for (var doc in regs.docs) {
        await doc.reference.update({'status': 'Absent'});
      }
    }
  }

  void _showAttendance(BuildContext context, String eventId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.8,
          child: StreamBuilder(
            stream: FirebaseFirestore.instance.collection('events').doc(eventId).collection('registrations').snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              return Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text("Attendance & Event Control", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    child: ListView(
                      children: snapshot.data!.docs.map((doc) {
                        String status = doc.data().toString().contains('status') ? doc['status'] : 'Registered';
                        return ListTile(
                          title: Text(doc['email']),
                          subtitle: Text("Status: $status"),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(icon: const Icon(Icons.check_circle, color: Colors.green), onPressed: () => doc.reference.update({'status': 'Present'})),
                              IconButton(icon: const Icon(Icons.cancel, color: Colors.red), onPressed: () => doc.reference.update({'status': 'Absent'})),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            _finalizeEvent(eventId, 'Cancelled');
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.block),
                          label: const Text("Cancel Event"),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade100, foregroundColor: Colors.red),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            _finalizeEvent(eventId, 'Completed');
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.done_all),
                          label: const Text("Finish Event"),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade100, foregroundColor: Colors.green),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _editEvent(BuildContext context, DocumentSnapshot doc) {
    TextEditingController titleEdit = TextEditingController(text: doc['title']);
    TextEditingController descEdit = TextEditingController(text: doc['description']);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Event"),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: titleEdit, decoration: const InputDecoration(labelText: "Title")),
          TextField(controller: descEdit, decoration: const InputDecoration(labelText: "Description")),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(onPressed: () {
            FirebaseFirestore.instance.collection('events').doc(doc.id).update({'title': titleEdit.text, 'description': descEdit.text});
            Navigator.pop(context);
          }, child: const Text("Update")),
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
        ? FloatingActionButton(child: const Icon(Icons.add), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddEventScreen())))
        : null,
      body: StreamBuilder(
        // NEW: Sorts by eventDate so the soonest event is at the top
        stream: FirebaseFirestore.instance
            .collection('events')
            .orderBy('eventDate', descending: false) 
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          return ListView(
            children: snapshot.data!.docs.map((doc) {
              String eventStatus = doc.data().toString().contains('eventStatus') ? doc['eventStatus'] : 'Active';
              // Check if date exists to avoid errors with old data
              String dateLabel = doc.data().toString().contains('dateString') ? doc['dateString'] : "TBD";

              return Dismissible(
                key: Key(doc.id),
                direction: isAdmin ? DismissDirection.endToStart : DismissDirection.none,
                background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.symmetric(horizontal: 20), child: const Icon(Icons.delete, color: Colors.white)),
                onDismissed: (direction) => FirebaseFirestore.instance.collection('events').doc(doc.id).delete(),
                child: Card(
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  child: ListTile(
                    title: Row(children: [
                      Expanded(child: Text(doc['title'], style: const TextStyle(fontWeight: FontWeight.bold))),
                      if (isAdmin) IconButton(icon: const Icon(Icons.edit, size: 20, color: Colors.blue), onPressed: () => _editEvent(context, doc)),
                    ]),
                    // UPDATED: Shows the event date above the description
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Date: $dateLabel", style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold, fontSize: 13)),
                        Text(doc['description']),
                      ],
                    ),
                    trailing: (eventStatus == 'Cancelled')
                      ? const Text("CANCELLED", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
                      : isAdmin 
                        ? ElevatedButton(onPressed: () => _showAttendance(context, doc.id), child: const Text("View List"))
                        : StreamBuilder<DocumentSnapshot>(
                            stream: FirebaseFirestore.instance.collection('events').doc(doc.id).collection('registrations').doc(currentUserEmail).snapshots(),
                            builder: (context, regSnapshot) {
                              if (!regSnapshot.hasData || !regSnapshot.data!.exists) {
                                return ElevatedButton(
                                  onPressed: (eventStatus == 'Completed') ? null : () => _registerForEvent(context, doc.id, doc['title']),
                                  child: Text(eventStatus == 'Completed' ? "Ended" : "Join"),
                                );
                              }
                              String status = regSnapshot.data!.data().toString().contains('status') ? regSnapshot.data!['status'] : 'Registered';
                              return ElevatedButton(
                                onPressed: null, 
                                style: ElevatedButton.styleFrom(backgroundColor: status == 'Present' ? Colors.green.shade100 : (status == 'Absent' ? Colors.red.shade100 : Colors.blue.shade50)),
                                child: Text(status, style: TextStyle(color: status == 'Present' ? Colors.green : (status == 'Absent' ? Colors.red : Colors.blue))),
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