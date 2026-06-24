import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'providers/activity_provider.dart';
import 'providers/proof_provider.dart';
import 'providers/timer_provider.dart';
import 'services/local_database_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr');
  await Hive.initFlutter('recruit_proof');

  final database = LocalDatabaseService();
  await database.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ActivityProvider(database)..load(),
        ),
        ChangeNotifierProvider(create: (_) => ProofProvider(database)..load()),
        ChangeNotifierProvider(create: (_) => TimerProvider()),
      ],
      child: const RecruitProofApp(),
    ),
  );
}
