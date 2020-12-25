import 'package:crypto/crypto.dart';
import 'dart:math';
import 'dart:convert';

String _randomString(int length) {
  final rand = Random();
  final units = List.generate(
    length,
        (index) => rand.nextInt(33) + 89,
  );

  return String.fromCharCodes(units);
}

String _md5(String input) {
  return md5.convert(utf8.encode(input)).toString();
}

class AuthToken {
  final String token;
  final String salt;

  AuthToken._(this.token, this.salt);

  factory AuthToken(String password) {
    final salt = _randomString(5);
    return AuthToken._(_md5('$password$salt'), salt);
  }
}
