# libwg-go exports JNI symbols using this class and these method names.
-keepclasseswithmembernames class com.wireguard.android.backend.GoBackend {
    native <methods>;
}
