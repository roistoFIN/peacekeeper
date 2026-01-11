import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peacekeeper/screens/paywall_screen.dart';
import 'package:peacekeeper/services/subscription_service.dart';
import 'package:peacekeeper/services/debug_service.dart';
import 'package:purchases_flutter/models/offering_wrapper.dart';
import 'package:purchases_flutter/models/offerings_wrapper.dart';
// We need to mock SubscriptionService or it will try to call Platform Channels
// Since SubscriptionService uses static methods, we might need to rely on it returning defaults or handling errors gracefully.
// However, the PaywallScreen calls SubscriptionService.getOfferings() in initState.
// If we run this in a test environment without mocking, it might throw MissingPluginException.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('PaywallScreen renders without overflow on small screens', (WidgetTester tester) async {
    // Set screen size to small (iPhone SE width approx 320)
    tester.view.physicalSize = const Size(320 * 2, 568 * 2); // logical 320x568 @ 2x pixel ratio
    tester.view.devicePixelRatio = 2.0;

    // We can't easily mock static methods of SubscriptionService in Dart without a wrapper.
    // However, the PaywallScreen catches errors or handles nulls? 
    // Let's look at PaywallScreen again. It calls SubscriptionService.getOfferings().
    // We should probably rely on the fact that MissingPluginException might be caught or ignored in some contexts, 
    // but usually it crashes the test.
    
    // To properly test this, we would need to Refactor SubscriptionService to be injectable, 
    // or use a MethodChannel mock for RevenueCat. 
    
    // For now, let's try to pump the widget. If it fails due to Platform Channel, 
    // we know we need to mock the channel.
    
    // RevenueCat channel: 'purchases_flutter'
    const MethodChannel channel = MethodChannel('purchases_flutter');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'getOfferings') {
        return {
          'current': {
            'identifier': 'default',
            'serverDescription': 'Standard',
            'availablePackages': [],
            'lifetime': null,
            'annual': null,
            'sixMonth': null,
            'threeMonth': null,
            'twoMonth': null,
            'monthly': null,
            'weekly': null,
            'metadata': <String, Object>{},
          },
          'all': <String, dynamic>{}
        };
      }
      return null;
    });

    await tester.pumpWidget(const MaterialApp(home: PaywallScreen()));
    
    // Wait for async
    await tester.pump();

    // Verify Title (Changed from "Unlock Peacekeeper" to "Unlock Premium")
    expect(find.text('Unlock Premium'), findsOneWidget);
    
    // Verify Long Text exists
    expect(find.text('AI help with feelings, needs & neutral phrasing'), findsOneWidget);

    // Reset view
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });
}
