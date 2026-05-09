class AppValidators {
  static String? required(String? value) {
    if (value == null || value.trim().isEmpty) return 'Campo obrigatório';
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) return 'E-mail inválido';
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Telefone obrigatório';
    final cleanPhone = value.replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.length < 10) return 'Telefone inválido';
    return null;
  }

  static String? validateDocument(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final doc = value.replaceAll(RegExp(r'\D'), '');
    
    if (doc.length == 11) {
      if (RegExp(r'^(\d)\1{10}$').hasMatch(doc)) return 'CPF inválido';
      return null;
    } else if (doc.length == 14) {
      if (RegExp(r'^(\d)\1{13}$').hasMatch(doc)) return 'CNPJ inválido';
      return null;
    }
    return 'Documento deve ter 11 (CPF) ou 14 (CNPJ) dígitos';
  }
}
