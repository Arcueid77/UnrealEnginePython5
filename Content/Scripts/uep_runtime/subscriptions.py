"""Explicitly owned, game-thread delegate and Gameplay Message subscriptions.

The optional signal API exposes only the channel. Typed delivery requires an
explicit verified VM reader; never invoke wildcard GetPayload via generic
ProcessEvent. Close scopes from Destruct/EndPlay and Mixin
teardown, before reloading modules. No global listener registry or finalizer
may call a UObject after engine shutdown.
"""

import unreal_engine as ue


def _valid(obj):
    try:
        return obj is not None and obj.is_valid()
    except Exception:
        # UEP can reject attribute lookup itself after native GC invalidated
        # the wrapper, before is_valid() gets a chance to return False.
        return False


class SubscriptionScope:
    def __init__(self):
        self._closed = False
        self._cleanups = []

    @property
    def closed(self):
        return self._closed

    @property
    def count(self):
        return len(self._cleanups)

    def _check_open(self):
        if self._closed:
            raise RuntimeError("subscription scope is closed")

    def bind_event(self, source, event, callback):
        self._check_open()
        if not _valid(source) or not callable(callback):
            raise ValueError("a live delegate source and callable are required")

        def dispatch(*args):
            if not self._closed:
                return callback(*args)

        source.bind_event(event, dispatch)

        def cleanup():
            if _valid(source):
                source.unbind_event(event, dispatch)

        self._cleanups.append(cleanup)

    def listen_gameplay_signal(self, context, channel, callback):
        """Listen for exact-channel notifications, without reading a payload.

        GameplayMessageRouter is an optional plugin, not a UEP link dependency.
        The caller owns any player filtering; a GameInstance message is not
        inherently local-player-scoped. No reflected CustomThunk is invoked.
        """
        self._check_open()
        if not _valid(context) or not isinstance(channel, str) or not channel or not callable(callback):
            raise ValueError("live context, channel name and callable are required")
        return self._listen_gameplay(context, channel, None, lambda sender, actual: callback(actual))

    def listen_gameplay_message(self, context, channel, payload_type, payload_reader, callback):
        """Typed delivery through an explicitly supplied, verified VM adapter.

        payload_reader(proxy) must copy the typed payload during delivery and
        fail if extraction fails. A compiled BP adapter can safely execute the
        wildcard GetPayload thunk; calling its placeholder via ProcessEvent
        cannot. Core never assumes a payload layout or depends on a game plugin.
        """
        self._check_open()
        if (not _valid(context) or not _valid(payload_type) or not isinstance(channel, str) or not channel
                or not callable(payload_reader) or not callable(callback)):
            raise ValueError("live context/type, channel, payload reader and callback are required")

        def typed_dispatch(sender, actual_channel):
            payload = payload_reader(sender)
            # A reader may close the scope. Do not deliver after disarming it.
            if not self._closed:
                callback(actual_channel, payload)

        return self._listen_gameplay(context, channel, payload_type, typed_dispatch)

    def _listen_gameplay(self, context, channel, payload_type, callback):
        from unreal_engine.structs import GameplayTag
        action_class = ue.find_class("AsyncAction_ListenForGameplayMessage")
        if action_class is None:
            raise RuntimeError("GameplayMessageRouter is not available")
        proxy = action_class.get_cdo().call_function("ListenForGameplayMessages", context,
                                                    GameplayTag(TagName=channel), payload_type, 0)
        if not _valid(proxy):
            raise RuntimeError("Gameplay Message listener has no valid World")

        def dispatch(sender, actual_channel):
            if not self._closed:
                callback(sender, actual_channel)

        bound = False
        try:
            proxy.bind_event("OnMessageReceived", dispatch)
            bound = True
            proxy.call_function("Activate")
            if not proxy.call_function("IsActive"):
                raise RuntimeError("Gameplay Message listener did not activate")
        except Exception:
            if _valid(proxy):
                try:
                    if bound:
                        proxy.unbind_event("OnMessageReceived", dispatch)
                finally:
                    proxy.call_function("Cancel")
            raise

        def cleanup():
            if _valid(proxy):
                try:
                    proxy.unbind_event("OnMessageReceived", dispatch)
                finally:
                    proxy.call_function("Cancel")

        self._cleanups.append(cleanup)

    def close(self):
        if self._closed:
            return
        self._closed = True  # Disarm before a native cancellation can reenter.
        cleanups, self._cleanups = self._cleanups, []
        errors = []
        for cleanup in reversed(cleanups):
            try:
                cleanup()
            except Exception as error:
                errors.append(error)
        if errors:
            raise RuntimeError("subscription cleanup failed: " + str(errors[0])) from errors[0]

    def __enter__(self):
        self._check_open()
        return self

    def __exit__(self, kind, value, traceback):
        self.close()
