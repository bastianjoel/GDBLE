# btleplug resources - protect classes accessed by native code
-keep class com.nonpolynomial.** { *; }
-keep class io.github.gedgygedgy.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep classes that implement interfaces accessed by native code
-keep class * implements android.bluetooth.BluetoothAdapter$LeScanCallback { *; }
-keep class * implements android.bluetooth.BluetoothAdapter$DiscoveryListener { *; }
-keep class * implements android.bluetooth.BluetoothLeScanner$ScanCallback { *; }

# Keep Bluetooth-related classes
-keep class android.bluetooth.** { *; }