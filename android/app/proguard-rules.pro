# Please add these rules to your existing keep rules in order to suppress warnings.
# This is generated automatically by the Android Gradle plugin.
-dontwarn androidx.camera.extensions.impl.InitializerImpl$OnExtensionsDeinitializedCallback
-dontwarn androidx.camera.extensions.impl.InitializerImpl$OnExtensionsInitializedCallback
-dontwarn com.google.devtools.build.android.desugar.runtime.ThrowableExtension
-keepclassmembers class util.concurrent.ConcurrentHashMap.CounterCell {
  long value;
}