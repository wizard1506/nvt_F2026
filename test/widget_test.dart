import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novitierra_f/main.dart';
import 'package:novitierra_f/screens/home_screen.dart';
import 'package:novitierra_f/services/sesion.dart';

void main() {
  testWidgets('Login screen renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const NovitierraApp());

    expect(find.text('Novitierra'), findsOneWidget);
    expect(find.text('Usuario'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
    expect(find.text('Iniciar Sesión'), findsOneWidget);
  });

  testWidgets('Administración solo es visible para el rol 1', (
    WidgetTester tester,
  ) async {
    Sesion.instance.clear();
    Sesion.instance.rol = 4;
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    expect(find.text('Administración'), findsNothing);

    Sesion.instance.rol = 1;
    await tester.pumpWidget(
      const MaterialApp(home: HomeScreen(key: ValueKey('admin'))),
    );
    await tester.pump();

    expect(find.text('Administración'), findsOneWidget);

    Sesion.instance.clear();
  });
}
