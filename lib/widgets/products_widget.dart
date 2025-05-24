import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:convert';
import 'dart:typed_data';

import '../inner_screens/edit_prod.dart';
import '../services/global_method.dart';
import '../services/utils.dart';
import 'text_widget.dart';

class ProductWidget extends StatelessWidget {
  const ProductWidget({
    Key? key,
    required this.id,
    required this.title,
    required this.price,
    this.imageUrl,
    required this.isOnSale,
    required this.salePrice,
    required this.categoryName,
    required this.description,
    required this.nutrients,
    required this.calories,
  }) : super(key: key);

  final String id;
  final String title;
  final String price;
  final String? imageUrl;
  final bool isOnSale;
  final double salePrice;
  final String categoryName;
  final String description;
  final String nutrients;
  final int calories;

  @override
  Widget build(BuildContext context) {
    Size size = Utils(context).getScreenSize;
    final color = Utils(context).color;
    final originalPriceDouble = double.tryParse(price) ?? 0.0;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Material(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).cardColor.withOpacity(0.6),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => EditProductScreen(
                  id: id,
                  title: title,
                  price: price,
                  categoryName: categoryName,
                  imageUrl: imageUrl ?? '',
                  description: description,
                  nutrients: nutrients,
                  calories: calories,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      flex: 3,
                      child: _buildProductImage(imageUrl, context, size),
                    ),
                    Flexible(
                      flex: 1,
                      child: PopupMenuButton(
                          itemBuilder: (context) => [
                                PopupMenuItem(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => EditProductScreen(
                                           id: id, title: title, price: price,
                                           categoryName: categoryName, imageUrl: imageUrl ?? '',
                                           description: description, nutrients: nutrients, calories: calories,
                                        ),
                                      ),
                                    );
                                  },
                                  value: 1,
                                  child: const Text('Edit'),
                                ),
                                PopupMenuItem(
                                  onTap: () {
                                    GlobalMethods.warningDialog(
                                        title: 'Delete?',
                                        subtitle: 'Press Okay to confirm',
                                        fct: () async {
                                           await FirebaseFirestore.instance
                                              .collection('products')
                                              .doc(id)
                                              .delete();
                                           await Fluttertoast.showToast(
                                             msg: "Product has been deleted",
                                             toastLength: Toast.LENGTH_LONG,
                                             gravity: ToastGravity.CENTER,
                                             timeInSecForIosWeb: 1,
                                           );
                                          if (Navigator.canPop(context)) {
                                            Navigator.pop(context);
                                          }
                                        },
                                        context: context);
                                  },
                                  value: 2,
                                  child: const Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ]),
                    )
                  ],
                ),
                const SizedBox(
                  height: 2,
                ),
                Row(
                  children: [
                    TextWidget(
                      text: isOnSale
                          ? '\$${salePrice.toStringAsFixed(2)}'
                          : '\$${originalPriceDouble.toStringAsFixed(2)}',
                      color: color,
                      textSize: 18,
                    ),
                    const SizedBox(
                      width: 7,
                    ),
                    Visibility(
                        visible: isOnSale,
                        child: Text(
                          '\$${originalPriceDouble.toStringAsFixed(2)}',
                          style: TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: color),
                        )),
                  ],
                ),
                const SizedBox(
                  height: 2,
                ),
                TextWidget(
                  text: title,
                  color: color,
                  maxLines: 2,
                  textSize: 16,
                  isTitle: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage(String? imageUrl, BuildContext context, Size size) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        height: size.width * 0.12,
        width: size.width * 0.12,
        color: Colors.grey[300],
        child: Icon(Icons.image_not_supported, color: Colors.grey[700], size: size.width * 0.12 / 2),
      );
    }
    
    try {
      return Image.memory(
        base64Decode(imageUrl),
        height: size.width * 0.12,
        width: size.width * 0.12,
        fit: BoxFit.cover,
        errorBuilder: (ctx, error, stackTrace) {
          return Image.network(
            imageUrl,
            height: size.width * 0.12,
            width: size.width * 0.12,
            fit: BoxFit.cover,
            errorBuilder: (ctx, error, stackTrace) {
              return Container(
                height: size.width * 0.12,
                width: size.width * 0.12,
                color: Colors.grey[300],
                child: Icon(Icons.error, color: Colors.red, size: size.width * 0.12 / 2),
              );
            },
          );
        },
      );
    } catch (e) {
      return Image.network(
        imageUrl,
        height: size.width * 0.12,
        width: size.width * 0.12,
        fit: BoxFit.cover,
        errorBuilder: (ctx, error, stackTrace) {
          return Container(
            height: size.width * 0.12,
            width: size.width * 0.12,
            color: Colors.grey[300],
            child: Icon(Icons.error, color: Colors.red, size: size.width * 0.12 / 2),
          );
        },
      );
    }
  }
}

final Uint8List kTransparentImage = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49,
  0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06,
  0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44,
  0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D,
  0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42,
  0x60, 0x82
]); // Tiny transparent PNG
