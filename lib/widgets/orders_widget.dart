import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:grocery_admin_panel/services/utils.dart';
import 'dart:convert';
import 'package:grocery_admin_panel/services/global_method.dart';
import 'package:grocery_admin_panel/widgets/text_widget.dart';

class OrdersWidget extends StatefulWidget {
  const OrdersWidget({
    Key? key,
    required this.orderId,
      required this.userId,
      required this.userName,
    required this.orderDate,
    required this.orderStatus,
    required this.totalPrice,
    required this.productCount,
  }) : super(key: key);
  
  final String orderId, userId, userName;
  final Timestamp orderDate;
  final String orderStatus;
  final double totalPrice;
  final int productCount;
  
  @override
  _OrdersWidgetState createState() => _OrdersWidgetState();
}

class _OrdersWidgetState extends State<OrdersWidget> {
  late String orderDateStr;
  bool _isLoading = false;
  bool _isExpanded = false;
  List<Map<String, dynamic>> _orderProducts = [];

  @override
  void initState() {
    super.initState();
    var postDate = widget.orderDate.toDate();
    orderDateStr = '${postDate.day}/${postDate.month}/${postDate.year}';
    
    // Remove automatic fetch on init to avoid duplicate fetches
    // We'll fetch only when expanding
  }
  
  Future<void> _fetchOrderProducts() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      print("Fetching products for order: ${widget.orderId}");
      
      // Use the correct subcollection name: "items" instead of "products"
      var itemsSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .collection('items') // Using "items" instead of "products"
          .get();
          
