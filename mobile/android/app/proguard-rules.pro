# Reglas R8 adicionales para la compilación release de JuDy Simulator.
# Flutter y sus plugins ya aportan sus propias reglas (consumer-rules).

# Flutter referencia Play Core (deferred components) aunque la app no lo use.
-dontwarn com.google.android.play.core.**

# Conserva el canal nativo de FLAG_SECURE.
-keep class mx.judysimulator.app.MainActivity { *; }
