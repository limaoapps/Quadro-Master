import 'package:flutter/services.dart';

// ════════════════════════════════════════════════════════════
// FORMATADORES DE MÁSCARA
// ════════════════════════════════════════════════════════════

class CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue nv) {
    final digits = nv.text.replaceAll(RegExp(r'\D'), '');
    final buf = StringBuffer();
    for (int i = 0; i < digits.length && i < 11; i++) {
      if (i == 3 || i == 6) buf.write('.');
      if (i == 9) buf.write('-');
      buf.write(digits[i]);
    }
    final s = buf.toString();
    return TextEditingValue(
      text: s,
      selection: TextSelection.collapsed(offset: s.length),
    );
  }
}

class CnpjInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue nv) {
    final digits = nv.text.replaceAll(RegExp(r'\D'), '');
    final buf = StringBuffer();
    for (int i = 0; i < digits.length && i < 14; i++) {
      if (i == 2 || i == 5) buf.write('.');
      if (i == 8) buf.write('/');
      if (i == 12) buf.write('-');
      buf.write(digits[i]);
    }
    final s = buf.toString();
    return TextEditingValue(
      text: s,
      selection: TextSelection.collapsed(offset: s.length),
    );
  }
}

class TelefoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue nv) {
    final digits = nv.text.replaceAll(RegExp(r'\D'), '');
    final buf = StringBuffer();
    final isCelular = digits.length > 10;
    for (int i = 0; i < digits.length && i < (isCelular ? 11 : 10); i++) {
      if (i == 0) buf.write('(');
      if (i == 2) buf.write(') ');
      if (isCelular && i == 7) buf.write('-');
      if (!isCelular && i == 6) buf.write('-');
      buf.write(digits[i]);
    }
    final s = buf.toString();
    return TextEditingValue(
      text: s,
      selection: TextSelection.collapsed(offset: s.length),
    );
  }
}

class CepInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue nv) {
    final digits = nv.text.replaceAll(RegExp(r'\D'), '');
    final buf = StringBuffer();
    for (int i = 0; i < digits.length && i < 8; i++) {
      if (i == 5) buf.write('-');
      buf.write(digits[i]);
    }
    final s = buf.toString();
    return TextEditingValue(
      text: s,
      selection: TextSelection.collapsed(offset: s.length),
    );
  }
}

class CreaInputFormatter extends TextInputFormatter {
  // CREA: ex. 123456-7/SP  ou  1234567890/SP
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue nv) {
    // Mantém como está — apenas letras, números, /, -
    final filtered = nv.text.replaceAll(RegExp(r'[^\d/\-A-Za-z]'), '').toUpperCase();
    return TextEditingValue(
      text: filtered,
      selection: TextSelection.collapsed(offset: filtered.length),
    );
  }
}

class CrtInputFormatter extends TextInputFormatter {
  // CRT é o CPF
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue nv) {
    return CpfInputFormatter().formatEditUpdate(old, nv);
  }
}

// ════════════════════════════════════════════════════════════
// VALIDADORES
// ════════════════════════════════════════════════════════════

class Validators {
  /// Valida CPF com dígitos verificadores
  static bool cpfValido(String cpf) {
    final digits = cpf.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 11) return false;
    if (RegExp(r'^(\d)\1{10}$').hasMatch(digits)) return false;

    int soma = 0;
    for (int i = 0; i < 9; i++) soma += int.parse(digits[i]) * (10 - i);
    int d1 = (soma * 10) % 11;
    if (d1 == 10 || d1 == 11) d1 = 0;
    if (d1 != int.parse(digits[9])) return false;

    soma = 0;
    for (int i = 0; i < 10; i++) soma += int.parse(digits[i]) * (11 - i);
    int d2 = (soma * 10) % 11;
    if (d2 == 10 || d2 == 11) d2 = 0;
    return d2 == int.parse(digits[10]);
  }

  /// Valida CNPJ com dígitos verificadores
  static bool cnpjValido(String cnpj) {
    final digits = cnpj.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 14) return false;
    if (RegExp(r'^(\d)\1{13}$').hasMatch(digits)) return false;

    const pesos1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
    const pesos2 = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];

    int soma = 0;
    for (int i = 0; i < 12; i++) soma += int.parse(digits[i]) * pesos1[i];
    int d1 = soma % 11 < 2 ? 0 : 11 - soma % 11;
    if (d1 != int.parse(digits[12])) return false;

    soma = 0;
    for (int i = 0; i < 13; i++) soma += int.parse(digits[i]) * pesos2[i];
    int d2 = soma % 11 < 2 ? 0 : 11 - soma % 11;
    return d2 == int.parse(digits[13]);
  }

  /// Valida telefone (10 ou 11 dígitos)
  static bool telefoneValido(String tel) {
    final digits = tel.replaceAll(RegExp(r'\D'), '');
    return digits.length == 10 || digits.length == 11;
  }

  /// Valida CEP (8 dígitos)
  static bool cepValido(String cep) {
    final digits = cep.replaceAll(RegExp(r'\D'), '');
    return digits.length == 8;
  }

  // ── Funções para uso como validator em TextFormField ──────

  static String? validarCpf(String? v) {
    if (v == null || v.trim().isEmpty) return 'CPF obrigatório';
    if (!cpfValido(v)) return 'CPF inválido';
    return null;
  }

  static String? validarCnpj(String? v) {
    if (v == null || v.trim().isEmpty) return 'CNPJ obrigatório';
    if (!cnpjValido(v)) return 'CNPJ inválido';
    return null;
  }

  static String? validarTelefone(String? v) {
    if (v == null || v.trim().isEmpty) return null; // opcional
    if (!telefoneValido(v)) return 'Telefone inválido (ex: (11) 99999-9999)';
    return null;
  }

  static String? validarCpfOuCnpj(String? v, bool isPf) {
    return isPf ? validarCpf(v) : validarCnpj(v);
  }
}
