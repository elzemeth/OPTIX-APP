import 'package:flutter/material.dart';

class GlassesHeroCard extends StatelessWidget {
  final ImageProvider image;
  final String title;
  final VoidCallback onTap;

  const GlassesHeroCard({
    super.key,
    required this.image,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Görsel (tam alan)
            Ink.image(image: image, fit: BoxFit.cover),
            // Alt kısımda koyu gradient + başlık
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black54],
                ),
              ),
            ),
            Positioned(
              left: 16, right: 16, bottom: 16,
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
