/// Validadores de formulário para uso em toda a aplicação.
class PhoneValidator {
  static String? validate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Campo obrigatório';
    }
    // Formato esperado: +5511999887766
    final phoneRegex = RegExp(r'^\+[1-9]\d{1,14}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Formato de telefone inválido (+55...)';
    }
    return null;
  }
}

class EmailValidator {
  static String? validate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Campo obrigatório';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'E-mail inválido';
    }
    return null;
  }
}

class BudgetRangeValidator {
  static String? validate(double? min, double? max) {
    if (min == null || max == null) return 'Valores obrigatórios';
    if (min < 0 || max < 0) return 'Valores não podem ser negativos';
    if (min > max) return 'Mínimo não pode ser maior que o máximo';
    return null;
  }
}

class DateRangeValidator {
  static String? validate(DateTime? start, DateTime? end) {
    if (start == null || end == null) return 'Datas obrigatórias';
    if (end.isBefore(start)) return 'Data de retorno não pode ser anterior à partida';
    return null;
  }
}
