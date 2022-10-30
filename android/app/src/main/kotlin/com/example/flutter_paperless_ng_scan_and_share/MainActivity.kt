package com.example.flutter_paperless_mobile

import android.os.Bundle
import android.view.WindowManager.LayoutParams
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity() {

    override fun onCreate(bundle: Bundle?) {
        super.onCreate(bundle)
        //getWindow().addFlags(LayoutParams.FLAG_SECURE)
    }
}
