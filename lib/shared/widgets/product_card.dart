import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final VoidCallback? onCompare;
  final bool isCompared;
  final int? matchScore;
  final double? priceDropAmount;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onAdd,
    this.onCompare,
    this.isCompared = false,
    this.matchScore,
    this.priceDropAmount,
  });

  bool get _hasDiscount => product.discountPrice < product.price;
  bool get _outOfStock => product.stock <= 0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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

        final showPriceDrop = priceDropAmount != null && priceDropAmount! > 0;

        Widget card = Card(
          elevation: _outOfStock ? 0.8 : 1.2,
          shadowColor: Colors.black.withValues(alpha: _outOfStock ? 0.1 : 0.14),
          margin: EdgeInsets.zero,
          color: scheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: imageHeight,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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
                    if (_outOfStock)
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withValues(alpha: 0.04),
                                Colors.black.withValues(alpha: 0.16),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
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
                    if (matchScore != null)
                      Positioned(
                        left: 8,
                        top: _hasDiscount ? 36 : 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
                          ),
                          child: Text(
                            'Match ${matchScore!}%',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    if (showPriceDrop)
                      Positioned(
                        left: 8,
                        top: _hasDiscount ? 60 : (matchScore != null ? 36 : 8),
                        child: _PriceDropBadge(
                          amount: priceDropAmount!,
                          scheme: scheme,
                        ),
                      ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        decoration: BoxDecoration(
                          color: scheme.surface.withValues(alpha: 0.92),
                          shape: BoxShape.circle,
                          border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: WishlistToggleButton(product: product, size: 18),
                      ),
                    ),
                    if (onCompare != null)
                      Positioned(
                        left: 8,
                        bottom: 8,
                        child: GestureDetector(
                          onTap: onCompare,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isCompared
                                  ? scheme.primary.withValues(alpha: 0.9)
                                  : scheme.surface.withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
                            ),
                            child: Icon(
                              isCompared ? Icons.check : Icons.compare_arrows,
                              size: 16,
                              color: isCompared ? scheme.onPrimary : scheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    if (onAdd != null)
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: GestureDetector(
                          onTap: _outOfStock
                              ? null
                              : () {
                                  HapticFeedback.selectionClick();
                                  onAdd?.call();
                                },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: _outOfStock
                                  ? scheme.surface.withValues(alpha: 0.9)
                                  : scheme.onSurface.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(20),
                              border: _outOfStock
                                  ? Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5))
                                  : null,
                            ),
                            child: Icon(
                              _outOfStock ? Icons.notifications_outlined : Icons.add,
                              size: 18,
                              color: _outOfStock ? scheme.onSurface : scheme.surface,
                            ),
                          ),
                        ),
                      ),
                    if (_outOfStock)
                      Positioned(
                        left: 8,
                        bottom: onCompare != null ? 36 : 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: scheme.surface.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
                          ),
                          child: const Text(
                            'Out of stock',
                            style: TextStyle(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.w600),
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
                            ? Text(
                                'Notify me',
                                style: TextStyle(color: scheme.primary, fontSize: 10),
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
        );

        return Semantics(
          label: label,
          button: onTap != null && !_outOfStock,
          child: InkWell(
            onTap: _outOfStock ? null : onTap,
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                card,
                if (_outOfStock)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.02),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PriceDropBadge extends StatelessWidget {
  final double amount;
  final ColorScheme scheme;

  const _PriceDropBadge({required this.amount, required this.scheme});

  @override
  Widget build(BuildContext context) {
    final label = Formatter.currency(amount);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primary.withValues(alpha: 0.9),
            scheme.tertiary.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.trending_down, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            'Drop $label',
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 18,
            height: 8,
            child: CustomPaint(painter: _MiniTrendPainter(color: Colors.white.withValues(alpha: 0.9))),
          ),
        ],
      ),
    );
  }
}

class _MiniTrendPainter extends CustomPainter {
  final Color color;

  _MiniTrendPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(0, size.height * 0.25)
      ..lineTo(size.width * 0.35, size.height * 0.65)
      ..lineTo(size.width * 0.6, size.height * 0.4)
      ..lineTo(size.width, size.height * 0.75);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
