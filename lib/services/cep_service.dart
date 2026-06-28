import 'dart:convert';
import 'package:http/http.dart' as http;

class EnderecoViaCep {
  final String cep;
  final String logradouro;
  final String bairro;
  final String cidade;
  final String estado; // sempre 2 letras maiúsculas (UF)
  final bool erro;

  EnderecoViaCep({
    required this.cep,
    required this.logradouro,
    required this.bairro,
    required this.cidade,
    required this.estado,
    this.erro = false,
  });
}

class CepService {
  /// Busca o CEP na API ViaCEP.
  /// Tenta primeiro via HTTPS direto; se falhar (CORS no web), tenta proxy alternativo.
  static Future<EnderecoViaCep?> buscarCep(String cep) async {
    final digits = cep.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 8) return null;

    // Tentativa 1 — ViaCEP direto
    try {
      final uri = Uri.parse('https://viacep.com.br/ws/$digits/json/');
      final resp = await http.get(uri, headers: {
        'Accept': 'application/json',
      }).timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        if (data['erro'] == true || data['erro'] == 'true') {
          return EnderecoViaCep(cep: digits, logradouro: '', bairro: '', cidade: '', estado: '', erro: true);
        }
        final uf = ((data['uf'] ?? '') as String).toUpperCase();
        return EnderecoViaCep(
          cep: data['cep'] ?? digits,
          logradouro: data['logradouro'] ?? '',
          bairro: data['bairro'] ?? '',
          cidade: data['localidade'] ?? '',
          estado: uf,
        );
      }
    } catch (_) {
      // Ignora: tenta alternativa
    }

    // Tentativa 2 — API alternativa (brasilapi)
    try {
      final uri = Uri.parse('https://brasilapi.com.br/api/cep/v1/$digits');
      final resp = await http.get(uri, headers: {
        'Accept': 'application/json',
      }).timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final uf = ((data['state'] ?? '') as String).toUpperCase();
        return EnderecoViaCep(
          cep: data['cep'] ?? digits,
          logradouro: data['street'] ?? '',
          bairro: data['neighborhood'] ?? '',
          cidade: data['city'] ?? '',
          estado: uf,
        );
      }
    } catch (_) {
      // Falhou também
    }

    return null;
  }
}
