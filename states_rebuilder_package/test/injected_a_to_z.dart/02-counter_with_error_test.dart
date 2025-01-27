// ignore_for_file: use_key_in_widget_constructors, file_names, prefer_const_constructors
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:states_rebuilder/states_rebuilder.dart';

class Counter {
  final int _incrementBy;
  Counter({int incrementBy = 1}) : _incrementBy = incrementBy;
  int _count = 0;
  int get count => _count * _incrementBy;
  void increment() {
    //This counter will throw randomly
    //
    //The app can not be tested unless this counter is mocked
    if (Random().nextBool()) {
      throw Exception('Counter Error');
    }
    _count++;
  }
}

//used for the propose of testing demonstration
int? dataFromInjection;
String? errorFromInjection;

final counter = RM.inject<Counter>(
  () => Counter(),
  initialState: Counter(),
  sideEffects: SideEffects.onAll(
    onWaiting: null,
    onError: (e, s) => errorFromInjection = e.message,
    onData: (counter) => dataFromInjection = counter.count,
  ),
);

class CounterApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: OnBuilder<Counter>.data(
        listenTo: counter,
        builder: (data) => Text('${data.count}'),
      ),
    );
  }
}

//To test the app we have to use a fake counter
class FakeCounter extends Counter {
  final bool shouldThrow;
  FakeCounter({int incrementBy = 1, this.shouldThrow = false})
      : super(incrementBy: incrementBy);

  @override
  int get count => _count * _incrementBy;

  @override
  void increment() {
    //when shouldThrow is true the counter throws
    if (shouldThrow) {
      throw Exception('Counter Error');
    }
    _count++;
  }
}

void main() {
  setUp(() {
    //Default injected mock
    //It is set to incrementBy 2
    counter.injectMock(() => FakeCounter(incrementBy: 2));
  });
  testWidgets('should increment counter', (tester) async {
    await tester.pumpWidget(CounterApp());
    expect(find.text('0'), findsOneWidget);
    counter.setState((s) => s.increment());
    await tester.pump();
    expect(find.text('2'), findsOneWidget);
    counter.setState((s) => s.increment());
    await tester.pump();
    expect(find.text('4'), findsOneWidget);
  });
  testWidgets('should override counter injection', (tester) async {
    //we can override the mocked counter instance for a particular test
    counter.injectMock(() => FakeCounter(incrementBy: 5));
    await tester.pumpWidget(CounterApp());
    expect(find.text('0'), findsOneWidget);
    counter.setState((s) => s.increment());
    await tester.pump();
    expect(find.text('5'), findsOneWidget);
    counter.setState((s) => s.increment());
    await tester.pump();
    expect(find.text('10'), findsOneWidget);
  });

  testWidgets('should use the default injected mock (when run all tests)',
      (tester) async {
    await tester.pumpWidget(CounterApp());
    expect(find.text('0'), findsOneWidget);
    counter.setState((s) => s.increment());
    await tester.pump();
    expect(find.text('2'), findsOneWidget);
    expect(dataFromInjection, 2);
    counter.setState((s) => s.increment());
    await tester.pump();
    expect(find.text('4'), findsOneWidget);
    expect(dataFromInjection, 4);
  });
  testWidgets('should throw error (override injection to throw error)',
      (tester) async {
    counter.injectMock(() => FakeCounter(incrementBy: 10, shouldThrow: true));
    await tester.pumpWidget(CounterApp());
    expect(find.text('0'), findsOneWidget);
    counter.setState(
      (s) => s.increment(),
    );
    await tester.pump();
    expect(errorFromInjection, 'Counter Error');
    errorFromInjection = null;
  });

  testWidgets('onSetState error override error defined in the injection',
      (tester) async {
    counter.injectMock(() => FakeCounter(incrementBy: 10, shouldThrow: true));
    String? _errorMessage;
    await tester.pumpWidget(CounterApp());
    expect(find.text('0'), findsOneWidget);
    counter.setState(
      (s) => s.increment(),
      sideEffects:
          SideEffects.onError((error, _) => _errorMessage = error.message),
      shouldOverrideDefaultSideEffects: (_) => true,
    );
    await tester.pump();
    expect(_errorMessage, 'Counter Error');
    expect(errorFromInjection, null);
  });
  testWidgets('should use the default injected mock (when run all tests)-bis',
      (tester) async {
    await tester.pumpWidget(CounterApp());
    expect(find.text('0'), findsOneWidget);
    counter.setState((s) => s.increment());
    await tester.pump();
    expect(find.text('2'), findsOneWidget);
    counter.setState((s) => s.increment());
    await tester.pump();
    expect(find.text('4'), findsOneWidget);
  });
}
