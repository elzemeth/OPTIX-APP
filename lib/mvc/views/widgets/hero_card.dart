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
            // TR: Tam alan görsel | EN: Full-bleed image | RU: Изображение на всю область
            Ink.image(image: image, fit: BoxFit.cover),
            // TR: Altta koyu gradyan ve başlık | EN: Dark gradient and title at bottom | RU: Тёмный градиент и заголовок внизу
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
