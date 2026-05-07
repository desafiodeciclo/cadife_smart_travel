import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:flutter/material.dart';
Future<T?> showAnimatedBottomSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
  bool isDismissible = true,
  Curve curve = Curves.easeInOut,
  Duration duration = const Duration(milliseconds: 300),
}) {
  return showModalBottomSheet<T>(
    context: context,
    isDismissible: isDismissible,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => AnimatedContainer(
      duration: duration,
      curve: curve,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: context.cadife.background,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: builder(context),
    ),
  );
}
