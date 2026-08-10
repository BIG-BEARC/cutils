import 'dart:async';

import 'package:event_bus/event_bus.dart';

final eventBus = EventBusUtil();

abstract class Event {}

class EventBusUtil {
  static EventBusUtil _singleton = EventBusUtil._internal();

  factory EventBusUtil() => _singleton;

  EventBusUtil._internal();

  static EventBus get eventBus => _singleton._eventBus;
  EventBus _eventBus = EventBus();

  /// 当前注册的订阅。用于 [dispose] 时统一取消，避免忘记 cancel 的监听器
  /// 永久挂在单例广播流上造成泄漏。
  final Set<StreamSubscription> _subscriptions = {};

  StreamSubscription<T> listen<T extends Event>(
    Function(T event) onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    final subscription = _eventBus.on<T>().listen(
          onData,
          onError: onError,
          onDone: onDone,
          cancelOnError: cancelOnError,
        );
    _subscriptions.add(subscription);
    return subscription;
  }

  void fire<T extends Event>(T e) {
    if (_eventBus.streamController.isClosed) {
      return;
    }
    _eventBus.fire(e);
  }

  /// 销毁事件总线：取消所有已注册的订阅并关闭控制器。
  ///
  /// 适用于宿主 App 在退出 / 重建时调用（per spec D3，eventBus 是应用级单例）。
  /// 调用后单例会被重置为可用状态，以便测试或 App 重启后复用。
  Future<void> dispose() async {
    final subs = _subscriptions.toList();
    _subscriptions.clear();
    for (final sub in subs) {
      await sub.cancel();
    }
    _eventBus.destroy();
    // 重置内部 EventBus 与单例引用，使后续 listen/fire 恢复可用。
    _eventBus = EventBus();
    _singleton = this;
  }
}
