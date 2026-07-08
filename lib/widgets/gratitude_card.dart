import 'package:flutter/material.dart';
import '../models/gratitude.dart';

const _cardTextPrimary = Color(0xFF352D31);
const _cardTextSecondary = Color(0xFF9A9096);
const _cardTimeColor = Color(0xFFC1BAC0);
const _bulletColor = Color(0xFFE58BAC);
const int _maxVisibleItems = 5;

class GratitudeCard extends StatelessWidget {
  final Gratitude gratitude;
  final VoidCallback onTap;

  const GratitudeCard({
    super.key,
    required this.gratitude,
    required this.onTap,
  });

  String _formatTime() {
    final dt = DateTime.fromMillisecondsSinceEpoch(gratitude.timestamp);
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    final visibleItems = gratitude.items.take(_maxVisibleItems).toList();
    final remainingCount = gratitude.items.length - _maxVisibleItems;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 13),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Visible gratitude items
            for (int i = 0; i < visibleItems.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 11, top: 2),
                    child: SizedBox(
                      width: 6,
                      height: 6,
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: _bulletColor,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      visibleItems[i],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        height: 1.5,
                        color: _cardTextPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (remainingCount > 0)
                  Text(
                    '+$remainingCount more',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: _cardTextSecondary,
                    ),
                  )
                else
                  const SizedBox.shrink(),
                Text(
                  _formatTime(),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _cardTimeColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
