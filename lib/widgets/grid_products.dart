import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:grocery_admin_panel/services/utils.dart';

import '../consts/constants.dart';
import 'products_widget.dart';
import 'text_widget.dart';

class ProductGridWidget extends StatelessWidget {
  const ProductGridWidget(
      {Key? key,
      this.crossAxisCount = 4,
      this.childAspectRatio = 1,
      this.isInMain = true})
      : super(key: key);
  final int crossAxisCount;
  final double childAspectRatio;
  final bool isInMain;
  @override
  Widget build(BuildContext context) {
    final Color color = Utils(context).color;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('products').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'An error occurred: ${snapshot.error}',
                  style: TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    FirebaseFirestore.instance.collection('products').snapshots();
                  },
                  child: const Text("Retry"),
                ),
              ],
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No products found',
              style: TextStyle(color: color),
            ),
          );
        }
        
        return Container(
          height: isInMain ? 450 : MediaQuery.of(context).size.height - 100,
          child: GridView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: isInMain && snapshot.data!.docs.length > 4
                ? 4
                : snapshot.data!.docs.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: childAspectRatio * 1.1,
              crossAxisSpacing: defaultPadding,
              mainAxisSpacing: defaultPadding,
            ),
            itemBuilder: (context, index) {
              // Extract data directly from the snapshot
              final productData = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              final productId = snapshot.data!.docs[index].id; // Get ID separately

              // Pass all necessary data to ProductWidget
              return ProductWidget(
                id: productId, // Use the actual document ID
                title: productData['title'] ?? 'No Title',
                price: (productData['price'] ?? 0.0).toString(), // Handle potential type difference
                imageUrl: productData['imageUrl'], // Already handles null
                isOnSale: productData['isOnSale'] ?? false,
                salePrice: (productData['salePrice'] ?? 0.0), // Handle null and ensure double
                // Data needed for editing:
                categoryName: productData['categoryName'] ?? '',
                description: productData['description'] ?? '',
                nutrients: productData['nutrients'] ?? '',
                calories: productData['calories'] ?? 0,
                // isPiece is needed for display logic if you re-add it
                // isPiece: productData['isPiece'] ?? false,
              );
            },
          ),
        );
      },
    );
  }
}
