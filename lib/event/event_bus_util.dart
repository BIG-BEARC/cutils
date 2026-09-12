import 'dart:async';

import 'package:event_bus/event_bus.dart';

/// 应用级事件总线单例（基于 `event_bus` 包）。
///
/// 订阅者通过 [EventBusUtil.listen] 注册（自动收集到内部集合，[dispose] 统一取消），
/// 发布者通过 [EventBusUtil.fire] 广播。事件类型必须继承 [Event]。
final eventBus = EventBusUtil();

/// 所有事件的标记基类。订阅端用 `listen<MyEvent>(...)` 按类型过滤。
abstract class Event {}

/// 事件总线工具：单例，封装 `event_bus` 并管理订阅生命周期。
///
/// example:
/// ```dart
/// class LoginEvent extends Event {}
/// eventBus.fire(LoginEvent());
/// eventBus.listen<LoginEvent>((e) => print('logged in'));
/// ```
class EventBusUtil {
  static EventBusUtil _singleton = EventBusUtil._internal();

  factory EventBusUtil() => _singleton;

  EventBusUtil._internal();

  /// 当前单例持有的 [EventBus] 流（静态访问点）。
  static EventBus get eventBus => _singleton._eventBus;
  EventBus _eventBus = EventBus();

  /// 当前注册的订阅。用于 [dispose] 时统一取消，避免忘记 cancel 的监听器
  /// 永久挂在单例广播流上造成泄漏。
  final Set<StreamSubscription<dynamic>> _subscriptions = {};

  /// 订阅指定类型 [T] 的事件。返回的 [StreamSubscription] 会被自动收集，
  /// [dispose] 时统一取消；调用方也可自行提前 cancel。
  StreamSubscription<T> listen<T extends Event>(
    void Function(T event) onData, {
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

  /// 广播事件 [e]。若控制器已关闭则安全跳过（no-op）。
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
