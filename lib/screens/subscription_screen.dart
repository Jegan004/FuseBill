import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fusepay_project/screens/payment_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';
import 'add_subscription_screen.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final user = FirebaseAuth.instance.currentUser;
    final firestore = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        elevation: 4,
        centerTitle: true,
        title: Text(
          "My Subscriptions",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: size.width * 0.05,
            color: Colors.white,
          ),
        ),
      ),
      body: user == null
          ? const Center(child: Text("Please log in to view subscriptions."))
          : StreamBuilder<QuerySnapshot>(
              stream: firestore.getUserSubscriptions(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        "No subscriptions yet.\nTap the '+' button to add one.",
                        style: GoogleFonts.poppins(
                          fontSize: size.width * 0.045,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final subs = snapshot.data!.docs;

                // Sort by nextDue date
                subs.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  final aDate =
                      DateTime.tryParse(aData['nextDue'] ?? '') ??
                      DateTime(2100);
                  final bDate =
                      DateTime.tryParse(bData['nextDue'] ?? '') ??
                      DateTime(2100);
                  return aDate.compareTo(bDate);
                });

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: subs.length,
                  itemBuilder: (context, index) {
                    final doc = subs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    final name = data['name'] ?? '';
                    final price = data['price'] ?? '0';
                    final nextDueRaw = data['nextDue'] ?? '';

                    // Format date
                    final nextDueDate = DateTime.tryParse(nextDueRaw);
                    final formattedDue = nextDueDate != null
                        ? DateFormat('dd MMM yyyy').format(nextDueDate)
                        : 'N/A';

                    // Format price
                    final formattedPrice =
                        '₹${double.tryParse(price)?.toStringAsFixed(2) ?? '0.00'}';

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
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          color: Colors.redAccent,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (_) async {
                          return await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text("Delete Subscription"),
                              content: const Text(
                                "Are you sure you want to delete this subscription?",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text("Cancel"),
                                ),
                                ElevatedButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent,
                                  ),
                                  child: const Text("Delete"),
                                ),
                              ],
                            ),
                          );
                        },
                        onDismissed: (_) async {
                          await firestore.deleteSubscription(doc.id);
                        },
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          elevation: 8,
                          shadowColor: Colors.deepPurple.withValues(
                            alpha: 0.13,
                          ),
                          color: Colors.deepPurple.shade50,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 8,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.deepPurple.shade100,
                                  radius: size.width * 0.07,
                                  child: Text(
                                    name.isNotEmpty
                                        ? name[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      color: Colors.deepPurple,
                                      fontWeight: FontWeight.bold,
                                      fontSize: size.width * 0.06,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          fontSize: size.width * 0.05,
                                          color: Colors.deepPurple.shade900,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Next Due: $formattedDue",
                                        style: GoogleFonts.poppins(
                                          color: Colors.deepPurple.shade700,
                                          fontWeight: FontWeight.w400,
                                          fontSize: size.width * 0.035,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      formattedPrice,
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        fontSize: size.width * 0.045,
                                        color: Colors.deepPurple,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      width: 60,
                                      height: 32,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => PaymentScreen(
                                                serviceName: name,
                                                amount: price,
                                                subscriptionId: doc.id,
                                              ),
                                            ),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              Colors.deepPurple.shade300,
                                          padding: EdgeInsets.zero,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          elevation: 4,
                                        ),
                                        child: Text(
                                          "Pay",
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: user == null
          ? null
          : FloatingActionButton.extended(
              backgroundColor: Colors.deepPurple,
              elevation: 5,
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                "Add",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: Colors.white,
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddSubscriptionScreen(),
                  ),
                );
              },
            ),
    );
  }
}
