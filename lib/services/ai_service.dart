class AIService {
  static List<String> getGeneralExamplePrompts() {
    return [
      'How can I save more money?',
      'Explain the 50/30/20 budgeting rule',
      'How much should I have in an emergency fund?',
      'What is dollar-cost averaging?',
      'How can I reduce my tax burden?',
    ];
  }

  static List<String> getFinanceExamplePrompts() {
    return [
      'Summarize my spending for this period',
      'What are my top expense categories?',
      'Identify unusual transactions',
      'Compare income vs expenses',
      'Any spending patterns or trends?',
    ];
  }
}
