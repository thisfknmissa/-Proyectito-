import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:bus_tracker_uat/main.dart';
import 'package:bus_tracker_uat/providers/bus_tracker_provider.dart';
import 'package:bus_tracker_uat/screens/splash_screen.dart';
import 'package:bus_tracker_uat/services/campus_tile_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CampusOfflineTileProvider', () {
    test('recognizes all campus offline zoom levels', () {
      // Zoom 14
      expect(CampusOfflineTileProvider.hasOfflineAsset(14, 3737, 7151), isTrue);
      expect(CampusOfflineTileProvider.hasOfflineAsset(14, 3738, 7151), isTrue);
      expect(CampusOfflineTileProvider.hasOfflineAsset(14, 0, 0), isFalse);

      // Zoom 15
      expect(CampusOfflineTileProvider.hasOfflineAsset(15, 7475, 14302), isTrue);
      expect(CampusOfflineTileProvider.hasOfflineAsset(15, 7476, 14303), isTrue);

      // Zoom 16
      expect(CampusOfflineTileProvider.hasOfflineAsset(16, 14952, 28606), isTrue);

      // Zoom 17
      expect(CampusOfflineTileProvider.hasOfflineAsset(17, 29905, 57212), isTrue);

      // Zoom 18
      expect(CampusOfflineTileProvider.hasOfflineAsset(18, 59810, 114425), isTrue);
      expect(CampusOfflineTileProvider.hasOfflineAsset(18, 100, 100), isFalse);
    });
  });

  group('SplashScreen Widget', () {
    testWidgets('renders brand title and offline badge', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => BusTrackerProvider(),
          child: const MaterialApp(
            home: SplashScreen(),
          ),
        ),
      );

      expect(find.text('BUS TRACKER'), findsOneWidget);
      expect(find.text('CAMPUS SUR'), findsOneWidget);
      expect(find.text('100% OFFLINE'), findsOneWidget);
      expect(find.byIcon(Icons.directions_bus_rounded), findsOneWidget);
    });
  });
}
