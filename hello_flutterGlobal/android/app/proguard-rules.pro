# Keep PDF library classes
-keep class com.tom_roush.pdfbox.** { *; }
-dontwarn com.tom_roush.pdfbox.**
-dontwarn com.gemalto.jp2.JP2Decoder

# Keep read_pdf_text plugin classes
-keep class com.example.read_pdf_text.** { *; }

# Keep all native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# WorkManager
-keep class androidx.work.** { *; }
-dontwarn androidx.work.**

# Flutter Local Notifications
-keep class com.dexterous.** { *; }
-dontwarn com.dexterous.**
