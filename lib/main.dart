import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'services/api_service.dart';
import 'services/cache_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService().init();
  await CacheService().init();
  await NotificationService().init();
  runApp(const ProviderScope(child: LawyerApp()));
}
