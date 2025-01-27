part of '../rm.dart';

abstract class InjectedBase<T> extends InjectedBaseState<T> {
  set state(T s) {
    setState((_) => s);
  }

  ///It is not null if the state is waiting for a Future or is subscribed to a
  ///Stream
  StreamSubscription? get subscription => _reactiveModelState.subscription;

  ///Custom status of the state. Set manually to mark the state with a particular
  ///tag to be used in your logic.
  Object? customStatus;

  ///If the state is bool, toggle it and notify listeners
  ///
  ///This is a shortcut of:
  ///
  ///If the state is not bool, it will throw an assertion error.
  void toggle() {
    assert(T == bool);
    final snap =
        _reactiveModelState.snapState._copyToHasData(!(_state as bool) as T);
    _reactiveModelState.setSnapStateAndRebuild = snap;
  }

  ///Subscribe to the state
  VoidCallback subscribeToRM(void Function(SnapState<T>? snap) fn) {
    _reactiveModelState.listeners._sideEffectListeners.add(fn);
    return () =>
        () => _reactiveModelState.listeners._sideEffectListeners.remove(fn);
  }

  ///Refresh the [Injected] state. Refreshing the state means reinitialize
  ///it and reinvoke its creation function and notify its listeners.
  ///
  ///If the state is persisted using [PersistState], the state is deleted from
  ///the store and the new recalculated state is stored instead.
  ///
  ///If the Injected model has [Injected.inherited] injected models, they will
  ///be refreshed also.
  Future<T?> refresh() async {
    _reactiveModelState._refresh();
    try {
      return await stateAsync;
    } catch (_) {
      try {
        return _state;
      } catch (_) {
        return null;
      }
    }
  }

  SnapState<T>? _middleSnap(
    SnapState<T> s, {
    On<void>? onSetState,
    bool shouldOverrideGlobalSideEffects,
    void Function(T)? onData,
    void Function(dynamic)? onError,
  });
  Timer? _debounceTimer;
  String? debugMessage;

  ///Mutate the state of the model and notify observers.
  ///
  ///* **Required parameters:**
  ///  * The mutation function. It takes the current state fo the model.
  /// The function can have any type of return including Future and Stream.
  ///* **Optional parameters:**
  ///  * **sideEffects**: Used to handle side effects resulting from calling
  /// this method. It takes [SideEffects] object. Notice that [SideEffects.initState]
  /// and [SideEffects.dispose] are never called here.
  ///  * **shouldOverrideDefaultSideEffects**: used to decide when to override
  /// the default side effects defined in [RM.inject] and other equivalent methods.
  ///  * **debounceDelay**: time in milliseconds to debounce the execution of
  /// [setState].
  ///  * **throttleDelay**: time in milliseconds to throttle the execution of
  /// [setState].
  ///  * **skipWaiting**: Wether to notify observers on the waiting state.
  ///  * **shouldAwait**: Wether to await of any existing async call.
  ///  * **silent**: Whether to silent the error of no observers is found.
  ///  * **context**: The [BuildContext] to be used for side effects
  /// (Navigation, SnackBar). If not defined a default [BuildContext]
  /// obtained from the last added [StateBuilder] will be used.
  Future<T> setState<R>(
    FutureOr<R> Function(T s) fn, {
    @Deprecated('User sideEffects.onData instead')
        void Function(T data)? onData,
    @Deprecated('User sideEffects.onError instead')
        void Function(dynamic error)? onError,
    @Deprecated('User sideEffects instead') On<void>? onSetState,
    @Deprecated('User sideEffects instead') void Function()? onRebuildState,
    SideEffects<T>? sideEffects,
    int debounceDelay = 0,
    int throttleDelay = 0,
    bool shouldAwait = false,
    bool skipWaiting = false,
    BuildContext? context,
    bool Function(SnapState<T> snap)? shouldOverrideDefaultSideEffects,
  }) async {
    final debugMessage = this.debugMessage;
    this.debugMessage = null;
    final call = _reactiveModelState.setStateFn(
      (s) {
        // assert(s != null);

        return fn(s as T);
      },
      middleState: (s) {
        final snap = _middleSnap(
          s,
          onError: onError,
          onData: onData,
          shouldOverrideGlobalSideEffects:
              shouldOverrideDefaultSideEffects?.call(s) ?? false,
          onSetState: sideEffects?.onSetState != null
              ? On(() {
                  sideEffects!.onSetState!(s);
                })
              : onSetState,
        );
        if (skipWaiting && snap != null && snap.isWaiting) {
          return null;
        }
        if (snap != null && snap.hasData) {
          if (sideEffects?.onAfterBuild != null) {
            sideEffects!.onAfterBuild!();
          } else if (onRebuildState != null) {
            WidgetsBinding.instance?.addPostFrameCallback(
              (_) => onRebuildState(),
            );
          }
        }
        return snap;
      },
      onDone: (s) {
        return s;
      },
      debugMessage: debugMessage,
    );
    if (debounceDelay > 0) {
      subscription?.cancel();
      _debounceTimer?.cancel();
      _debounceTimer = Timer(
        Duration(milliseconds: debounceDelay),
        () {
          call();
          _debounceTimer = null;
        },
      );
      return Future.value(_state);
    } else if (throttleDelay > 0) {
      if (_debounceTimer != null) {
        return Future.value(_state);
      }
      _debounceTimer = Timer(
        Duration(milliseconds: throttleDelay),
        () {
          _debounceTimer = null;
        },
      );
    }

    if (shouldAwait && isWaiting) {
      return stateAsync.then(
        (_) async {
          final snap = await call();
          return snap.data as T;
        },
      );
    }

    final snap = await call();
    return snap.data as T;
  }

  ///IF the state is in the hasError status, The last callback that causes the
  ///error can be reinvoked.
  void onErrorRefresher() {
    _reactiveModelState._snapState.onErrorRefresher?.call();
  }

  ///
  Future<InjectedBase<T>> catchError(
    void Function(dynamic error, StackTrace s) onError,
  ) async {
    try {
      await _reactiveModelState._endStreamCompleter?.future;
      if (hasError) {
        onError(error, snapState.stackTrace!);
      }
    } catch (e, s) {
      onError(e, s);
    }
    return this;
  }

  @override
  String toString() {
    return '$hashCode: $snapState';
  }
}
