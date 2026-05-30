import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/member.dart';
import '../models/relationship.dart';

/// Renders curved connection lines between member nodes.
/// [positions] maps memberId → center offset of the node.
class TreePainter extends CustomPainter {
  final Map<String, Offset> positions;
  final List<Relationship> relationships;
  final List<Member> members;

  TreePainter({
    required this.positions,
    required this.relationships,
    required this.members,
  });

  final _parentPaint = Paint()
    ..color = AppColors.textTertiary.withOpacity(0.5)
    ..strokeWidth = 1.8
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  final _spousePaint = Paint()
    ..color = AppColors.female.withOpacity(0.5)
    ..strokeWidth = 1.8
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  @override
  void paint(Canvas canvas, Size size) {
    final drawn = <String>{};

    for (final rel in relationships) {
      if (rel.type != RelationshipType.parent &&
          rel.type != RelationshipType.spouse) continue;

      final key = [rel.memberId, rel.relatedMemberId]..sort();
      final keyStr = key.join('-');
      if (drawn.contains(keyStr)) continue;
      drawn.add(keyStr);

      final from = positions[rel.memberId];
      final to = positions[rel.relatedMemberId];
      if (from == null || to == null) continue;

      if (rel.type == RelationshipType.spouse) {
        _drawSpouseLine(canvas, from, to);
      } else {
        _drawParentLine(canvas, from, to);
      }
    }
  }

  void _drawParentLine(Canvas canvas, Offset from, Offset to) {
    final midY = (from.dy + to.dy) / 2;
    final path = Path()
      ..moveTo(from.dx, from.dy)
      ..cubicTo(from.dx, midY, to.dx, midY, to.dx, to.dy);
    canvas.drawPath(path, _parentPaint);
  }

  void _drawSpouseLine(Canvas canvas, Offset from, Offset to) {
    // Dashed horizontal line for spouses
    const dashWidth = 6.0;
    const dashSpace = 4.0;
    double startX = from.dx < to.dx ? from.dx : to.dx;
    final endX = from.dx < to.dx ? to.dx : from.dx;
    final y = (from.dy + to.dy) / 2;
    while (startX < endX) {
      canvas.drawLine(
        Offset(startX, y),
        Offset((startX + dashWidth).clamp(startX, endX), y),
        _spousePaint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(TreePainter old) =>
      old.positions != positions ||
      old.relationships != relationships;
}
