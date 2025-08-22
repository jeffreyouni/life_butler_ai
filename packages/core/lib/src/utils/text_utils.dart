/// Utility functions for text processing
class TextUtils {
  /// Remove markdown formatting from text
  static String stripMarkdown(String text) {
    return text
        // Remove headers
        .replaceAll(RegExp(r'^#{1,6}\s+'), '')
        // Remove bold/italic
        .replaceAll(RegExp(r'\*\*(.+?)\*\*'), r'$1')
        .replaceAll(RegExp(r'\*(.+?)\*'), r'$1')
        .replaceAll(RegExp(r'__(.+?)__'), r'$1')
        .replaceAll(RegExp(r'_(.+?)_'), r'$1')
        // Remove links
        .replaceAll(RegExp(r'\[([^\]]+)\]\([^)]+\)'), r'$1')
        // Remove code blocks
        .replaceAll(RegExp(r'```[\s\S]*?```'), '')
        .replaceAll(RegExp(r'`([^`]+)`'), r'$1')
        // Remove lists
        .replaceAll(RegExp(r'^\s*[-*+]\s+', multiLine: true), '')
        .replaceAll(RegExp(r'^\s*\d+\.\s+', multiLine: true), '')
        // Clean up whitespace
        .replaceAll(RegExp(r'\n+'), '\n')
        .trim();
  }

  /// Truncate text to a maximum length with ellipsis
  static String truncate(String text, int maxLength, {String ellipsis = '...'}) {
    if (text.length <= maxLength) return text;
    
    final truncateAt = maxLength - ellipsis.length;
    if (truncateAt <= 0) return ellipsis;
    
    // Try to break at word boundary
    final words = text.substring(0, truncateAt).split(' ');
    if (words.length > 1) {
      words.removeLast(); // Remove potentially partial word
      final result = words.join(' ');
      if (result.isNotEmpty) {
        return result + ellipsis;
      }
    }
    
    return text.substring(0, truncateAt) + ellipsis;
  }

  /// Extract sentences from text
  static List<String> extractSentences(String text) {
    // Simple sentence splitting on periods, exclamation marks, and question marks
    return text
        .split(RegExp(r'[.!?]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  /// Count approximate tokens in text (rough estimate: 1 token ≈ 4 characters)
  static int estimateTokens(String text) {
    return (text.length / 4).ceil();
  }

  /// Clean and normalize text for search
  static String normalizeForSearch(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Extract keywords from text
  static Set<String> extractKeywords(String text, {int minLength = 3}) {
    final words = normalizeForSearch(text)
        .split(' ')
        .where((word) => word.length >= minLength)
        .toSet();

    // Remove common stop words
    final stopWords = <String>{
      'the', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for', 'of', 'with',
      'by', 'is', 'are', 'was', 'were', 'be', 'been', 'have', 'has', 'had',
      'do', 'does', 'did', 'will', 'would', 'could', 'should', 'may', 'might',
      'can', 'this', 'that', 'these', 'those', 'i', 'you', 'he', 'she', 'it',
      'we', 'they', 'me', 'him', 'her', 'us', 'them', 'my', 'your', 'his',
      'her', 'its', 'our', 'their', 'from', 'up', 'about', 'into', 'over',
      'after', 'all', 'any', 'both', 'each', 'few', 'more', 'most', 'other',
      'some', 'such', 'only', 'own', 'same', 'so', 'than', 'too', 'very'
    };

    return words.difference(stopWords);
  }

  /// Calculate text similarity using Jaccard coefficient
  static double jaccardSimilarity(String text1, String text2) {
    final words1 = extractKeywords(text1);
    final words2 = extractKeywords(text2);

    if (words1.isEmpty && words2.isEmpty) return 1.0;
    if (words1.isEmpty || words2.isEmpty) return 0.0;

    final intersection = words1.intersection(words2);
    final union = words1.union(words2);

    return intersection.length / union.length;
  }

  /// Remove extra whitespace and normalize line endings
  static String cleanWhitespace(String text) {
    return text
        .replaceAll(RegExp(r'\r\n'), '\n')  // Windows line endings
        .replaceAll(RegExp(r'\r'), '\n')    // Mac line endings
        .replaceAll(RegExp(r'\t'), ' ')     // Replace tabs with spaces
        .replaceAll(RegExp(r' +'), ' ')     // Multiple spaces to single space
        .replaceAll(RegExp(r'\n +'), '\n')  // Remove leading spaces on lines
        .replaceAll(RegExp(r' +\n'), '\n')  // Remove trailing spaces on lines
        .replaceAll(RegExp(r'\n{3,}'), '\n\n') // Multiple newlines to double
        .trim();
  }

  /// Convert text to title case
  static String toTitleCase(String text) {
    if (text.isEmpty) return text;
    
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  /// Generate a slug from text (URL-friendly string)
  static String generateSlug(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s-]'), '')  // Remove non-word chars except spaces and hyphens
        .replaceAll(RegExp(r'\s+'), '-')      // Replace spaces with hyphens
        .replaceAll(RegExp(r'-+'), '-')       // Replace multiple hyphens with single
        .replaceAll(RegExp(r'^-+|-+$'), '');  // Remove leading/trailing hyphens
  }

  /// Check if text contains any of the given patterns (case-insensitive)
  static bool containsAny(String text, List<String> patterns) {
    final textLower = text.toLowerCase();
    return patterns.any((pattern) => textLower.contains(pattern.toLowerCase()));
  }

  /// Highlight search terms in text
  static String highlightTerms(String text, List<String> terms, {
    String startTag = '<mark>',
    String endTag = '</mark>',
  }) {
    if (terms.isEmpty) return text;
    
    String result = text;
    for (final term in terms) {
      if (term.isEmpty) continue;
      
      final regex = RegExp(RegExp.escape(term), caseSensitive: false);
      result = result.replaceAllMapped(regex, (match) {
        return '$startTag${match.group(0)}$endTag';
      });
    }
    
    return result;
  }

  /// Calculate reading time in minutes (average 200 words per minute)
  static int calculateReadingTime(String text, {int wordsPerMinute = 200}) {
    final wordCount = text.split(RegExp(r'\s+')).length;
    return (wordCount / wordsPerMinute).ceil();
  }

  /// Extract URLs from text
  static List<String> extractUrls(String text) {
    final urlRegex = RegExp(
      r'https?://(?:[-\w.])+(?::\d+)?(?:/(?:[\w/_.])*)?(?:\?(?:[\w&=%.])*)?(?:#(?:\w)*)?',
      caseSensitive: false,
    );
    
    return urlRegex.allMatches(text)
        .map((match) => match.group(0)!)
        .toList();
  }

  /// Extract email addresses from text
  static List<String> extractEmails(String text) {
    final emailRegex = RegExp(
      r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b',
    );
    
    return emailRegex.allMatches(text)
        .map((match) => match.group(0)!)
        .toList();
  }

  /// Escape special characters for regex
  static String escapeRegex(String text) {
    return text.replaceAllMapped(RegExp(r'[.*+?^${}()|[\]\\]'), (match) {
      return '\\${match.group(0)}';
    });
  }
}
