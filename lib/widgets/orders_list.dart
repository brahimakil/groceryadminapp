import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../consts/constants.dart';
import 'orders_widget.dart';

class OrdersList extends StatelessWidget {
  const OrdersList({Key? key, required this.isInDashboard}) : super(key: key);
  final bool isInDashboard;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').orderBy('orderDate', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Text(
              'An error occurred: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(18.0),
              child: Text('No orders available'),
            ),
          );
        } else {
          return Container(
            padding: const EdgeInsets.all(defaultPadding),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.all(Radius.circular(10)),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: isInDashboard && snapshot.data!.docs.length > 4
                  ? 4
                  : snapshot.data!.docs.length,
              itemBuilder: (ctx, index) {
                final orderData = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                final orderId = snapshot.data!.docs[index].id;
                
                return OrdersWidget(
                  orderId: orderId,
                  userId: orderData['userId'] ?? '',
                  userName: orderData['userName'] ?? '',
                  orderDate: orderData['orderDate'] ?? Timestamp.now(),
                  orderStatus: orderData['status'] ?? 'Pending',
                  totalPrice: orderData['totalPrice']?.toDouble() ?? 0.0,
                  productCount: orderData['productCount'] ?? 0,
                );
              },
            ),
          );
        }
      },
    );
  }
}
