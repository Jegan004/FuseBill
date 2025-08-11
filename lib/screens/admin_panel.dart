import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  String? userIdFilter;
  DateTime? selectedDate;
  bool darkMode = false;

  Stream<QuerySnapshot> getFilteredStream() {
    Query query = FirebaseFirestore.instance.collection('subscriptions');

    if (userIdFilter != null && userIdFilter!.isNotEmpty) {
      query = query.where('userId', isEqualTo: userIdFilter);
    }

    if (selectedDate != null) {
      final dayStart = DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
      );
      final dayEnd = dayStart.add(const Duration(days: 1));
      query = query
          .where('nextDue', isGreaterThanOrEqualTo: dayStart.toIso8601String())
          .where('nextDue', isLessThan: dayEnd.toIso8601String());
    }

    return query.snapshots();
  }

  Future<void> confirmDelete(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Subscription"),
        content: const Text("Are you sure you want to delete this item?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('subscriptions')
          .doc(docId)
          .delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: darkMode ? ThemeData.dark() : ThemeData.light(),
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Admin Panel"),
          actions: [
            IconButton(
              icon: Icon(darkMode ? Icons.dark_mode : Icons.light_mode),
              onPressed: () => setState(() => darkMode = !darkMode),
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Filter by User ID',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) =>
                          setState(() => userIdFilter = value),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => selectedDate = picked);
                      }
                    },
                    child: const Text("Filter by Date"),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: getFilteredStream(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;

                      return Card(
                        child: ListTile(
                          title: Text(data['name'] ?? 'No Name'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("User: ${data['userId'] ?? ''}"),
                              Text("Price: ₹${data['price'] ?? '0'}"),
                              Text("Due: ${data['nextDue'] ?? ''}"),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.redAccent,
                            ),
                            onPressed: () => confirmDelete(doc.id),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
