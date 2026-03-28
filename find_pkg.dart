import 'dart:io';
import 'dart:convert';
void main() {
  final file = File('.dart_tool/package_config.json');
  final json = jsonDecode(file.readAsStringSync());
  final packages = json['packages'] as List;
  final out = File('out.txt');
  out.writeAsStringSync('');
  for (final pkg in packages) {
    if (pkg['name'].toString().contains('google_sign_in_all_platforms')) {
      out.writeAsStringSync('${pkg['name']}\n${pkg['rootUri']}\n', mode: FileMode.append);
    }
  }
}
