import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/product.dart';
import 'rating_stars.dart';
import 'price_widget.dart';
import 'discount_badge.dart';
import 'wishlist_toggle_button.dart';
import '../../core/utils/formatter.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onAdd;

  const ProductCard({super.key, required this.product, this.onTap, this.onAdd});

  bool get _hasDiscount => product.discountPrice < product.price;
  bool get _outOfStock => product.stock <= 0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardHeight = constraints.maxHeight.isFinite ? constraints.maxHeight : 320.0;
        final desiredImage = (cardHeight * 0.5).clamp(120.0, 160.0);
        var contentHeight = cardHeight - desiredImage;
        if (contentHeight < 118) {
          contentHeight = 118;
        } else if (contentHeight > 136) {
          contentHeight = 136;
        }
        var imageHeight = cardHeight - contentHeight;
        if (imageHeight < 120) {
          imageHeight = 120;
          contentHeight = cardHeight - imageHeight;
        }
        final compact = contentHeight < 126;
        final label = 'Product ${product.name}. '
            '${_outOfStock ? 'Out of stock. ' : ''}'
            'Price ${Formatter.currency(product.discountPrice)}.';

        return Semantics(
          label: label,
          button: onTap != null && !_outOfStock,
          child: InkWell(
            onTap: _outOfStock ? null : onTap,
            borderRadius: BorderRadius.circular(12),
            child: Card(
              elevation: 1,
              margin: EdgeInsets.zero,
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: imageHeight,
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          child: CachedNetworkImage(
                            imageUrl: product.image,
                            height: imageHeight,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              height: imageHeight,
                              color: Colors.grey.shade200,
                            ),
                            errorWidget: (context, url, error) => Container(
                              height: imageHeight,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.broken_image),
                            ),
                          ),
                        ),
                        if (_hasDiscount)
                          Positioned(
                            top: 8,
                            left: 8,
                            child: DiscountBadge(
                              text: '-${(((product.price - product.discountPrice) / product.price) * 100).round()}%',
                            ),
                          ),
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(230),
                              shape: BoxShape.circle,
                            ),
                            child: WishlistToggleButton(product: product, size: 18),
                          ),
                        ),
                        if (onAdd != null)
                          Positioned(
                            right: 8,
                            bottom: 8,
                            child: GestureDetector(
                              onTap: _outOfStock ? null : onAdd,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: _outOfStock ? Colors.grey.withAlpha(160) : Colors.black.withAlpha(180),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Icon(
                                  _outOfStock ? Icons.block : Icons.add,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        if (_outOfStock)
                          Positioned(
                            left: 8,
                            bottom: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withAlpha(160),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Out of stock',
                                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: contentHeight,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: compact ? 30 : 34,
                            child: Text(
                              product.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          SizedBox(
                            height: 10,
                            child: _outOfStock
                                ? const Text(
                                    'Out of stock',
                                    style: TextStyle(color: Colors.redAccent, fontSize: 10),
                                  )
                                : product.stock <= 3
                                    ? const Text(
                                        'Low stock',
                                        style: TextStyle(color: Colors.orange, fontSize: 10),
                                      )
                                    : const SizedBox.shrink(),
                          ),
                          const SizedBox(height: 1),
                          SizedBox(
                            height: 16,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: PriceWidget(price: product.discountPrice),
                            ),
                          ),
                          SizedBox(
                            height: 10,
                            child: _hasDiscount
                                ? Text(
                                    Formatter.currency(product.price),
                                    style: const TextStyle(
                                      decoration: TextDecoration.lineThrough,
                                      fontSize: 10,
                                      color: Colors.grey,
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                          SizedBox(height: compact ? 2 : 3),
                          SizedBox(
                            height: compact ? 12 : 13,
                            child: FittedBox(
                              alignment: Alignment.centerLeft,
                              fit: BoxFit.scaleDown,
                              child: Row(
                                children: [
                                  RatingStars(rating: product.rating),
                                  if (!compact) ...[
                                    const SizedBox(width: 6),
                                    Text(
                                      '(${product.reviewCount})',
                                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