      if (itemsSnapshot.docs.isEmpty) {
        print("No items found in subcollection");
        
        // If no items are found, try checking the main order document
        final orderDoc = await FirebaseFirestore.instance
            .collection('orders')
            .doc(widget.orderId)
            .get();
            
        if (orderDoc.exists) {
          final data = orderDoc.data();
          print("Order document exists with fields: ${data?.keys.join(', ')}");
          
          // Check various possible field names
          var fieldNames = ['items', 'products', 'orderItems'];
          for (var field in fieldNames) {
            if (data != null && data.containsKey(field)) {
              final items = data[field];
              if (items is List) {
                _orderProducts = List<Map<String, dynamic>>.from(items);
                print("Found ${_orderProducts.length} products in '$field' array field");
                break;
              }
            }
          }
        } else {
          print("Order document not found!");
        }
      } else {
        // Convert the document snapshots to a list of maps
        _orderProducts = itemsSnapshot.docs.map((doc) {
          print("Item found: ${doc.id}");
          return doc.data();
        }).toList();
        
        print("Found ${_orderProducts.length} products in 'items' subcollection");
      }
    } catch (error) {
      print("Error fetching order products: $error");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildProductImage(String imageUrl, Size size) {
    try {
      return Image.memory(
        base64Decode(imageUrl),
        fit: BoxFit.cover,
        width: size.width * 0.1,
        height: size.width * 0.1,
        errorBuilder: (ctx, error, stackTrace) {
          return Image.network(
            imageUrl,
            fit: BoxFit.cover,
            width: size.width * 0.1,
            height: size.width * 0.1,
            errorBuilder: (ctx, error, stackTrace) {
              return Container(
                width: size.width * 0.1,
                height: size.width * 0.1,
                color: Colors.grey[300],
                child: const Center(
                  child: Icon(Icons.error, color: Colors.red),
                ),
              );
            },
          );
        },
      );
    } catch (e) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: size.width * 0.1,
        height: size.width * 0.1,
        errorBuilder: (ctx, error, stackTrace) {
          return Container(
            width: size.width * 0.1,
            height: size.width * 0.1,
            color: Colors.grey[300],
            child: const Center(
              child: Icon(Icons.error, color: Colors.red),
            ),
          );
        },
      );
    }
  }

  Future<void> _updateOrderStatus(String newStatus) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .update({'status': newStatus});
          
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order status updated to $newStatus')),
      );
    } catch (error) {
      GlobalMethods.errorDialog(
        subtitle: error.toString(), 
        context: context
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Utils(context).color;
    final size = Utils(context).getScreenSize;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Material(
        borderRadius: BorderRadius.circular(8.0),
        color: Theme.of(context).cardColor.withOpacity(0.4),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Header Row
              Row(
                children: [
                  // Order info icon
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.shopping_bag, 
                      color: Theme.of(context).primaryColor,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Order Summary
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Order ID and Date
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Order #${widget.orderId.substring(0, 8)}...',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              orderDateStr,
                              style: TextStyle(color: color.withOpacity(0.7)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        
                        // Customer name
                        Row(
                          children: [
                            Text('Customer: ', style: TextStyle(color: color.withOpacity(0.7))),
                            Expanded(
                              child: Text(
                                widget.userName,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                        
                        // Order Summary
                        Row(
                          children: [
                            Text('Total: ', style: TextStyle(color: color.withOpacity(0.7))),
                            Text(
                              '\$${widget.totalPrice.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 15),
                            Text('Items: ', style: TextStyle(color: color.withOpacity(0.7))),
                            Text('${widget.productCount}', style: const TextStyle(fontWeight: FontWeight.w500)),
                          ],
                        ),
                        
                        // Order status
                        Row(
                  children: [
                            Text('Status: ', style: TextStyle(color: color.withOpacity(0.7))),
                            Chip(
                              backgroundColor: _getStatusColor(widget.orderStatus),
                              label: Text(
                                widget.orderStatus,
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                              padding: EdgeInsets.zero,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Order Actions
                  Column(
                    children: [
                      // Expand/Collapse button
                      IconButton(
                        icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                        onPressed: () {
                          setState(() {
                            _isExpanded = !_isExpanded;
                            if (_isExpanded && _orderProducts.isEmpty) {
                              _fetchOrderProducts();
                            }
                          });
                        },
                      ),
                      
                      // Menu button
                      PopupMenuButton(
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            onTap: () => _updateOrderStatus('Pending'),
                            value: 'pending',
                            child: const Text('Set as Pending'),
                          ),
                          PopupMenuItem(
                            onTap: () => _updateOrderStatus('Delivered'),
                            value: 'delivered',
                            child: const Text('Set as Delivered'),
                          ),
                          PopupMenuItem(
                            onTap: () => _updateOrderStatus('Cancelled'),
                            value: 'cancelled',
                            child: const Text(
                              'Set as Cancelled',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                          PopupMenuItem(
                            onTap: () {
                              GlobalMethods.warningDialog(
                                title: 'Delete Order?',
                                subtitle: 'Are you sure you want to delete this order?',
                                fct: () async {
                                  try {
                                    // First delete all products in the subcollection
                                    final productsSnapshot = await FirebaseFirestore.instance
                                        .collection('orders')
                                        .doc(widget.orderId)
                                        .collection('items')
                                        .get();
                                    
                                    for (var doc in productsSnapshot.docs) {
                                      await doc.reference.delete();
                                    }
                                    
                                    // Then delete the order document
                                    await FirebaseFirestore.instance
                                        .collection('orders')
                                        .doc(widget.orderId)
                                        .delete();
                                        
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Order deleted')),
                                    );
                                  } catch (error) {
                                    GlobalMethods.errorDialog(
                                      subtitle: error.toString(), 
                                      context: context
                                    );
                                  }
                                },
                                context: context,
                              );
                            },
                            value: 'delete',
                            child: const Text(
                              'Delete Order',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                        child: const Icon(Icons.more_vert),
                      ),
                    ],
                  ),
                ],
              ),
              
              // Expanded view with products list
              if (_isExpanded)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'Products in this order:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (_orderProducts.isEmpty)
                      const Center(child: Text('No products found in this order'))
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _orderProducts.length,
                        itemBuilder: (ctx, index) {
                          final product = _orderProducts[index];
                          
                          // Extract product info safely with null checks
                          final title = product['title'] ?? product['productTitle'] ?? 'Unknown Product';
                          final imageUrl = product['imageUrl'] ?? product['productImage'] ?? '';
                          
                          // Try different price fields that might exist in the data
                          double price = 0.0;
                          if (product.containsKey('price')) {
                            price = (product['price'] is double) 
                                ? product['price'] 
                                : double.tryParse(product['price'].toString()) ?? 0.0;
                          } else if (product.containsKey('productPrice')) {
                            price = (product['productPrice'] is double) 
                                ? product['productPrice'] 
                                : double.tryParse(product['productPrice'].toString()) ?? 0.0;
                          }
                          
                          // Try different quantity fields that might exist
                          int quantity = 1;
                          if (product.containsKey('quantity')) {
                            quantity = (product['quantity'] is int) 
                                ? product['quantity'] 
                                : int.tryParse(product['quantity'].toString()) ?? 1;
                          } else if (product.containsKey('productQuantity')) {
                            quantity = (product['productQuantity'] is int) 
                                ? product['productQuantity'] 
                                : int.tryParse(product['productQuantity'].toString()) ?? 1;
                          }
                          
                          // Check for sale price in different possible field names
                          bool isOnSale = product['isOnSale'] == true;
                          double salePrice = 0.0;
                          if (isOnSale && product.containsKey('salePrice')) {
                            salePrice = (product['salePrice'] is double)
                                ? product['salePrice']
                                : double.tryParse(product['salePrice'].toString()) ?? 0.0;
                          }
                          
                          return Card(
                            elevation: 1,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: _buildProductImage(imageUrl, size),
                              title: Text(
                                title,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Price: \$${price.toStringAsFixed(2)}'),
                                  if (isOnSale && salePrice > 0)
                                    Text(
                                      'Sale Price: \$${salePrice.toStringAsFixed(2)}',
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                ],
                              ),
                              trailing: Text(
                                'x$quantity',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          );
                        },
                      ),
                    if (_orderProducts.isEmpty)
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            // First print the order document
                            final orderDoc = await FirebaseFirestore.instance
                                .collection('orders')
                                .doc(widget.orderId)
                                .get();
                                
                            if (orderDoc.exists) {
                              print("---------- ORDER DATA ----------");
                              print("Order ID: ${widget.orderId}");
                              print("Order Fields: ${orderDoc.data()?.keys.join(', ')}");
                              
                              // Try to directly access the items subcollection
                              final itemsSnapshot = await FirebaseFirestore.instance
                                  .collection('orders')
                                  .doc(widget.orderId)
                                  .collection('items')
                                  .get();
                                  
                              print("Items subcollection exists: ${itemsSnapshot.docs.isNotEmpty}");
                              print("Items count: ${itemsSnapshot.docs.length}");
                              
                              if (itemsSnapshot.docs.isNotEmpty) {
                                // Convert the document snapshots to a list of maps
                                final items = itemsSnapshot.docs.map((doc) => doc.data()).toList();
                                
                                // Update the state with the found items
                                setState(() {
                                  _orderProducts = items;
                                });
                                
                                // Print sample of the first item
                                if (items.isNotEmpty) {
                                  print("First item fields: ${items.first.keys.join(', ')}");
                                }
                              }
                            } else {
                              print("Order ${widget.orderId} doesn't exist!");
                            }
                          } catch (e) {
                            print("Error checking order structure: $e");
                          }
                        },
                        child: const Text("Diagnose & Fix Order Products"),
                      ),
                  ],
                ),
              
              // Loading indicator
              if (_isLoading && !_isExpanded)
                const Center(child: LinearProgressIndicator()),
            ],
          ),
        ),
      ),
    );
  }
}
