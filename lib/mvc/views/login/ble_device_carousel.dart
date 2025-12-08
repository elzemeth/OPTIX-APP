import 'package:flutter/material.dart';
import '../widgets/glass_card.dart';
import 'helpers.dart';
import '../../controllers/ble_service.dart';

class BleDeviceCarousel extends StatelessWidget {
  final List<BleDevice> devices;
  final Color cardBg;
  final ColorScheme cs;
  final void Function(BleDevice) onConnect;

  const BleDeviceCarousel({
    super.key,
    required this.devices,
    required this.cardBg,
    required this.cs,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    if (devices.isEmpty) {
      return const Center(child: EmptyHint());
    }

    return ListView.separated(
      key: const PageStorageKey('ble_cards_horizontal_common'),
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      physics: const BouncingScrollPhysics(),
      itemCount: devices.length,
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (c, i) {
        final d = devices[i];
        return SizedBox(
          width: 288,
          child: GlassCard(
            key: ValueKey('ble_card_${d.id}'),
            color: cardBg,
            radius: 18,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.bluetooth, color: cs.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        d.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  d.id,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7)),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => onConnect(d),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Bağlan'),
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
