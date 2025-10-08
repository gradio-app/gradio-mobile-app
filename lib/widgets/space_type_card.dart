import 'package:flutter/material.dart';
import '../models/space_type.dart';

class SpaceTypeCard extends StatelessWidget {
  final SpaceType spaceType;
  final VoidCallback onTap;

  const SpaceTypeCard({
    super.key,
    required this.spaceType,
    required this.onTap,
  });

  Color _getColor() {
    try {
      return Color(int.parse(spaceType.color.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();

    return Card(
      elevation: 0,
      margin: const EdgeInsets.fromLTRB(6, 0, 0, 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.22),
                color.withOpacity(0.08),
              ],
            ),
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(21),
                ),
                child: Center(
                  child: Icon(
                    spaceType.icon,
                    size: 24,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                spaceType.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  spaceType.description,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}