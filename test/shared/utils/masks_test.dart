import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/shared/utils/masks.dart';

TextEditingValue _type(TextInputFormatter f, String text) =>
    f.formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: text));

void main() {
  group('formatadores de entrada', () {
    test('CPF vai ganhando pontos e traço enquanto digita', () {
      final f = cpfInputFormatter();
      expect(_type(f, '123').text, '123');
      expect(_type(f, '1234').text, '123.4');
      expect(_type(f, '123456789').text, '123.456.789');
      expect(_type(f, '12345678901').text, '123.456.789-01');
    });

    test('ignora o que não é dígito e corta o excesso', () {
      final f = cpfInputFormatter();
      expect(_type(f, 'abc123.456-789xx01999').text, '123.456.789-01');
    });

    test('o cursor fica sempre no fim do texto formatado', () {
      final v = _type(cpfInputFormatter(), '12345');
      expect(v.selection, TextSelection.collapsed(offset: v.text.length));
    });

    test('texto vazio continua vazio', () {
      expect(_type(cpfInputFormatter(), '').text, '');
      expect(_type(cpfInputFormatter(), 'abc').text, '');
    });

    test('CEP, celular, fixo e data de nascimento', () {
      expect(_type(cepInputFormatter(), '74000123').text, '74000-123');
      expect(
        _type(phoneInputFormatter(), '62999887766').text,
        '(62) 99988-7766',
      );
      expect(
        _type(landlineInputFormatter(), '6233221100').text,
        '(62) 3322-1100',
      );
      expect(_type(birthDateInputFormatter(), '01022000').text, '01/02/2000');
    });

    test('passaporte vira maiúsculo sem mexer no resto', () {
      final v = _type(passportInputFormatter(), 'ab123456');
      expect(v.text, 'AB123456');
    });
  });

  group('onlyDigits', () {
    test('mantém só os dígitos', () {
      expect(onlyDigits('(62) 99988-7766'), '62999887766');
      expect(onlyDigits('sem numero'), '');
    });
  });

  group('maskCpf', () {
    test('esconde tudo menos os dois últimos dígitos', () {
      expect(maskCpf('12345678901'), '•••.•••.•••-01');
      expect(maskCpf('123.456.789-01'), '•••.•••.•••-01');
    });

    test('valor que não é um CPF de 11 dígitos volta como veio', () {
      expect(maskCpf('123'), '123');
      expect(maskCpf(''), '');
    });
  });

  group('maskEmail', () {
    test('mostra 2 letras do nome e o domínio inteiro', () {
      expect(maskEmail('lucas@gmail.com'), 'lu••••@gmail.com');
    });

    test('nome curto aparece inteiro', () {
      expect(maskEmail('ab@x.com'), 'ab••••@x.com');
      expect(maskEmail('a@x.com'), 'a••••@x.com');
    });

    test('sem arroba ou sem nome, não mexe', () {
      expect(maskEmail('semarroba'), 'semarroba');
      expect(maskEmail('@dominio.com'), '@dominio.com');
    });
  });

  group('maskPhone', () {
    test('celular de 11 dígitos mostra DDD e primeiro dígito', () {
      expect(maskPhone('62999887766'), '(62) 9••••-••••');
    });

    test('fixo de 10 dígitos mostra só o DDD', () {
      expect(maskPhone('6233221100'), '(62) ••••-••••');
    });

    test('número curto demais volta como veio', () {
      expect(maskPhone('99887766'), '99887766');
    });
  });
}
