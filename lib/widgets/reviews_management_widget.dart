import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../consts/constants.dart';

class ReviewsManagementWidget extends StatefulWidget {
  final String productId;
  final String productTitle;

  const ReviewsManagementWidget({
    Key? key,
    required this.productId,
    required this.productTitle,
  }) : super(key: key);

  @override
  State<ReviewsManagementWidget> createState() => _ReviewsManagementWidgetState();
}

class _ReviewsManagementWidgetState extends State<ReviewsManagementWidget> {
  bool _showReviews = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reviews Header
          Row(
            children: [
              Icon(
                Icons.star_rate_rounded,
                color: Colors.amber,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Product Reviews',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // Toggle Button
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _showReviews = !_showReviews;
                  });
                },
                icon: Icon(_showReviews ? Icons.expand_less : Icons.expand_more),
                label: Text(_showReviews ? 'Hide Reviews' : 'Show Reviews'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Reviews Count
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('product_reviews')
                .where('productId', isEqualTo: widget.productId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final reviewCount = snapshot.data!.docs.length;
                return Row(
                  children: [
                    Text(
                      'Total Reviews: $reviewCount',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 16),
                    if (reviewCount > 0)
                      Text(
                        'Average Rating: ${_calculateAverageRating(snapshot.data!.docs).toStringAsFixed(1)}⭐',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                );
              }
              return const Text('Loading reviews count...');
            },
          ),
          
          // Reviews List
          if (_showReviews) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('product_reviews')
                  .where('productId', isEqualTo: widget.productId)
                  // Remove the orderBy to avoid index requirements
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading reviews: ${snapshot.error}',
                      style: TextStyle(color: Colors.red),
                    ),
                  );
                }
                
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.rate_review_outlined,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No reviews yet for this product',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                // Sort the reviews manually after getting them
                var sortedReviews = snapshot.data!.docs.toList();
                sortedReviews.sort((a, b) {
                  final aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                  final bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                  
                  if (aTime == null && bTime == null) return 0;
                  if (aTime == null) return 1;
                  if (bTime == null) return -1;
                  
                  return bTime.compareTo(aTime); // Descending order (newest first)
                });
                
                return Column(
                  children: [
                    Container(
                      constraints: const BoxConstraints(maxHeight: 400),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: sortedReviews.length,
                        itemBuilder: (context, index) {
                          final reviewDoc = sortedReviews[index];
                          final reviewData = reviewDoc.data() as Map<String, dynamic>;
                          
                          return _buildReviewCard(reviewDoc.id, reviewData);
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Delete All Reviews Button
                    if (sortedReviews.isNotEmpty)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : () => _deleteAllReviews(),
                          icon: _isLoading 
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.delete_sweep),
                          label: Text(_isLoading ? 'Deleting...' : 'Delete All Reviews'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewCard(String reviewId, Map<String, dynamic> reviewData) {
    final rating = reviewData['rating'] ?? 0;
    final userName = reviewData['userName'] ?? 'Anonymous';
    final userEmail = reviewData['userEmail'] ?? '';
    final reviewText = reviewData['reviewText'] ?? '';
    final createdAt = reviewData['createdAt'] as Timestamp?;
    
    String formattedDate = 'Unknown date';
    if (createdAt != null) {
      formattedDate = DateFormat('MMM dd, yyyy at HH:mm').format(createdAt.toDate());
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with user info and rating
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (userEmail.isNotEmpty)
                        Text(
                          userEmail,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                // Rating stars
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 20,
                    );
                  }),
                ),
                const SizedBox(width: 8),
                Text(
                  '$rating/5',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Review text
            if (reviewText.isNotEmpty) ...[
              Text(
                reviewText,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
            ],
            
            // Date and actions
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  formattedDate,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _deleteReview(reviewId, userName),
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _calculateAverageRating(List<QueryDocumentSnapshot> reviews) {
    if (reviews.isEmpty) return 0.0;
    
    double totalRating = 0.0;
    for (var review in reviews) {
      final data = review.data() as Map<String, dynamic>;
      totalRating += (data['rating'] ?? 0).toDouble();
    }
    
    return totalRating / reviews.length;
  }

  Future<void> _deleteReview(String reviewId, String userName) async {
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Review'),
          content: Text('Are you sure you want to delete the review by $userName?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await FirebaseFirestore.instance
            .collection('product_reviews')
            .doc(reviewId)
            .delete();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Review by $userName deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting review: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteAllReviews() async {
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete All Reviews'),
          content: Text(
            'Are you sure you want to delete ALL reviews for "${widget.productTitle}"? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete All'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        setState(() => _isLoading = true);
        
        final reviewsSnapshot = await FirebaseFirestore.instance
            .collection('product_reviews')
            .where('productId', isEqualTo: widget.productId)
            .get();
        
        final batch = FirebaseFirestore.instance.batch();
        for (var doc in reviewsSnapshot.docs) {
          batch.delete(doc.reference);
        }
        
        await batch.commit();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('All reviews deleted successfully (${reviewsSnapshot.docs.length} reviews)'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting reviews: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
} 