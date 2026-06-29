import 'package:flutter/material.dart';
import '../models/gratitude.dart';

const _cardTextPrimary = Color(0xFF352D31);
const _cardTextSecondary = Color(0xFF8A8086);
const _bulletColor = Color(0xFFE58BAC);

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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 13),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 19),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment(0.3, -1.0),
            end: Alignment(-0.3, 1.0),
            colors: [Color(0xB8FFFFFF), Color(0x75FFFFFF)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xD9FFFFFF)),
          boxShadow: const [
            BoxShadow(color: Color(0x17462D41), blurRadius: 36, offset: Offset(0, 14)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: star icon + time + optional delete button
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment(-0.87, -0.5),
                      end: Alignment(0.87, 0.5),
                      colors: [Color(0xD9FBDBE9), Color(0x9EF6C8DD)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xBFFFFFFF)),
                  ),
                  child: const Icon(Icons.auto_awesome, size: 15, color: Color(0xFFDB6A92)),
                ),
                const SizedBox(width: 10),
                Text(
                  _formatTime(),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.26,
                    color: _cardTextSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Gratitude items
            for (int i = 0; i < gratitude.items.length; i++) ...[
              if (i > 0) const SizedBox(height: 11),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: SizedBox(
                      width: 7,
                      height: 7,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _bulletColor,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x4DB2446A),
                              blurRadius: 2,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      gratitude.items[i],
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                        color: _cardTextPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
