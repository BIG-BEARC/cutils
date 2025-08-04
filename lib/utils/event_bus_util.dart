import 'dart:async';

import 'package:event_bus/event_bus.dart';

final eventBus = EventBusUtil();

abstract class Event {}

class EventBusUtil {
  static final EventBusUtil _singleton = EventBusUtil._internal();

  factory EventBusUtil() => _singleton;

  EventBusUtil._internal();

  static EventBus get eventBus => _singleton._eventBus;
  final _eventBus = EventBus();

  //保存事件订阅者队列，key:事件名(id)，value: 对应事件的订阅者队列
  // var _emap = new Map<Object, List<EventCallback>>();

  StreamSubscription<T> listen<T extends Event>(
    Function(T event) onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return _eventBus.on<T>().listen(
          onData,
          onError: onError,
          onDone: onDone,
          cancelOnError: cancelOnError,
        );
  }

  void fire<T extends Event>(T e) {
    if (_eventBus.streamController.isClosed) {
      return;
    }
    _eventBus.fire(e);
  }
}
