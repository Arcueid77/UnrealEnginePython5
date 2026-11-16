"""Host-only contracts for scope ownership; native signal test is separate."""
from pathlib import Path
import sys
import types
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / 'Content' / 'Scripts'))
sys.modules.setdefault('unreal_engine', types.ModuleType('unreal_engine'))
fake_structs = types.ModuleType('unreal_engine.structs')
fake_structs.GameplayTag = lambda **kwargs: kwargs
sys.modules['unreal_engine.structs'] = fake_structs
from uep_runtime import subscriptions


class Source:
    def __init__(self):
        self.valid, self.active = True, True
        self.callbacks, self.unbound, self.calls = {}, [], []

    def is_valid(self):
        return self.valid

    def bind_event(self, name, callback):
        self.callbacks[name] = callback

    def unbind_event(self, name, callback):
        if self.callbacks[name] is not callback:
            raise AssertionError('different callback identity')
        self.unbound.append(name)
        del self.callbacks[name]

    def call_function(self, name, *args):
        self.calls.append(name)
        if name == 'IsActive':
            return self.active
        if name == 'Cancel':
            self.active = False


class SubscriptionTests(unittest.TestCase):
    def setUp(self):
        self.old_ue = subscriptions.ue
        self.source = Source()
        factory = types.SimpleNamespace(get_cdo=lambda: types.SimpleNamespace(call_function=lambda *args: self.source))
        subscriptions.ue = types.SimpleNamespace(find_class=lambda name: factory)

    def tearDown(self):
        subscriptions.ue = self.old_ue

    def test_dynamic_delegate_exact_identity_and_disarm(self):
        scope, source, received = subscriptions.SubscriptionScope(), self.source, []
        scope.bind_event(source, 'Changed', received.append)
        saved = source.callbacks['Changed']
        saved(1)
        scope.close()
        saved(2)
        scope.close()
        self.assertEqual(received, [1])
        self.assertEqual(source.unbound, ['Changed'])
        self.assertEqual(scope.count, 0)

    def test_message_activate_cancel_and_channel_only(self):
        scope, received = subscriptions.SubscriptionScope(), []
        scope.listen_gameplay_signal(self.source, 'Test.Message', received.append)
        self.source.callbacks['OnMessageReceived'](self.source, 'Test.Message')
        scope.close()
        self.assertEqual(received, ['Test.Message'])
        self.assertEqual(self.source.calls, ['Activate', 'IsActive', 'Cancel'])

    def test_typed_delivery_uses_reader_during_callback_and_disarms(self):
        scope, received, reads = subscriptions.SubscriptionScope(), [], []
        payload = {'owner': 'local', 'enabled': True}
        def reader(proxy):
            reads.append(proxy)
            return dict(payload)
        scope.listen_gameplay_message(self.source, 'Test.Message', self.source, reader,
                                      lambda channel, value: received.append((channel, value)))
        saved = self.source.callbacks['OnMessageReceived']
        saved(self.source, 'Test.Message')
        scope.close()
        saved(self.source, 'Test.Message')
        self.assertEqual(reads, [self.source])
        self.assertEqual(received, [('Test.Message', payload)])
        self.assertEqual(scope.count, 0)

    def test_typed_reader_failure_does_not_deliver_default_payload(self):
        scope, received = subscriptions.SubscriptionScope(), []
        def reader(proxy):
            raise RuntimeError('typed extraction failed')
        scope.listen_gameplay_message(self.source, 'Test.Message', self.source, reader, received.append)
        with self.assertRaisesRegex(RuntimeError, 'extraction failed'):
            self.source.callbacks['OnMessageReceived'](self.source, 'Test.Message')
        self.assertEqual(received, [])
        scope.close()

    def test_reader_can_close_without_delivering_after_close(self):
        scope, received = subscriptions.SubscriptionScope(), []
        def reader(proxy):
            scope.close()
            return 7
        scope.listen_gameplay_message(self.source, 'Test.Message', self.source, reader,
                                      lambda channel, value: received.append(value))
        self.source.callbacks['OnMessageReceived'](self.source, 'Test.Message')
        self.assertTrue(scope.closed)
        self.assertEqual(received, [])

    def test_typed_listener_requires_live_type_and_explicit_reader(self):
        for value in (None, object()):
            with self.assertRaises(ValueError):
                subscriptions.SubscriptionScope().listen_gameplay_message(self.source, 'Test.Message', value,
                                                                        lambda proxy: 1, lambda *args: None)
        with self.assertRaises(ValueError):
            subscriptions.SubscriptionScope().listen_gameplay_message(self.source, 'Test.Message', self.source,
                                                                    None, lambda *args: None)

    def test_failed_activation_is_cancelled(self):
        self.source.active = False
        scope = subscriptions.SubscriptionScope()
        with self.assertRaisesRegex(RuntimeError, 'activate'):
            scope.listen_gameplay_signal(self.source, 'Test.Message', lambda tag: None)
        self.assertEqual(scope.count, 0)
        self.assertIn('Cancel', self.source.calls)
        self.assertFalse(self.source.callbacks)

    def test_activation_failure_cancels_even_when_unbind_fails(self):
        self.source.active = False
        def failed(*args):
            raise RuntimeError('unbind failed')
        self.source.unbind_event = failed
        with self.assertRaisesRegex(RuntimeError, 'unbind failed'):
            subscriptions.SubscriptionScope().listen_gameplay_signal(self.source, 'Test.Message', lambda tag: None)
        self.assertIn('Cancel', self.source.calls)

    def test_closed_scope_rejects_new_callbacks(self):
        scope = subscriptions.SubscriptionScope()
        scope.close()
        with self.assertRaisesRegex(RuntimeError, 'closed'):
            scope.bind_event(self.source, 'Changed', lambda: None)

    def test_dead_source_needs_no_native_cleanup(self):
        scope = subscriptions.SubscriptionScope()
        scope.bind_event(self.source, 'Changed', lambda: None)
        self.source.valid = False
        scope.close()
        self.assertFalse(self.source.unbound)

    def test_native_gc_invalid_wrapper_is_also_dead(self):
        scope = subscriptions.SubscriptionScope()
        scope.bind_event(self.source, 'Changed', lambda: None)
        def invalid():
            raise RuntimeError('PyUObject is in invalid state')
        self.source.is_valid = invalid
        scope.close()
        self.assertFalse(self.source.unbound)

    def test_optional_plugin_absence_is_explicit(self):
        subscriptions.ue = types.SimpleNamespace(find_class=lambda name: None)
        with self.assertRaisesRegex(RuntimeError, 'not available'):
            subscriptions.SubscriptionScope().listen_gameplay_signal(self.source, 'Test.Message', lambda tag: None)

    def test_cleanup_continues_after_one_failure(self):
        scope = subscriptions.SubscriptionScope()
        other = Source()
        scope.bind_event(other, 'Other', lambda: None)
        scope.bind_event(self.source, 'Changed', lambda: None)
        def failed(*args):
            raise RuntimeError('detach failed')
        self.source.unbind_event = failed
        with self.assertRaisesRegex(RuntimeError, 'cleanup failed'):
            scope.close()
        self.assertEqual(other.unbound, ['Other'])
        self.assertTrue(scope.closed)
