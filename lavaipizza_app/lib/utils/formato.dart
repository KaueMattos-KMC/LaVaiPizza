// Formatação em português do Brasil, sem dependências externas.

/// 1234.5 -> "R$ 1.234,50"
String brl(num valor) {
  final negativo = valor < 0;
  final centavos = (valor.abs() * 100).round();
  final inteiro = (centavos ~/ 100).toString();
  final decimais = (centavos % 100).toString().padLeft(2, '0');

  final grupos = StringBuffer();
  for (var i = 0; i < inteiro.length; i++) {
    if (i > 0 && (inteiro.length - i) % 3 == 0) grupos.write('.');
    grupos.write(inteiro[i]);
  }

  return '${negativo ? '-' : ''}R\$ $grupos,$decimais';
}

/// 20.0 -> "20" ; 12.5 -> "12,5" (usado no selo "-20%")
String numero(num valor) {
  if (valor == valor.roundToDouble()) return valor.toInt().toString();
  return valor.toString().replaceAll('.', ',');
}

String _dois(int n) => n.toString().padLeft(2, '0');

/// 19:54
String hora(DateTime data) => '${_dois(data.hour)}:${_dois(data.minute)}';

/// 19:54:37
String horaComSegundos(DateTime data) => '${hora(data)}:${_dois(data.second)}';
