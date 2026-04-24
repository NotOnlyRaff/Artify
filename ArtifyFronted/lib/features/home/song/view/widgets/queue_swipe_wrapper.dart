import 'package:client/core/utils.dart';
import 'package:flutter/material.dart';

class QueueSwipeWrapper extends StatelessWidget {
  final Key swipeKey;
  final Widget child;
  final Future<void> Function() onQueue;
  final String successMessage;

  const QueueSwipeWrapper({
    super.key,
    required this.swipeKey,
    required this.child,
    required this.onQueue,
    required this.successMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: swipeKey,
      direction: DismissDirection.startToEnd,
      dismissThresholds: const {
        DismissDirection.startToEnd: 0.28,
      },
      movementDuration: const Duration(milliseconds: 180),
      resizeDuration: null,
      confirmDismiss: (_) async {
        try {
          await onQueue();
          if (context.mounted) {
            showSnackBar(context, successMessage);
          }
        } catch (error) {
          if (context.mounted) {
            showSnackBar(
              context,
              'Unable to add track to queue: ${_errorMessage(error)}',
            );
          }
        }
        return false;
      },
      background: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              const Color(0xFFFE7A6B).withOpacity(0.24),
              const Color(0xFF58E1FF).withOpacity(0.12),
            ],
          ),
          border: Border.all(
            color: Colors.white.withOpacity(0.08),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        alignment: Alignment.centerLeft,
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.playlist_add_rounded,
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: 10),
            Text(
              'Add to queue',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      child: child,
    );
  }
}

String _errorMessage(Object error) {
  final raw = error.toString().trim();
  if (raw.startsWith('Exception: ')) {
    return raw.substring('Exception: '.length);
  }
  return raw.isEmpty ? 'Unknown error' : raw;
}
