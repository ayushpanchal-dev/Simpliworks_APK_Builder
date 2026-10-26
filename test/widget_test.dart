import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simpliworks_apk_builder/main.dart';
import 'package:simpliworks_apk_builder/services/client_registry_service.dart';
import 'package:simpliworks_apk_builder/services/build_orchestrator.dart';

void main() {
  testWidgets('Simpliworks APK Builder Smoke Test', (WidgetTester tester) async {
    // Desktop window dimensions for testing
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final registry = ClientRegistryService();
    await registry.initialize();
    final orchestrator = BuildOrchestrator();

    await tester.pumpWidget(SimpliworksApkBuilderApp(
      registryService: registry,
      orchestrator: orchestrator,
    ));

    expect(find.byType(SimpliworksApkBuilderApp), findsOneWidget);
  });
}
