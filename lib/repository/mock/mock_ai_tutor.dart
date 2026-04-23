// Mock AI Tutor that simulates Gemini/ChatGPT responses.
// Returns canned educational responses with realistic delay.

class MockAiTutor {
  static final Map<String, String> _responses = {
    'design': 'Great question about design! UI/UX design is all about creating intuitive, user-centered experiences. The key principles include:\n\n1. **Consistency** — Keep visual elements uniform\n2. **Hierarchy** — Guide the user\'s eye with size and contrast\n3. **Feedback** — Let users know their actions are registered\n4. **Accessibility** — Design for everyone\n\nWould you like me to dive deeper into any of these principles?',
    'flutter': 'Flutter is Google\'s UI toolkit for building natively compiled apps for mobile, web, and desktop from a single codebase. Here\'s what makes it powerful:\n\n• **Hot Reload** — See changes instantly\n• **Widget-based** — Everything is a widget\n• **Dart language** — Fast, productive, and type-safe\n• **Cross-platform** — One codebase, multiple platforms\n\nWhat specific aspect of Flutter would you like to explore?',
    'python': 'Python is one of the most versatile programming languages! It\'s widely used in:\n\n• **Data Science** — pandas, numpy, matplotlib\n• **Machine Learning** — TensorFlow, PyTorch, scikit-learn\n• **Web Development** — Django, Flask\n• **Automation** — Scripting and task automation\n\nIts simple syntax makes it perfect for beginners. What area interests you most?',
    'career': 'Here are some key tips for advancing your tech career:\n\n1. **Build a portfolio** — Showcase real projects, not just tutorials\n2. **Network actively** — Attend meetups, join communities\n3. **Learn continuously** — Stay updated with industry trends\n4. **Specialize** — Deep expertise in one area is more valuable than surface knowledge in many\n5. **Soft skills matter** — Communication and teamwork are essential\n\nWould you like specific advice for your field?',
    'math': 'Mathematics is the foundation of computer science and data analysis. Key areas include:\n\n• **Linear Algebra** — Essential for ML and graphics\n• **Statistics** — Critical for data science\n• **Calculus** — Used in optimization algorithms\n• **Discrete Math** — Foundation of computer science\n\nWhich area would you like to practice?',
    'programming': 'Programming fundamentals are universal across all languages:\n\n1. **Variables & Data Types** — Storing information\n2. **Control Flow** — if/else, loops, switches\n3. **Functions** — Reusable blocks of code\n4. **OOP** — Classes, objects, inheritance\n5. **Data Structures** — Arrays, lists, maps, trees\n\nMastering these concepts will help you learn any language quickly. What would you like to practice?',
  };

  static const String _defaultResponse =
      'That\'s an interesting topic! Let me help you understand it better.\n\nBased on the latest educational research, here are the key points to consider:\n\n1. **Start with fundamentals** — Build a strong foundation before moving to advanced topics\n2. **Practice regularly** — Consistent practice is more effective than cramming\n3. **Apply what you learn** — Build projects to reinforce concepts\n4. **Seek feedback** — Get your work reviewed by peers or mentors\n\nWould you like me to create a study plan or practice questions on this topic?';

  /// Returns a mock AI response based on the user's message.
  /// Simulates network delay to feel realistic.
  static Future<String> getResponse(String userMessage) async {
    await Future.delayed(const Duration(milliseconds: 1200));

    final lower = userMessage.toLowerCase();

    for (final entry in _responses.entries) {
      if (lower.contains(entry.key)) {
        return entry.value;
      }
    }

    return _defaultResponse;
  }
}
