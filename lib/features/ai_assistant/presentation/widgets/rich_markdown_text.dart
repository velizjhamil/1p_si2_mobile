import 'package:flutter/material.dart';

/// Lightweight native Markdown renderer for conversational AI messages.
///
/// Supports:
/// - Headings (`#`, `##`, `###`)
/// - Bulleted lists (`*`, `-`) and numbered lists (`1.`)
/// - Bold text (`**bold**`)
/// - Italic text (`*italic*`)
/// - Inline code (`` `code` ``)
/// - Paragraph spacing and adaptive theme colors.
class RichMarkdownText extends StatelessWidget {
 const RichMarkdownText({
 super.key,
 required this.text,
 this.baseStyle,
 this.isUser = false,
 });

 final String text;
 final TextStyle? baseStyle;
 final bool isUser;

 @override
 Widget build(BuildContext context) {
 final theme = Theme.of(context);
 final isDark = theme.brightness == Brightness.dark;

 final defaultStyle = baseStyle ??
 TextStyle(
 fontSize: 14.5,
 height: 1.45,
 color: isUser
 ? Colors.white
 : (isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B)),
 );

 final lines = text.split('\n');
 final List<Widget> widgets = [];

 for (int i = 0; i < lines.length; i++) {
 final line = lines[i].trimRight();

 if (line.trim().isEmpty) {
 widgets.add(const SizedBox(height: 6));
 continue;
 }

 // Headers: #, ##, ###
 if (line.startsWith('### ')) {
 widgets.add(Padding(
 padding: const EdgeInsets.only(top: 6, bottom: 3),
 child: Text(
 line.substring(4).trim(),
 style: defaultStyle.copyWith(
 fontWeight: FontWeight.bold,
 fontSize: defaultStyle.fontSize! + 2,
 ),
 ),
 ));
 } else if (line.startsWith('## ')) {
 widgets.add(Padding(
 padding: const EdgeInsets.only(top: 8, bottom: 4),
 child: Text(
 line.substring(3).trim(),
 style: defaultStyle.copyWith(
 fontWeight: FontWeight.w700,
 fontSize: defaultStyle.fontSize! + 3,
 ),
 ),
 ));
 } else if (line.startsWith('# ')) {
 widgets.add(Padding(
 padding: const EdgeInsets.only(top: 10, bottom: 4),
 child: Text(
 line.substring(2).trim(),
 style: defaultStyle.copyWith(
 fontWeight: FontWeight.w800,
 fontSize: defaultStyle.fontSize! + 4,
 ),
 ),
 ));
 }
 // Bullet lists: - or *
 else if (line.startsWith('- ') || line.startsWith('* ')) {
 final content = line.substring(2).trim();
 widgets.add(Padding(
 padding: const EdgeInsets.symmetric(vertical: 2),
 child: Row(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 '• ',
 style: defaultStyle.copyWith(
 fontWeight: FontWeight.bold,
 color: isUser
 ? Colors.white70
 : (isDark ? const Color(0xFFA5B4FC) : const Color(0xFF7C3AED)),
 ),
 ),
 Expanded(
 child: Text.rich(
 TextSpan(
 children: _parseInlineSpans(content, defaultStyle, isDark, isUser),
 ),
 ),
 ),
 ],
 ),
 ));
 }
 // Numbered lists: 1. 2. etc
 else if (RegExp(r'^\d+\.\s').hasMatch(line)) {
 final match = RegExp(r'^(\d+\.)\s').firstMatch(line)!;
 final numPrefix = match.group(1)!;
 final content = line.substring(match.end).trim();
 widgets.add(Padding(
 padding: const EdgeInsets.symmetric(vertical: 2),
 child: Row(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 '$numPrefix ',
 style: defaultStyle.copyWith(
 fontWeight: FontWeight.w600,
 color: isUser
 ? Colors.white70
 : (isDark ? const Color(0xFFA5B4FC) : const Color(0xFF7C3AED)),
 ),
 ),
 Expanded(
 child: Text.rich(
 TextSpan(
 children: _parseInlineSpans(content, defaultStyle, isDark, isUser),
 ),
 ),
 ),
 ],
 ),
 ));
 }
 // Regular paragraph
 else {
 widgets.add(Padding(
 padding: const EdgeInsets.symmetric(vertical: 2),
 child: Text.rich(
 TextSpan(
 children: _parseInlineSpans(line, defaultStyle, isDark, isUser),
 ),
 ),
 ));
 }
 }

 return Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 mainAxisSize: MainAxisSize.min,
 children: widgets,
 );
 }

 /// Parses inline markdown elements (**bold**, *italic*, `code`).
 static List<InlineSpan> _parseInlineSpans(
 String raw,
 TextStyle base,
 bool isDark,
 bool isUser,
 ) {
 final List<InlineSpan> spans = [];
 final pattern = RegExp(r'(\*\*[^*]+\*\*|\*[^*]+\*|`[^`]+`)');
 int lastEnd = 0;

 for (final match in pattern.allMatches(raw)) {
 if (match.start > lastEnd) {
 spans.add(TextSpan(
 text: raw.substring(lastEnd, match.start),
 style: base,
 ));
 }

 final matchedText = match.group(0)!;
 if (matchedText.startsWith('**') && matchedText.endsWith('**') && matchedText.length > 4) {
 spans.add(TextSpan(
 text: matchedText.substring(2, matchedText.length - 2),
 style: base.copyWith(fontWeight: FontWeight.bold),
 ));
 } else if (matchedText.startsWith('*') && matchedText.endsWith('*') && matchedText.length > 2) {
 spans.add(TextSpan(
 text: matchedText.substring(1, matchedText.length - 1),
 style: base.copyWith(fontStyle: FontStyle.italic),
 ));
 } else if (matchedText.startsWith('`') && matchedText.endsWith('`') && matchedText.length > 2) {
 spans.add(WidgetSpan(
 alignment: PlaceholderAlignment.middle,
 child: Container(
 padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
 decoration: BoxDecoration(
 color: isUser
 ? Colors.black26
 : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
 borderRadius: BorderRadius.circular(4),
 ),
 child: Text(
 matchedText.substring(1, matchedText.length - 1),
 style: base.copyWith(
 fontFamily: 'monospace',
 fontSize: (base.fontSize ?? 14) * 0.9,
 ),
 ),
 ),
 ));
 } else {
 spans.add(TextSpan(text: matchedText, style: base));
 }

 lastEnd = match.end;
 }

 if (lastEnd < raw.length) {
 spans.add(TextSpan(
 text: raw.substring(lastEnd),
 style: base,
 ));
 }

 return spans;
 }
}
