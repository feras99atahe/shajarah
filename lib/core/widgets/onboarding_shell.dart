import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Onboarding shell — themed bg, optional progress bar, content, footer.
class OnboardingShell extends StatelessWidget {
  final int? step;
  final int total;
  final double pad;
  final Widget child;
  final Widget? footer;

  const OnboardingShell({
    super.key,
    this.step,
    this.total = 5,
    this.pad = 26,
    required this.child,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: Column(children: [
          if (step != null)
            Padding(
              padding: EdgeInsets.fromLTRB(pad, 70, pad, 0),
              child: Row(
                children: List.generate(total, (i) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsetsDirectional.only(end: i == total - 1 ? 0 : 6),
                      decoration: BoxDecoration(
                        color: i <= step! ? AppColors.primary : AppColors.line,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  );
                }),
              ),
            ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(pad, step != null ? 22 : 70, pad, 0),
              child: child,
            ),
          ),
          if (footer != null)
            Padding(padding: EdgeInsets.fromLTRB(pad, 12, pad, 42), child: footer!),
        ]),
      ),
    );
  }
}
