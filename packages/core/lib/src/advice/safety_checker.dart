import 'package:meta/meta.dart';

/// Safety checker for advice generation
class SafetyChecker {
  static const Set<String> medicalTerms = {
    'medicine', 'medication', 'drug', 'prescription', 'doctor', 'hospital',
    'disease', 'illness', 'symptoms', 'diagnosis', 'treatment', 'therapy',
    'pain', 'injury', 'blood', 'heart', 'cancer', 'diabetes', 'depression',
    'anxiety', 'mental health', 'suicide', 'self-harm'
  };

  static const Set<String> financialTerms = {
    'investment', 'stock', 'bond', 'trading', 'loan', 'mortgage', 'insurance',
    'tax', 'taxes', 'debt', 'credit', 'financial advice', 'money management',
    'retirement', 'pension', 'savings', 'portfolio'
  };

  static const Set<String> legalTerms = {
    'legal', 'law', 'lawyer', 'attorney', 'court', 'lawsuit', 'contract',
    'agreement', 'rights', 'liability', 'criminal', 'civil', 'divorce',
    'custody', 'will', 'estate', 'immigration'
  };

  /// Check if content requires safety disclaimers
  static SafetyResult checkSafety(String query, String content) {
    final queryLower = query.toLowerCase();
    final contentLower = content.toLowerCase();
    final combinedText = '$queryLower $contentLower';

    final warnings = <SafetyWarning>[];

    // Check for medical content
    if (_containsAny(combinedText, medicalTerms)) {
      warnings.add(SafetyWarning.medical);
    }

    // Check for financial content
    if (_containsAny(combinedText, financialTerms)) {
      warnings.add(SafetyWarning.financial);
    }

    // Check for legal content
    if (_containsAny(combinedText, legalTerms)) {
      warnings.add(SafetyWarning.legal);
    }

    // Check for emergency situations
    if (_containsEmergencyTerms(combinedText)) {
      warnings.add(SafetyWarning.emergency);
    }

    return SafetyResult(warnings: warnings);
  }

  static bool _containsAny(String text, Set<String> terms) {
    return terms.any((term) => text.contains(term));
  }

  static bool _containsEmergencyTerms(String text) {
    const emergencyTerms = {
      'suicide', 'kill myself', 'end my life', 'want to die', 'self-harm',
      'emergency', 'urgent', 'crisis', 'help me', 'desperate'
    };
    return _containsAny(text, emergencyTerms);
  }
}

@immutable
class SafetyResult {
  const SafetyResult({required this.warnings});

  final List<SafetyWarning> warnings;

  bool get hasMedicalWarning => warnings.contains(SafetyWarning.medical);
  bool get hasFinancialWarning => warnings.contains(SafetyWarning.financial);
  bool get hasLegalWarning => warnings.contains(SafetyWarning.legal);
  bool get hasEmergencyWarning => warnings.contains(SafetyWarning.emergency);
  bool get hasAnyWarning => warnings.isNotEmpty;
}

enum SafetyWarning {
  medical,
  financial,
  legal,
  emergency,
}

/// Get disclaimer text for each warning type
extension SafetyWarningExtension on SafetyWarning {
  String get disclaimer {
    switch (this) {
      case SafetyWarning.medical:
        return '⚠️ Medical Disclaimer: This advice is not professional medical advice. '
            'Always consult with a qualified healthcare provider for medical concerns.';
      case SafetyWarning.financial:
        return '⚠️ Financial Disclaimer: This is not professional financial advice. '
            'Consider consulting with a qualified financial advisor for important financial decisions.';
      case SafetyWarning.legal:
        return '⚠️ Legal Disclaimer: This is not legal advice. '
            'Consult with a qualified attorney for legal matters.';
      case SafetyWarning.emergency:
        return '🚨 Emergency Notice: If you are in crisis or having thoughts of self-harm, '
            'please contact emergency services or a crisis helpline immediately.';
    }
  }

  String get actionButton {
    switch (this) {
      case SafetyWarning.medical:
        return 'Find Healthcare Provider';
      case SafetyWarning.financial:
        return 'Find Financial Advisor';
      case SafetyWarning.legal:
        return 'Find Legal Counsel';
      case SafetyWarning.emergency:
        return 'Get Emergency Help';
    }
  }
}
