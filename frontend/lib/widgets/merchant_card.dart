import 'package:flutter/material.dart';
import '../models/merchant.dart';

class MerchantCard extends StatelessWidget {
  final Merchant merchant;
  final VoidCallback onTap;

  const MerchantCard({super.key, required this.merchant, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Determine which image to show (Logo preferred, else Banner, else Placeholder)
    final imageUrl = merchant.logoUrl ?? merchant.bannerUrl;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0), // List style (no gaps)
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Image (Square)
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                image: hasImage ? DecorationImage(
                  image: NetworkImage(imageUrl!),
                  fit: BoxFit.cover,
                ) : null,
              ),
              child: !hasImage 
                  ? Icon(Icons.store, color: Colors.grey[400], size: 30) 
                  : null,
            ),
            
            const SizedBox(width: 12),

            // Center Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 2),
                  // Name
                  Text(
                    merchant.name,
                    style: const TextStyle(
                      color: Color(0xFF1F2937), // Gray 800
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Category • Distance
                  Row(
                    children: [
                      if (merchant.category != null) ...[
                        Text(
                          merchant.category!,
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                        Text(' • ', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                      ],
                      Text(
                        '${merchant.distanceKm.toStringAsFixed(1)} km',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 4),

                  // Offers or Address
                  if (merchant.campaignCount > 0)
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9), // Light Green
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${merchant.campaignCount} Oferta${merchant.campaignCount > 1 ? 's' : ''}',
                        style: const TextStyle(color: Color(0xFF2E7D32), fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),

            // Right Chevron
            // const Padding(
            //   padding: EdgeInsets.only(top: 24),
            //   child: Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14),
            // ),
          ],
        ),
      ),
    );
  }
}

