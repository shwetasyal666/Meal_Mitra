import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mealmitra/app/app.dart';
import 'package:mealmitra/app/bootstrap.dart';

Future<void> main() async {
  await bootstrap();
  runApp(const ProviderScope(child: MealMitraApp()));
}
