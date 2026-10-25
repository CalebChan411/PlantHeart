import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../widgets/design.dart';

/// Explicit prototype tool popup. Production destinations remain behind it.
Future<void> showTestWindow(
  BuildContext context, {
  required String title,
  required Widget child,
}) => showDialog<void>(
  context: context,
  builder: (context) => Dialog(
    insetPadding: const EdgeInsets.all(12),
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    child: SizedBox(
      width: 680,
      height: math.max(
        240,
        math.min(820, MediaQuery.sizeOf(context).height - 40),
      ),
      child: Column(
        children: [
          Material(
            color: mint,
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 4),
              child: Row(
                children: [
                  const Icon(Icons.science_outlined, size: 20, color: leaf),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close test window',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    ),
  ),
);
