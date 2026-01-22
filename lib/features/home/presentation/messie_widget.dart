import 'package:flutter/material.dart';

class MessieWidget extends StatelessWidget {
  final String comment;
  final TextEditingController? inputController;
  final VoidCallback? onSendMessage;
  final VoidCallback? onTap;

  const MessieWidget({
    super.key,
    required this.comment,
    this.inputController,
    this.onSendMessage,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Messie + Speech Bubble Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Messie Character (LEFT)
            GestureDetector(
              onTap: onTap,
              child: Image.asset(
                'assets/images/messie.png',
                width: 80,
                height: 80,
                fit: BoxFit.contain,
                errorBuilder:
                    (context, error, stackTrace) =>
                        const Text("🦕", style: TextStyle(fontSize: 60)),
              ),
            ),
            const SizedBox(width: 8),
            // Speech Bubble
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  comment,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ],
        ),

        // Text Input (if controller provided)
        if (inputController != null) ...[
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: inputController,
                    decoration: const InputDecoration(
                      hintText: 'メッシーに質問...',
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    style: const TextStyle(fontSize: 14),
                    onSubmitted: (_) => onSendMessage?.call(),
                  ),
                ),
                IconButton(
                  onPressed: onSendMessage,
                  icon: Icon(
                    Icons.send_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
