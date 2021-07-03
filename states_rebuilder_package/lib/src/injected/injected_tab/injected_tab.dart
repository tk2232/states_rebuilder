import 'package:flutter/material.dart';

import '../../builders/state_with_mixin_builder.dart';
import '../../rm.dart';

part 'on_tab.dart';

abstract class InjectedTab implements InjectedBaseState<int> {
  TabController? _controller;

  TabController get controller {
    assert(_controller != null);
    return _controller!;
  }

  ///The index of the currently selected tab.
  int get index => _controller!.index;
  set index(int i) {
    if (i == snapState.data) {
      return;
    }
    _controller!.index = i;
  }

  ///The index of the previously selected tab.
  int get previousIndex => _controller!.previousIndex;

  ///True while we're animating from [previousIndex] to [index] as a consequence of calling [animateTo].
  bool get indexIsChanging => _controller!.indexIsChanging;

  ///Immediately sets [index] and [previousIndex] and then plays the animation from its current value to [index].
  void animateTo(
    int value, {
    Duration duration = kTabScrollDuration,
    Curve curve = Curves.ease,
  }) {
    _controller!.animateTo(
      value,
      duration: duration,
      curve: curve,
    );
  }
}

class InjectedTabImp extends InjectedBaseBaseImp<int> with InjectedTab {
  InjectedTabImp({
    this.initialIndex = 0,
    required this.length,
  }) : super(creator: () => initialIndex);

  final int initialIndex;
  final int length;

  void initialize(TickerProvider ticker) {
    if (_controller != null) {
      return;
    }
    _controller = TabController(
      vsync: ticker,
      length: length,
      initialIndex: initialIndex,
    );
    _controller!.addListener(() {
      if (snapState.data == _controller!.index) {
        return;
      }
      snapState = SnapState.data(_controller!.index);
      notify();
    });
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
    _controller = null;
  }
}