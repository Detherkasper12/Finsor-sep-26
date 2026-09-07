import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

void main() {
  testWidgets('Assistant message with long markdown does not overflow', (tester) async {
    const longContent = '''
**Summary**
- Item one with some detail
- Item two with more text that could wrap
- Item three

Code block:
\`\`\`
some code line 1
some code line 2
\`\`\`

A long line without breaks that might cause overflow if not wrapped properly in the layout. Lorem ipsum dolor sit amet.
''';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 400),
              child: SingleChildScrollView(
                child: MarkdownBody(
                  data: longContent.trim().replaceAll(RegExp(r'\n{3,}'), '\n\n'),
                  selectable: true,
                  shrinkWrap: true,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(MarkdownBody), findsOneWidget);
  });
}
