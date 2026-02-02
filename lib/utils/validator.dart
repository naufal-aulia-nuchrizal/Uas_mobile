class Validator {
  /// Validate email format
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'Email is required';
    }
    const emailPattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
    final regExp = RegExp(emailPattern);
    if (!regExp.hasMatch(email)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  /// Validate password strength
  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password is required';
    }
    if (password.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain an uppercase letter';
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain a number';
    }
    return null;
  }

  /// Validate required field
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validate phone number
  static String? validatePhoneNumber(String? phoneNumber) {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      return 'Phone number is required';
    }
    const phonePattern = r'^\d{10,}$';
    final regExp = RegExp(phonePattern);
    if (!regExp.hasMatch(phoneNumber)) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  /// Validate minimum length
  static String? validateMinLength(String? value, int minLength) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    if (value.length < minLength) {
      return 'Must be at least $minLength characters';
    }
    return null;
  }

  /// Validate maximum length
  static String? validateMaxLength(String? value, int maxLength) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    if (value.length > maxLength) {
      return 'Must be at most $maxLength characters';
    }
    return null;
  }
}
