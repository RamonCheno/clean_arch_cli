import 'package:test/test.dart';
import 'package:clean_arch_cli/src/utils/string_ext.dart';

void main() {
  group('toSnakeCase', () {
    test('camelCase → snake_case', () {
      expect('myModule'.toSnakeCase(), 'my_module');
    });
    test('PascalCase → snake_case', () {
      expect('MyModule'.toSnakeCase(), 'my_module');
    });
    test('already snake_case', () {
      expect('my_module'.toSnakeCase(), 'my_module');
    });
    test('single word', () {
      expect('home'.toSnakeCase(), 'home');
    });
  });

  group('toPascalCase', () {
    test('snake_case → PascalCase', () {
      expect('my_module'.toPascalCase(), 'MyModule');
    });
    test('single word', () {
      expect('home'.toPascalCase(), 'Home');
    });
  });

  group('toPlural', () {
    test('regular word adds s', () {
      expect('product'.toPlural(), 'products');
    });
    test('word ending in s adds es', () {
      expect('status'.toPlural(), 'statuses');
    });
    test('word ending in y → ies', () {
      expect('category'.toPlural(), 'categories');
    });
  });

  group('isValidIdentifier', () {
    test('valid lowercase', () => expect('home'.isValidIdentifier, isTrue));
    test('valid with numbers', () => expect('module2'.isValidIdentifier, isTrue));
    test('valid snake_case', () => expect('my_module'.isValidIdentifier, isTrue));
    test('invalid with spaces', () => expect('my module'.isValidIdentifier, isFalse));
    test('invalid starts with number', () => expect('2module'.isValidIdentifier, isFalse));
    test('invalid with hyphen', () => expect('my-module'.isValidIdentifier, isFalse));
  });
}
