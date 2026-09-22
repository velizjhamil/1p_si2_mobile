import 'package:flutter/material.dart';

/// Animated typing indicator with bouncing dots and an AI avatar,
/// displaying "Attention AI está escribiendo...".
class TypingIndicator extends StatefulWidget {
 const TypingIndicator({super.key});

 @override
 State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
 with SingleTickerProviderStateMixin {
 late AnimationController _controller;

 @override
 void initState() {
 super.initState();
 _controller = AnimationController(
 vsync: this,
 duration: const Duration(milliseconds: 1200),
 )..repeat();
 }

 @override
 void dispose() {
 _controller.dispose();
 super.dispose();
 }

 @override
 Widget build(BuildContext context) {
 final theme = Theme.of(context);
 final isDark = theme.brightness == Brightness.dark;

 return Padding(
 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
 child: Row(
 crossAxisAlignment: CrossAxisAlignment.end,
 children: [
 // Assistant Avatar Icon
 Container(
 width: 32,
 height: 32,
 decoration: BoxDecoration(
 gradient: const LinearGradient(
 colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
 begin: Alignment.topLeft,
 end: Alignment.bottomRight,
 ),
 shape: BoxShape.circle,
 boxShadow: [
 BoxShadow(
 color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
 blurRadius: 6,
 offset: const Offset(0, 2),
 ),
 ],
 ),
 child: const Icon(
 Icons.auto_awesome,
 size: 16,
 color: Colors.white,
 ),
 ),
 const SizedBox(width: 8),

 // Bubble with bouncing dots and label
 Container(
 padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
 decoration: BoxDecoration(
 color: isDark ? const Color(0xFF1E293B) : Colors.white,
 borderRadius: const BorderRadius.only(
 topLeft: Radius.circular(16),
 topRight: Radius.circular(16),
 bottomRight: Radius.circular(16),
 bottomLeft: Radius.circular(4),
 ),
 border: Border.all(
 color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
 width: 1,
 ),
 boxShadow: [
 BoxShadow(
 color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
 blurRadius: 4,
 offset: const Offset(0, 2),
 ),
 ],
 ),
 child: Row(
 mainAxisSize: MainAxisSize.min,
 children: [
 _buildDot(0),
 const SizedBox(width: 4),
 _buildDot(0.2),
 const SizedBox(width: 4),
 _buildDot(0.4),
 const SizedBox(width: 10),
 Text(
 'Attention AI está pensando...',
 style: TextStyle(
 fontSize: 12.5,
 fontStyle: FontStyle.italic,
 color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
 ),
 ),
 ],
 ),
 ),
 ],
 ),
 );
 }

 Widget _buildDot(double delay) {
 return AnimatedBuilder(
 animation: _controller,
 builder: (context, child) {
 final progress = (_controller.value + delay) % 1.0;
 final double offsetY = -4.0 * (1.0 - (progress * 2.0 - 1.0).abs());

 return Transform.translate(
 offset: Offset(0, offsetY),
 child: Container(
 width: 6,
 height: 6,
 decoration: const BoxDecoration(
 color: Color(0xFF7C3AED),
 shape: BoxShape.circle,
 ),
 ),
 );
 },
 );
 }
}
