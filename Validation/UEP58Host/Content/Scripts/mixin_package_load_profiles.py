"""Importable profiles for the saved-package, fresh-process discovery fixture."""


class PythonProfile:
    def BroadcastSignal(self, Value):
        self.Int32Value += Value

    def OverrideableValue(self, Input):
        return Input + 100


class BlueprintFallbackProfile:
    def BroadcastSignal(self, Value):
        self.call_mixin_original("BroadcastSignal", Value)
