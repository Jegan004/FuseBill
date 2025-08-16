import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  Future<void> _deleteAlert(String docId) async {
    await FirebaseFirestore.instance
        .collection('subscriptions')
        .doc(docId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionsRef = FirebaseFirestore.instance.collection(
      'subscriptions',
    );

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          "Alerts",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.deepPurple,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: subscriptionsRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No alerts right now"));
          }

          final now = DateTime.now();
          final upcoming = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['nextDue'] == null) return false;

            try {
              final dueDate = DateFormat("yyyy-MM-dd").parse(data['nextDue']);
              final difference = dueDate.difference(now).inDays;
              return difference >= 0 && difference <= 3;
            } catch (e) {
              return false;
            }
          }).toList();

          if (upcoming.isEmpty) {
            return const Center(child: Text("No alerts right now"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: upcoming.length,
            itemBuilder: (context, index) {
              final doc = upcoming[index];
              final data = doc.data() as Map<String, dynamic>;

              // Format date to show only date, not time
              String formattedDate = "N/A";
              try {
                final date = DateFormat("yyyy-MM-dd").parse(data['nextDue']);
                formattedDate = DateFormat('dd MMM yyyy').format(date);
              } catch (_) {}

              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 400 + index * 100),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value.clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset(40 * (1 - value), 0),
                      child: child,
                    ),
                  );
                },
                child: Dismissible(
                  key: Key(doc.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    color: Colors.redAccent,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  // Remove confirmDismiss for instant delete
                  onDismissed: (_) async {
                    await _deleteAlert(doc.id);
                  },
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 6,
                    shadowColor: Colors.deepPurple.withValues(alpha: 0.13),
                    color: Colors.orange.shade50,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.orange.shade100,
                        child: Icon(
                          Icons.notifications_active_rounded,
                          color: Colors.orange,
                        ),
                      ),
                      title: Text(
                        data['name'] ?? "Unknown Subscription",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: Colors.deepPurple.shade900,
                        ),
                      ),
                      subtitle: Text(
                        "Due on: $formattedDate",
                        style: GoogleFonts.poppins(
                          color: Colors.deepPurple.shade700,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      trailing: Text(
                        "₹${data['price'] ?? ""}",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
