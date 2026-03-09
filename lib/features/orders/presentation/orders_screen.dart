import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../../../shared/widgets/price_widget.dart';
import 'orders_providers.dart';
import 'orders_downloads_provider.dart';
import '../../home/presentation/home_providers.dart';
import '../../cart/presentation/cart_providers.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  String _query = '';
  String _status = 'All';

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(ordersProvider);
    final filtered = orders.where((o) {
      final matchQuery = _query.isEmpty || o.code.toLowerCase().contains(_query.toLowerCase());
      final matchStatus = _status == 'All' || o.status == _status;
      return matchQuery && matchStatus;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            decoration: const InputDecoration(
              hintText: 'Search order code...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: ['All', 'Processing', 'Shipped', 'Delivered']
                .map(
                  (s) => ChoiceChip(
                    label: Text(s),
                    selected: _status == s,
                    onSelected: (_) => setState(() => _status = s),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          ...filtered.map(
            (order) => Card(
              child: ListTile(
                title: Text(order.code),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.date),
                    const SizedBox(height: 6),
                    _MiniTimeline(status: order.status),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    PriceWidget(price: order.total),
                    const SizedBox(height: 4),
                    _StatusChip(status: order.status),
                  ],
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: order.id)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OrderDetailScreen extends ConsumerStatefulWidget {
  final int orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  double _rating = 4.0;

  @override
  Widget build(BuildContext context) {
    final orderId = widget.orderId;
    final detail = ref.watch(orderDetailProvider(orderId));
    final products = ref.watch(homeDataProvider).allProducts;
    final downloads = ref.watch(orderDownloadsProvider).where((d) => d.orderId == orderId).toList();
    final steps = const ['Processing', 'Shipped', 'Delivered'];
    final currentIndex = steps.indexOf(detail.order.status);
    final subtotal = detail.items.fold<double>(0, (s, i) => s + (i.price * i.quantity));
    final formatter = DateFormat('dd MMM, HH:mm');
    final timeline = _buildStatusTimeline(detail.order.date, detail.order.status);
    final events = _buildTrackingEvents(detail.order.date);
    final rated = ref.watch(orderRatingProvider)[orderId];

    return Scaffold(
      appBar: AppBar(
        title: Text(detail.order.code),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/orders');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              final summary =
                  'Order ${detail.order.code}\nStatus: ${detail.order.status}\nTotal: Rp ${detail.order.total.toStringAsFixed(0)}';
              Clipboard.setData(ClipboardData(text: summary));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tracking summary copied')),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _OrderStatusTracker(status: detail.order.status),
          const SizedBox(height: 12),
          const Text('Shipping Address', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(detail.address),
          const SizedBox(height: 16),
          const Text('Payment Method', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(detail.paymentMethod),
          const SizedBox(height: 16),
          const Text('Items', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...detail.items.map(
            (item) => ListTile(
              title: Text(item.name),
              subtitle: Text('Qty ${item.quantity}'),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  PriceWidget(price: item.price * item.quantity),
                  const SizedBox(height: 4),
                  _StatusChip(status: item.status),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                for (final line in detail.items) {
                  final product = products.firstWhere(
                    (p) => p.name == line.name,
                    orElse: () => products.first,
                  );
                  ref.read(cartProvider.notifier).add(product);
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Items added to cart')),
                );
              },
              icon: const Icon(Icons.shopping_bag_outlined),
              label: const Text('Reorder'),
            ),
          ),
          const SizedBox(height: 8),
          const Text('Item Timeline', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...detail.items.map(
            (item) => Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    Stepper(
                      currentStep: currentIndex < 0 ? 0 : currentIndex,
                      controlsBuilder: (context, details) => const SizedBox.shrink(),
                      steps: steps
                          .map(
                            (s) => Step(
                              title: Text(s),
                              content: const SizedBox.shrink(),
                              isActive: steps.indexOf(s) <= currentIndex,
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text('Item Tracking', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...detail.items.map(
            (item) => _ItemTrackingCard(itemName: item.name, status: item.status),
          ),
          const SizedBox(height: 8),
          const Text('Tracking Map Preview', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          _MiniMapPreview(orderId: orderId),
          const Divider(),
          if (detail.order.status == 'Delivered') ...[
            const Text('Rate Your Order', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (rated != null)
              Text('Thanks! You rated ${rated.toStringAsFixed(1)}', style: const TextStyle(color: Colors.green))
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Slider(
                    value: _rating,
                    min: 1,
                    max: 5,
                    divisions: 8,
                    label: _rating.toStringAsFixed(1),
                    onChanged: (v) => setState(() => _rating = v),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        ref.read(orderRatingProvider.notifier).setRating(orderId, _rating);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Thanks for your feedback')),
                        );
                      },
                      child: const Text('Submit rating'),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 12),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal'),
              PriceWidget(price: subtotal),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Shipping'),
              const Text('Rp 20000'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total', style: TextStyle(fontWeight: FontWeight.w700)),
              PriceWidget(price: detail.order.total),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Downloads', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (downloads.isEmpty)
            const Text('No downloads yet', style: TextStyle(color: Colors.grey))
          else
            ...downloads.map(
              (d) => Card(
                child: ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: Text(d.filename),
                  subtitle: Text('Saved at ${formatter.format(d.createdAt)}'),
                  trailing: TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Opening ${d.filename}')),
                      );
                    },
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                var added = 0;
                for (final item in detail.items) {
                  final product = products.where((p) => p.name == item.name).firstOrNull;
                  if (product != null) {
                    for (var i = 0; i < item.quantity; i++) {
                      ref.read(cartProvider.notifier).add(product);
                    }
                    added += item.quantity;
                  }
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Added $added items to cart')),
                );
              },
              icon: const Icon(Icons.replay),
              label: const Text('Re-order items'),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final bytes = await _buildInvoice(detail);
                    await Printing.sharePdf(
                      bytes: bytes,
                      filename: 'invoice-${detail.order.code}.pdf',
                    );
                    await ref.read(orderDownloadsProvider.notifier).addDownload(
                          orderId: detail.order.id,
                          code: detail.order.code,
                          filename: 'invoice-${detail.order.code}.pdf',
                          action: 'Share',
                        );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invoice shared')),
                      );
                    }
                  },
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final bytes = await _buildInvoice(detail);
                    await Printing.sharePdf(
                      bytes: bytes,
                      filename: 'invoice-${detail.order.code}.pdf',
                    );
                    await ref.read(orderDownloadsProvider.notifier).addDownload(
                          orderId: detail.order.id,
                          code: detail.order.code,
                          filename: 'invoice-${detail.order.code}.pdf',
                          action: 'Download',
                        );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invoice saved')),
                      );
                    }
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Download'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Download History', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (downloads.isEmpty)
            const Text('No downloads yet', style: TextStyle(color: Colors.grey))
          else
            ...downloads.map(
              (d) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.receipt_long),
                title: Text(d.filename),
                subtitle: Text('${d.action} - ${formatter.format(d.createdAt)}'),
              ),
            ),
          const SizedBox(height: 24),
          const Text('Tracking', style: TextStyle(fontWeight: FontWeight.w700)),
          Stepper(
            currentStep: currentIndex < 0 ? 0 : currentIndex,
            controlsBuilder: (context, details) => const SizedBox.shrink(),
            steps: steps
                .map(
                  (s) => Step(
                    title: Text(s),
                    content: const SizedBox.shrink(),
                    isActive: steps.indexOf(s) <= currentIndex,
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          const Text('Status Timeline', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...timeline.map(
            (t) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(t.isActive ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: t.isActive ? Colors.green : Colors.grey),
              title: Text(t.status),
              subtitle: Text(t.timestamp),
            ),
          ),
          const SizedBox(height: 8),
          const Text('Tracking Events', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...events.map(
            (e) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.local_shipping_outlined),
              title: Text(e.title),
              subtitle: Text(e.time),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Delivery Proof', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (detail.order.status == 'Delivered') ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?w=600&q=80',
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Upload proof (dummy)')),
                ),
                icon: const Icon(Icons.upload_file_outlined),
                label: const Text('Upload proof'),
              ),
            ),
          ] else
            Container(
              height: 140,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Center(
                child: Text('Available after delivery', style: TextStyle(color: Colors.grey)),
              ),
            ),
          const SizedBox(height: 12),
          const Text('Live Map', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          _OrderMapPanel(status: detail.order.status),
        ],
      ),
    );
  }
}

Future<Uint8List> _buildInvoice(OrderDetail detail) async {
  final doc = pw.Document();
  doc.addPage(
    pw.Page(
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Invoice', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Text('Order: ${detail.order.code}'),
            pw.Text('Date: ${detail.order.date}'),
            pw.Text('Address: ${detail.address}'),
            pw.Text('Payment: ${detail.paymentMethod}'),
            pw.SizedBox(height: 12),
            pw.Text('Items', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ...detail.items.map(
              (i) => pw.Text('${i.name} x${i.quantity}  Rp ${(i.price * i.quantity).toStringAsFixed(0)}'),
            ),
            pw.SizedBox(height: 12),
            pw.Text('Total: Rp ${detail.order.total.toStringAsFixed(0)}'),
          ],
        );
      },
    ),
  );
  return doc.save();
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  Color get _color {
    switch (status) {
      case 'Delivered':
        return Colors.green;
      case 'Shipped':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withAlpha(31),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(fontSize: 11, color: _color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ItemTrackingCard extends StatelessWidget {
  final String itemName;
  final String status;

  const _ItemTrackingCard({required this.itemName, required this.status});

  @override
  Widget build(BuildContext context) {
    final steps = const ['Processing', 'Shipped', 'Delivered'];
    final currentIndex = steps.indexOf(status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(itemName, style: const TextStyle(fontWeight: FontWeight.w700)),
            Stepper(
              currentStep: currentIndex < 0 ? 0 : currentIndex,
              controlsBuilder: (context, details) => const SizedBox.shrink(),
              steps: steps
                  .map(
                    (s) => Step(
                      title: Text(s),
                      content: const SizedBox.shrink(),
                      isActive: steps.indexOf(s) <= currentIndex,
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderStatusTracker extends StatelessWidget {
  final String status;

  const _OrderStatusTracker({required this.status});

  @override
  Widget build(BuildContext context) {
    const steps = ['Processing', 'Shipped', 'Delivered'];
    final currentIndex = steps.indexOf(status);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Live Status', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Stepper(
              currentStep: currentIndex < 0 ? 0 : currentIndex,
              controlsBuilder: (context, details) => const SizedBox.shrink(),
              steps: steps
                  .map(
                    (s) => Step(
                      title: Text(s),
                      content: const SizedBox.shrink(),
                      isActive: steps.indexOf(s) <= currentIndex,
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniTimeline extends StatelessWidget {
  final String status;

  const _MiniTimeline({required this.status});

  @override
  Widget build(BuildContext context) {
    const steps = ['Processing', 'Shipped', 'Delivered'];
    final index = steps.indexOf(status);
    return Row(
      children: List.generate(steps.length, (i) {
        final active = i <= (index < 0 ? 0 : index);
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: i == steps.length - 1 ? 0 : 6),
            decoration: BoxDecoration(
              color: active ? Colors.green : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        );
      }),
    );
  }
}

class _OrderMapPanel extends StatelessWidget {
  final String status;

  const _OrderMapPanel({required this.status});

  @override
  Widget build(BuildContext context) {
    final isDelivered = status == 'Delivered';
    final eta = isDelivered ? 'Arrived' : 'ETA 18 - 22 min';
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 190,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFE8F5E9), Color(0xFFE3F2FD)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: 0.12,
                  child: CustomPaint(painter: _MapGridPainter()),
                ),
              ),
              Positioned(
                left: 16,
                top: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isDelivered ? 'Delivered' : 'Courier en route',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(eta),
                  ],
                ),
              ),
              Positioned(
                right: 16,
                top: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(220),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.directions_bike, size: 16),
                      SizedBox(width: 6),
                      Text('Rider'),
                    ],
                  ),
                ),
              ),
              const Positioned(
                left: 28,
                bottom: 24,
                child: _MapPin(label: 'Hub', color: Colors.blue),
              ),
              const Positioned(
                right: 32,
                bottom: 32,
                child: _MapPin(label: 'You', color: Colors.redAccent),
              ),
              const Positioned(
                left: 90,
                bottom: 50,
                right: 90,
                child: Divider(color: Colors.black54, thickness: 2, height: 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniMapPreview extends StatelessWidget {
  final int orderId;

  const _MiniMapPreview({required this.orderId});

  @override
  Widget build(BuildContext context) {
    final lat = -6.2 + (orderId % 5) * 0.01;
    final lng = 106.8 + (orderId % 3) * 0.01;
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: Colors.blueGrey.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueGrey.withAlpha(40)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.map_outlined, size: 28),
            const SizedBox(height: 4),
            Text('Lat $lat, Lng $lng', style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1;
    const step = 36.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MapPin extends StatelessWidget {
  final String label;
  final Color color;

  const _MapPin({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.location_on, size: 28, color: color),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(220),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(label, style: const TextStyle(fontSize: 11)),
        ),
      ],
    );
  }
}

class _TimelineItem {
  final String status;
  final String timestamp;
  final bool isActive;

  const _TimelineItem({required this.status, required this.timestamp, required this.isActive});
}

List<_TimelineItem> _buildStatusTimeline(String orderDate, String currentStatus) {
  final steps = ['Processing', 'Shipped', 'Delivered'];
  final base = DateFormat('MMM d, yyyy').parse(orderDate);
  final currentIndex = steps.indexOf(currentStatus);
  final formatter = DateFormat('dd MMM, HH:mm');
  return List.generate(steps.length, (index) {
    final date = base.add(Duration(hours: 6 + (index * 18)));
    return _TimelineItem(
      status: steps[index],
      timestamp: formatter.format(date),
      isActive: index <= currentIndex,
    );
  });
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}

class _TrackingEvent {
  final String title;
  final String time;

  const _TrackingEvent({required this.title, required this.time});
}

List<_TrackingEvent> _buildTrackingEvents(String orderDate) {
  final base = DateFormat('MMM d, yyyy').parse(orderDate);
  final formatter = DateFormat('dd MMM, HH:mm');
  return [
    _TrackingEvent(title: 'Package received at warehouse', time: formatter.format(base.add(const Duration(hours: 8)))),
    _TrackingEvent(title: 'Courier picked up the package', time: formatter.format(base.add(const Duration(hours: 14)))),
    _TrackingEvent(title: 'Arrived at sorting center', time: formatter.format(base.add(const Duration(hours: 18)))),
    _TrackingEvent(title: 'Out for delivery', time: formatter.format(base.add(const Duration(hours: 24)))),
  ];
}

