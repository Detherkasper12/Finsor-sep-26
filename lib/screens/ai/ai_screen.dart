import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/category.dart';
import '../../providers/categories_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../providers/sync_provider.dart';
import '../../services/ai_service.dart';
import '../../services/ai_chat_service.dart';
import '../../constants/app_theme.dart';
import '../../utils/auth_guard.dart';
import '../../widgets/ai/ai_context_picker.dart';
import '../main_screen.dart';

class ChatMessage {
  final String content;
  final bool isFromUser;
  final DateTime timestamp;
  final bool showSetContextCta;

  ChatMessage({
    required this.content,
    required this.isFromUser,
    required this.timestamp,
    this.showSetContextCta = false,
  });
}

class AIScreen extends ConsumerStatefulWidget {
  const AIScreen({super.key});

  @override
  ConsumerState<AIScreen> createState() => _AIScreenState();
}

class _AIScreenState extends ConsumerState<AIScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocus = FocusNode();

  List<ChatMessage> _messages = [];
  bool _isTyping = false;
  late AnimationController _typingAnimationController;

  AIChatContext? _financeContext;

  @override
  void initState() {
    super.initState();
    _typingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _initAssistantWelcome();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocus.dispose();
    _typingAnimationController.dispose();
    super.dispose();
  }

  void _initAssistantWelcome() {
    setState(() {
      _messages = [
        ChatMessage(
          content: '''Hi! I'm Finsor AI.

Choose a period or category to analyze your finances. Use Set context to get started.''',
          isFromUser: false,
          timestamp: DateTime.now(),
          showSetContextCta: true,
        ),
      ];
    });
  }

  void _openContextPicker({DateTimeRange? prefillDateRange}) async {
    final categories = await ref.read(categoriesProvider.future);
    final wallets = await ref.read(walletsProvider.future);
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AIContextPicker(
        initialContext: _financeContext ?? (prefillDateRange != null ? AIChatContext(dateRange: prefillDateRange) : null),
        categories: categories,
        wallets: wallets,
        onConfirm: (ctx) {
          setState(() => _financeContext = ctx);
        },
        onCancel: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  DateTimeRange? _extractDateRangeFromMessage(String msg) {
    final now = DateTime.now();
    final lower = msg.toLowerCase();
    if (lower.contains('this month') || lower.contains('this month\'s')) {
      return DateTimeRange(
        start: DateTime(now.year, now.month, 1),
        end: now,
      );
    }
    if (lower.contains('last month')) {
      final last = DateTime(now.year, now.month - 1, now.day);
      return DateTimeRange(
        start: DateTime(last.year, last.month, 1),
        end: last,
      );
    }
    if (RegExp(r'last\s+7\s+days|past\s+7\s+days|7\s+days').hasMatch(lower)) {
      return DateTimeRange(
        start: now.subtract(const Duration(days: 7)),
        end: now,
      );
    }
    final monthNames = ['january', 'february', 'march', 'april', 'may', 'june',
      'july', 'august', 'september', 'october', 'november', 'december'];
    for (var i = 0; i < monthNames.length; i++) {
      if (lower.contains(monthNames[i])) {
        var year = now.year;
        if (i + 1 > now.month) year--;
        final start = DateTime(year, i + 1, 1);
        final end = DateTime(year, i + 2, 0);
        return DateTimeRange(start: start, end: end);
      }
    }
    final dayRange = RegExp(r'(\d{1,2})[\s\-–]+(\d{1,2})\s+(august|aug|january|jan|february|feb|march|mar|april|apr|may|june|jun|july|jul|september|sep|october|oct|november|nov|december|dec)', caseSensitive: false);
    final m = dayRange.firstMatch(lower);
    if (m != null) {
      final d1 = int.tryParse(m.group(1)!) ?? 1;
      final d2 = int.tryParse(m.group(2)!) ?? 1;
      final monthStr = (m.group(3) ?? '').toLowerCase();
      final monthMap = {'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
        'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12};
      final month = monthMap[monthStr.length >= 3 ? monthStr.substring(0, 3) : monthStr] ?? 1;
      var year = now.year;
      if (month > now.month) year--;
      final start = DateTime(year, month, d1.clamp(1, 28));
      final end = DateTime(year, month, d2.clamp(1, 31));
      if (start.isBefore(end) || start.isAtSameMomentAs(end)) {
        return DateTimeRange(start: start, end: end);
      }
    }
    return null;
  }

  void _applyQuickPresetLast7Days() {
    final now = DateTime.now();
    setState(() {
      _financeContext = AIChatContext(
        dateRange: DateTimeRange(
          start: now.subtract(const Duration(days: 7)),
          end: now,
        ),
      );
    });
  }

  void _applyQuickPresetThisMonth() {
    final now = DateTime.now();
    setState(() {
      _financeContext = AIChatContext(
        dateRange: DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: now,
        ),
      );
    });
  }

  void _applyQuickPresetLastMonth() {
    final now = DateTime.now();
    final last = DateTime(now.year, now.month - 1, now.day);
    setState(() {
      _financeContext = AIChatContext(
        dateRange: DateTimeRange(
          start: DateTime(last.year, last.month, 1),
          end: last,
        ),
      );
    });
  }

  AIChatContext? _resolveContext(String text) {
    if (_financeContext != null && _financeContext!.isValid) return _financeContext;
    final range = _extractDateRangeFromMessage(text);
    if (range != null) {
      setState(() => _financeContext = AIChatContext(dateRange: range));
      return _financeContext;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => mainScaffoldKey.currentState?.openDrawer(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primary,
              child: Icon(
                Icons.smart_toy,
                color: theme.colorScheme.onPrimary,
                size: 18,
              ),
            ),
            const Gap(12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Finsor AI',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Financial Assistant',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _clearChat,
            icon: const Icon(Icons.refresh),
            tooltip: 'New Conversation',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildContextBar(),
          if (_messages.length <= 1) _buildExamplePrompts(),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return _buildTypingIndicator();
                }
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildContextBar() {
    final theme = Theme.of(context);
    final categoriesAsync = ref.watch(categoriesProvider);
    String label = 'No context';
    if (_financeContext != null) {
      if (_financeContext!.dateRange != null) {
        label = '${DateFormat.yMMMd().format(_financeContext!.dateRange!.start)} – ${DateFormat.yMMMd().format(_financeContext!.dateRange!.end)}';
      } else if (_financeContext!.categoryId != null) {
        final cats = categoriesAsync.valueOrNull ?? <Category>[];
        final cat = cats.where((c) => c.id == _financeContext!.categoryId).firstOrNull;
        label = 'Category: ${cat?.name ?? _financeContext!.categoryId}';
      }
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: theme.colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          Icon(Icons.filter_list, size: 18, color: theme.colorScheme.primary),
          const Gap(8),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: () => _openContextPicker(),
            child: const Text('Set context'),
          ),
        ],
      ),
    );
  }

  Widget _buildExamplePrompts() {
    final examples = AIService.getFinanceExamplePrompts();
    return Container(
      height: 160,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Try asking:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const Gap(8),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: examples.length,
              itemBuilder: (context, index) {
                return Container(
                  width: 200,
                  margin: const EdgeInsets.only(right: 12),
                  child: Material(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    elevation: 1,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _sendMessage(examples[index]),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              _getPromptIcon(examples[index]),
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                            const Gap(8),
                            Text(
                              examples[index],
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isFromUser;
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                CircleAvatar(
                  radius: 16,
                  backgroundColor: theme.colorScheme.primary,
                  child: Icon(
                    Icons.smart_toy,
                    color: theme.colorScheme.onPrimary,
                    size: 16,
                  ),
                ),
                const Gap(8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUser
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                    boxShadow: AppTheme.getCardShadow(
                      isDark: theme.brightness == Brightness.dark,
                    ),
                    border: isUser ? null : Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isUser)
                        Text(
                          message.content,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            height: 1.4,
                          ),
                        )
                      else
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 400),
                          child: SingleChildScrollView(
                            child: MarkdownBody(
                              data: message.content
                                  .trim()
                                  .replaceAll(RegExp(r'\n{3,}'), '\n\n'),
                              styleSheet: MarkdownStyleSheet(
                                p: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                  height: 1.4,
                                ),
                                listBullet: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                ),
                                code: theme.textTheme.bodyMedium?.copyWith(
                                  fontFamily: 'monospace',
                                  color: theme.colorScheme.onSurface,
                                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                                ),
                                codeblockDecoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              selectable: true,
                              shrinkWrap: true,
                            ),
                          ),
                        ),
                      const Gap(4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('HH:mm').format(message.timestamp),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isUser
                                  ? theme.colorScheme.onPrimary.withOpacity(0.7)
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (!isUser)
                            IconButton(
                              icon: Icon(
                                Icons.copy,
                                size: 18,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: message.content));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Copied to clipboard'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (isUser) ...[
                const Gap(8),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.person,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 16,
                  ),
                ),
              ],
            ],
          ),
          if (message.showSetContextCta) ...[
            const Gap(8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  label: const Text('Set context'),
                  avatar: const Icon(Icons.filter_list, size: 18, color: Colors.white70),
                  onPressed: () => _openContextPicker(),
                ),
                ActionChip(
                  label: const Text('Last 7 days'),
                  onPressed: () => _applyQuickPresetLast7Days(),
                ),
                ActionChip(
                  label: const Text('This month'),
                  onPressed: () => _applyQuickPresetThisMonth(),
                ),
                ActionChip(
                  label: const Text('Last month'),
                  onPressed: () => _applyQuickPresetLastMonth(),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: theme.colorScheme.primary,
            child: Icon(
              Icons.smart_toy,
              color: theme.colorScheme.onPrimary,
              size: 16,
            ),
          ),
          const Gap(8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
              boxShadow: AppTheme.getCardShadow(
                isDark: theme.brightness == Brightness.dark,
              ),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.1),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(0),
                const Gap(4),
                _buildTypingDot(1),
                const Gap(4),
                _buildTypingDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return AnimatedBuilder(
      animation: _typingAnimationController,
      builder: (context, child) {
        final v = (_typingAnimationController.value - (index * 0.2)) % 1.0;
        final opacity = v < 0.5 ? v * 2 : (1 - v) * 2;
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(opacity.clamp(0.3, 1.0)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildMessageInput() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasContext = _financeContext?.isValid ?? false;
    final sendEnabled = !_isTyping && hasContext;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.05),
            blurRadius: isDark ? 8 : 4,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.1),
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!hasContext)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Choose a period or category to analyze.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    focusNode: _messageFocus,
                    decoration: InputDecoration(
                      hintText: 'Ask about your transactions...',
                      hintStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: theme.colorScheme.outline.withOpacity(0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: theme.colorScheme.outline.withOpacity(0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: theme.colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: 3,
                    minLines: 1,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (text) {
                      if (text.trim().isNotEmpty && sendEnabled) {
                        _sendMessage(text.trim());
                      }
                    },
                  ),
                ),
                const Gap(8),
                CircleAvatar(
                  radius: 24,
                  backgroundColor: theme.colorScheme.primary,
                  child: IconButton(
                    onPressed: sendEnabled
                        ? () {
                            final text = _messageController.text.trim();
                            if (text.isNotEmpty) _sendMessage(text);
                          }
                        : null,
                    icon: Icon(
                      _isTyping ? Icons.hourglass_empty : Icons.send,
                      color: theme.colorScheme.onPrimary,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage(String text) async {
    if (_isTyping) return;
    if (!requireAuthOrShowPrompt(context)) return;

    setState(() {
      _messages.add(ChatMessage(
        content: text,
        isFromUser: true,
        timestamp: DateTime.now(),
      ));
      _isTyping = true;
    });

    _messageController.clear();
    _scrollToBottom();

    final resolvedContext = _resolveContext(text);

    if (resolvedContext == null || !resolvedContext.isValid) {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            content: 'Choose a period or category to analyze.',
            isFromUser: false,
            timestamp: DateTime.now(),
            showSetContextCta: true,
          ));
          _isTyping = false;
        });
        _scrollToBottom();
      }
      return;
    }

    try {
      final lastSyncAt = ref.read(lastSyncAtProvider);
      final useServer = AIChatService.useServerData(lastSyncAt);
      String response;

      if (useServer) {
        response = await AIChatService.sendMessage(
          'finance',
          text,
          context: resolvedContext,
          useServerData: true,
        );
      } else {
        final transactions = await ref.read(transactionsProvider.future);
        final categories = await ref.read(categoriesProvider.future);
        final wallets = await ref.read(walletsProvider.future);
        final filteredCount = AIChatService.getFilteredCount(
          resolvedContext,
          transactions,
          categories,
        );
        final tier = AIChatService.selectTier(
          text,
          transactionCount: filteredCount,
        );
        final dataset = await AIChatService.buildCompactDataset(
          resolvedContext,
          transactions,
          categories,
          wallets,
          tier: tier,
        );
        response = await AIChatService.sendMessage(
          'finance',
          text,
          context: resolvedContext,
          dataset: dataset,
        );
      }

      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            content: response,
            isFromUser: false,
            timestamp: DateTime.now(),
          ));
          _isTyping = false;
        });
        _scrollToBottom();
      }
    } on ContextRequiredException {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            content: 'Choose a period or category to analyze.',
            isFromUser: false,
            timestamp: DateTime.now(),
            showSetContextCta: true,
          ));
          _isTyping = false;
        });
        _scrollToBottom();
      }
    } on AuthRequiredException catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            content: e.message,
            isFromUser: false,
            timestamp: DateTime.now(),
          ));
          _isTyping = false;
        });
        _scrollToBottom();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } on AIChatException catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            content: e.userMessage,
            isFromUser: false,
            timestamp: DateTime.now(),
          ));
          _isTyping = false;
        });
        _scrollToBottom();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.userMessage),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => _sendMessage(text),
            ),
          ),
        );
      }
    } on FunctionException catch (e) {
      if (mounted) {
        final msg = e.status == 401
            ? 'Session expired. Please sign in again.'
            : (e.reasonPhrase ?? 'Request failed.');
        setState(() {
          _messages.add(ChatMessage(
            content: msg,
            isFromUser: false,
            timestamp: DateTime.now(),
          ));
          _isTyping = false;
        });
        _scrollToBottom();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceFirst(RegExp(r'^Exception:?\s*'), '');
        setState(() {
          _messages.add(ChatMessage(
            content: msg.isNotEmpty ? msg : 'Sorry, an error occurred. Please try again.',
            isFromUser: false,
            timestamp: DateTime.now(),
          ));
          _isTyping = false;
        });
        _scrollToBottom();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Something went wrong. You can try again.'),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => _sendMessage(text),
            ),
          ),
        );
      }
    }
  }

  void _clearChat() {
    setState(() {
      _initAssistantWelcome();
      _isTyping = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  IconData _getPromptIcon(String prompt) {
    final lower = prompt.toLowerCase();
    if (lower.contains('save') || lower.contains('saving')) return Icons.savings;
    if (lower.contains('spend') || lower.contains('expense')) return Icons.shopping_cart;
    if (lower.contains('budget')) return Icons.account_balance_wallet;
    if (lower.contains('pattern') || lower.contains('analysis')) return Icons.analytics;
    if (lower.contains('tip') || lower.contains('advice')) return Icons.lightbulb;
    return Icons.help_outline;
  }
}
