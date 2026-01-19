import 'package:flutter/material.dart';

/// Widget representing a single pit in the Awale board
class AwalePit extends StatelessWidget {
  final int pitIndex;
  final int seedCount;
  final bool isSelectable;
  final bool isHighlighted;
  final VoidCallback? onTap;
  final bool isTopRow;

  const AwalePit({
    super.key,
    required this.pitIndex,
    required this.seedCount,
    this.isSelectable = false,
    this.isHighlighted = false,
    this.onTap,
    required this.isTopRow,
  });

  @override
  Widget build(BuildContext context) {
    // Enhanced color scheme for wood-like appearance
    final Color pitColor = isHighlighted
        ? const Color(0xFFA1887F) // Lighter brown when highlighted
        : const Color(0xFF6D4C41); // Rich dark brown

    final Color borderColor = isSelectable
        ? const Color(0xFFFFB74D) // Warm orange for selectable
        : Colors.transparent;

    return GestureDetector(
      onTap: isSelectable ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          // Outer rim with gradient for 3D effect
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              pitColor.withValues(alpha: 0.9),
              pitColor,
              pitColor.withValues(alpha: 0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: isSelectable ? 3 : 0),
          boxShadow: [
            // Outer shadow for depth
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
              spreadRadius: 1,
            ),
            // Inner highlight for 3D effect
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(-2, -2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Inner pit with gradient for depth
            Center(
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.8,
                    colors: [
                      const Color(0xFF3E2723), // Very dark center
                      const Color(0xFF4E342E), // Dark brown
                      const Color(0xFF5D4037), // Medium brown rim
                    ],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    // Inner shadow for concave effect
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                      spreadRadius: -2,
                    ),
                  ],
                ),
              ),
            ),
            // Seed count and visualization
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Visual seeds representation
                  if (seedCount > 0 && seedCount <= 12) ...[
                    _buildSeedsVisualization(),
                    const SizedBox(height: 3),
                  ],
                  // Seed count number with shadow
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: seedCount > 0
                          ? Colors.black.withValues(alpha: 0.3)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$seedCount',
                      style: TextStyle(
                        color: seedCount > 0
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.3),
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            offset: const Offset(1, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeedsVisualization() {
    // Show small circles representing seeds (max 6 visible for compact layout)
    final visibleSeeds = seedCount > 6 ? 6 : seedCount;

    return Wrap(
      spacing: 3,
      runSpacing: 3,
      alignment: WrapAlignment.center,
      children: List.generate(
        visibleSeeds,
        (index) => Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                const Color(0xFFEFEBE9), // Light beige center
                const Color(0xFFD7CCC8), // Beige edge
                const Color(0xFFBCAAA4), // Darker beige shadow
              ],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 1,
                offset: const Offset(0.5, 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
