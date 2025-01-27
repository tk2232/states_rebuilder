// ignore_for_file: use_key_in_widget_constructors, file_names, prefer_const_constructors
import 'package:flutter_test/flutter_test.dart';
import 'package:states_rebuilder/states_rebuilder.dart';

void main() {
  testWidgets(
    'WHEN middleSnapState is defined for RM.inject'
    'THEN it is called when the app is initialized, notified and disposed'
    'ALL possible case are tested',
    (tester) async {
      SnapState<int>? _snapState;
      SnapState<int>? _nextSnapState;
      final model = RM.inject<int>(
        () => 0,
        stateInterceptor: (currentSnap, nextSnap) {
          _snapState = currentSnap;
          _nextSnapState = nextSnap;
        },
        initialState: 0,
      );
      expect(_snapState, null);
      expect(_nextSnapState, null);
      //
      expect(model.isIdle, true);
      //model is initialized
      // expect(_snapState!.isIdle, true);
      // expect(_snapState!.data, 0);
      // expect(_nextSnapState!.isIdle, true);
      // expect(_nextSnapState!.data, 0);
      //
      model.state++;
      expect(_snapState!.isIdle, true);
      expect(_snapState!.data, 0);
      expect(_nextSnapState!.hasData, true);
      expect(_nextSnapState!.data, 1);
      expect(model.state, 1);
      //
      model.setState(
        (s) => throw Exception('Error'),
      );
      expect(_snapState!.hasData, true);
      expect(_snapState!.data, 1);
      expect(_nextSnapState!.hasError, true);
      expect(_nextSnapState!.data, 1);
      expect(model.state, 1);
      //
      model.setState((s) => Future.delayed(Duration(seconds: 1), () => 2));
      expect(_snapState!.hasError, true);
      expect(_snapState!.data, 1);
      expect(_nextSnapState!.isWaiting, true);
      expect(_nextSnapState!.data, 1);
      expect(model.state, 1);
      //
      await tester.pump(Duration(seconds: 1));
      expect(_snapState!.isWaiting, true);
      expect(_snapState!.data, 1);
      expect(_nextSnapState!.hasData, true);
      expect(_nextSnapState!.data, 2);
      expect(model.state, 2);
      //
      model.setState(
        (s) => Future.delayed(
          Duration(seconds: 1),
          () => throw Exception('Error'),
        ),
      );
      expect(_snapState!.hasData, true);
      expect(_snapState!.data, 2);
      expect(_nextSnapState!.isWaiting, true);
      expect(_nextSnapState!.data, 2);
      expect(model.state, 2);
      //
      await tester.pump(Duration(seconds: 1));
      expect(_snapState!.isWaiting, true);
      expect(_snapState!.data, 2);
      expect(_nextSnapState!.hasError, true);
      expect(_nextSnapState!.data, 2);
      expect(model.state, 2);
      //
      model.onErrorRefresher();
      expect(_snapState!.hasError, true);
      expect(_snapState!.data, 2);
      expect(_nextSnapState!.isWaiting, true);
      expect(_nextSnapState!.data, 2);
      expect(model.state, 2);
      //
      await tester.pump(Duration(seconds: 1));
      expect(_snapState!.isWaiting, true);
      expect(_snapState!.data, 2);
      expect(_nextSnapState!.hasError, true);
      expect(_nextSnapState!.data, 2);
      expect(model.state, 2);
      //
      model.refresh();
      expect(_snapState!.isIdle, true);
      expect(_snapState!.data, 2);
      expect(_nextSnapState!.isIdle, true);
      expect(_nextSnapState!.data, 0);
      expect(model.state, 0);
      model.dispose();
      expect(_snapState!.isIdle, true);
      expect(_snapState!.data, 2);
      expect(_nextSnapState!.isIdle, true);
      expect(_nextSnapState!.data, 0);
      //Initialize after disposing
      expect(model.isIdle, true);
      //model is initialized (middle snap is not called)
      expect(_snapState!.isIdle, true);
      expect(_snapState!.data, 2);
      expect(_nextSnapState!.isIdle, true);
      expect(_nextSnapState!.data, 0);
    },
  );

  testWidgets(
    'WHEN middleSnapState is defined for RM.injectFuture'
    'THEN it is called when initialized, when notified, when disposed'
    'WHEN state is disposed while the future is still pending'
    'THEN the future is indeed canceled',
    (tester) async {
      SnapState<int>? _snapState;
      SnapState<int>? _nextSnapState;
      final model = RM.injectFuture<int>(
        () => Future.delayed(Duration(seconds: 1), () => 1),
        stateInterceptor: (currentSnap, nextSnap) {
          _snapState = currentSnap;
          _nextSnapState = nextSnap;
        },
        isLazy: false,
      );
      // expect(_snapState!.isIdle, true);
      // expect(_snapState!.data, null);
      // expect(_nextSnapState!.isWaiting, true);
      // expect(_nextSnapState!.data, null);
      await tester.pump(Duration(seconds: 1));
      expect(_snapState!.isWaiting, true);
      expect(_snapState!.data, null);
      expect(_nextSnapState!.hasData, true);
      expect(_nextSnapState!.data, 1);
      //
      model.refresh();
      expect(_snapState!.isIdle, true);
      expect(_snapState!.data, 1);
      expect(_nextSnapState!.isWaiting, true);
      expect(_nextSnapState!.data, 1);
      await tester.pump(Duration(seconds: 1));
      expect(_snapState!.isWaiting, true);
      expect(_snapState!.data, 1);
      expect(_nextSnapState!.hasData, true);
      expect(_nextSnapState!.data, 1);
      //
      model.dispose();
      expect(_snapState!.isWaiting, true);
      expect(_snapState!.data, 1);
      expect(_nextSnapState!.hasData, true);
      expect(_nextSnapState!.data, 1);
      //
      //Initialize after disposing
      expect(model.isWaiting, true);
      expect(_snapState!.isWaiting, true);
      expect(_snapState!.data, 1);
      expect(_nextSnapState!.hasData, true);
      expect(_nextSnapState!.data, 1);
      //Dispose while waiting for a future
      await tester.pump(Duration(milliseconds: 500));
      model.dispose();
      expect(_snapState!.isWaiting, true);
      expect(_snapState!.data, 1);
      expect(_nextSnapState!.hasData, true);
      expect(_nextSnapState!.data, 1);
      //Future is indeed canceled
      await tester.pump(Duration(milliseconds: 500));
      expect(_snapState!.isWaiting, true);
      expect(_snapState!.data, 1);
      expect(_nextSnapState!.hasData, true);
      expect(_nextSnapState!.data, 1);
    },
  );

  testWidgets(
    'WHEN middleSnapState is defined for RM.injectStreams'
    'THEN it is called when initialized, when notified, when disposed'
    'WHEN state is disposed while the stream is emitting data'
    'THEN the subscription is indeed closed',
    (tester) async {
      SnapState<int>? _snapState;
      SnapState<int>? _nextSnapState;
      final model = RM.injectStream<int>(
        () => Stream.periodic(Duration(seconds: 1), (n) => n).take(3),
        stateInterceptor: (currentSnap, nextSnap) {
          _snapState = currentSnap;
          _nextSnapState = nextSnap;
        },
        isLazy: false,
        initialState: 0,
      );

      // expect(_snapState!.isIdle, true);
      // expect(_snapState!.data, 0);
      // expect(_nextSnapState!.isWaiting, true);
      // expect(_nextSnapState!.data, 0);
      //
      await tester.pump(Duration(seconds: 1));
      expect(_snapState!.isWaiting, true);
      expect(_snapState!.data, 0);
      expect(_nextSnapState!.hasData, true);
      expect(_nextSnapState!.data, 0);
      //
      await tester.pump(Duration(seconds: 1));
      expect(_snapState!.hasData, true);
      expect(_snapState!.data, 0);
      expect(_nextSnapState!.hasData, true);
      expect(_nextSnapState!.data, 1);
      //
      await tester.pump(Duration(seconds: 1));
      expect(_snapState!.hasData, true);
      expect(_snapState!.data, 1);
      expect(_nextSnapState!.hasData, true);
      expect(_nextSnapState!.data, 2);
      //
      model.refresh();
      expect(_snapState!.isIdle, true);
      expect(_snapState!.data, 2);
      expect(_nextSnapState!.isWaiting, true);
      expect(_nextSnapState!.data, 0);
      //
      await tester.pump(Duration(seconds: 1));
      expect(_snapState!.isWaiting, true);
      expect(_snapState!.data, 0);
      expect(_nextSnapState!.hasData, true);
      expect(_nextSnapState!.data, 0);
      //
      await tester.pump(Duration(seconds: 1));
      expect(_snapState!.hasData, true);
      expect(_snapState!.data, 0);
      expect(_nextSnapState!.hasData, true);
      expect(_nextSnapState!.data, 1);
      //
      model.dispose();
      expect(_snapState!.hasData, true);
      expect(_snapState!.data, 0);
      expect(_nextSnapState!.hasData, true);
      expect(_nextSnapState!.data, 1);
      //
      expect(model.isWaiting, true);
      expect(_snapState!.hasData, true);
      expect(_snapState!.data, 0);
      expect(_nextSnapState!.hasData, true);
      expect(_nextSnapState!.data, 1);
      //
      await tester.pump(Duration(seconds: 1));
      expect(_snapState!.isWaiting, true);
      expect(_snapState!.data, 0);
      expect(_nextSnapState!.hasData, true);
      expect(_nextSnapState!.data, 0);
      //
      await tester.pump(Duration(seconds: 1));
      expect(_snapState!.hasData, true);
      expect(_snapState!.data, 0);
      expect(_nextSnapState!.hasData, true);
      expect(_nextSnapState!.data, 1);
      model.dispose();
    },
  );

  testWidgets(
    'stateInterceptor is not invoked on init and on dispose ',
    (WidgetTester tester) async {
      String message = '';
      final model = RM.inject<List<String>>(
        () => [],
        stateInterceptor: (currentSnap, nextSnap) {
          message = 'stateInterceptor is called';
          return nextSnap.copyTo(data: [
            ...currentSnap.state,
            ...nextSnap.state,
          ]);
        },
      );
      expect(message, '');
      expect(model.state, []);
      expect(message, '');

      model.state = ['one'];
      await tester.pump();
      expect(model.state, ['one']);
      expect(message, 'stateInterceptor is called');
      model.state = ['two'];
      await tester.pump();
      expect(model.state, ['one', 'two']);
      message = '';
      model.dispose();
      expect(message, '');
    },
  );

  testWidgets(
    'WHEN '
    'THEN ',
    (tester) async {
      // SnapState<int>? _snapState;
      // SnapState<int>? _nextSnapState;
      final model1 = RM.inject(() => 0);
      final model2 = RM.injectFuture<int>(
        () => Future.delayed(Duration(seconds: 1), () => 1),
        stateInterceptor: (currentSnap, nextSnap) {
          // _snapState = currentSnap;
          // _nextSnapState = nextSnap;
        },
        dependsOn: DependsOn({model1}),
      );
      expect(model1.isIdle, true);
      expect(model2.isWaiting, true);
      await tester.pump(Duration(seconds: 1));
      model1.state++;
      await tester.pump(Duration(seconds: 1));
      model1.setState((s) => Future.delayed(Duration(seconds: 1), () => 2));
      await tester.pump(Duration(seconds: 1));
      await tester.pump(Duration(seconds: 1));
    },
  );
}
