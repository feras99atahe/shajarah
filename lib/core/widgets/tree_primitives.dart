import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'avatar.dart';

/// A node in the tree-reveal primitives.
class TreeNode {
  final String? char;
  final String? photoUrl;
  final String name;
  final String? rel;
  final bool you;
  final bool line;
  final bool add;
  final bool hint;
  final VoidCallback? onTap;
  const TreeNode({
    this.char,
    this.photoUrl,
    required this.name,
    this.rel,
    this.you = false,
    this.line = false,
    this.add = false,
    this.hint = false,
    this.onTap,
  });
}

class NodeLabel extends StatelessWidget {
  final TreeNode n;
  const NodeLabel({super.key, required this.n});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(n.name,
              textAlign: TextAlign.center,
              style: ui(
                  size: 12,
                  weight: (n.you || n.line) ? FontWeight.w700 : FontWeight.w600,
                  color: n.add ? AppColors.faint : AppColors.ink)),
          if (n.rel != null) ...[
            const SizedBox(height: 1),
            Text(n.rel!,
                textAlign: TextAlign.center,
                style: ui(
                    size: 10.5,
                    weight: FontWeight.w500,
                    color: n.you ? AppColors.accent : AppColors.muted)),
          ],
        ]),
      );
}

class TreeRow extends StatelessWidget {
  final List<TreeNode> nodes;
  const TreeRow({super.key, required this.nodes});

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: nodes
            .map((n) => Expanded(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Avatar(
                        char: n.char,
                        photoUrl: n.photoUrl,
                        you: n.you,
                        line: n.line,
                        add: n.add,
                        hint: n.hint,
                        size: n.you ? 52 : 44,
                        onTap: n.onTap),
                    NodeLabel(n: n),
                  ]),
                ))
            .toList(),
      );
}

/// Grandparent couple — two nodes joined by a marriage line.
class Couple extends StatelessWidget {
  final TreeNode left;
  final TreeNode right;
  const Couple({super.key, required this.left, required this.right});

  Widget _node(TreeNode n) => SizedBox(
        width: 86,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Avatar(
              char: n.char,
              photoUrl: n.photoUrl,
              line: n.line,
              add: n.add,
              hint: n.hint,
              size: 46,
              onTap: n.onTap),
          NodeLabel(n: n),
        ]),
      );

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            _node(left),
            Container(
                width: 18,
                height: 46,
                alignment: Alignment.center,
                child: Container(height: 1.4, color: AppColors.line)),
            _node(right),
          ]),
        ],
      );
}

/// Connector lines from a single parent to [cols] children.
class Connector extends StatelessWidget {
  final int cols;
  const Connector({super.key, required this.cols});

  @override
  Widget build(BuildContext context) =>
      SizedBox(height: 26, width: double.infinity, child: CustomPaint(painter: _ConnPainter(cols)));
}

class _ConnPainter extends CustomPainter {
  final int cols;
  _ConnPainter(this.cols);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.line
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final w = size.width, h = size.height;
    final midY = h * (13 / 30);
    final centers =
        List.generate(cols, (i) => ((i + 0.5) / cols) * w);
    // stem down from top center
    canvas.drawLine(Offset(w / 2, 0), Offset(w / 2, midY), paint);
    // horizontal bus
    canvas.drawLine(Offset(centers.first, midY), Offset(centers.last, midY), paint);
    // drop to each child
    for (final c in centers) {
      canvas.drawLine(Offset(c, midY), Offset(c, h), paint);
    }
  }

  @override
  bool shouldRepaint(_ConnPainter o) => o.cols != cols;
}
