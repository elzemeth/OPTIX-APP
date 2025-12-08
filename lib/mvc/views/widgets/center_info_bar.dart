import 'package:flutter/material.dart';

class CenterInfoBar extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final double height;

  const CenterInfoBar({
    super.key,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    const vPad = 6.0;
    const hPad = 12.0;

    return Material(
      color: cs.surface.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: height,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: vPad, horizontal: hPad),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, color: cs.primary),
                const SizedBox(width: 10),

                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.8),
                            ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 16, color: cs.onSurface.withValues(alpha: 0.7)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
