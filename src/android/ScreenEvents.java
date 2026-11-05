package com.wrobins.cordova.plugin;

import android.app.Activity;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Build;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CordovaWebView;
import org.apache.cordova.LOG;
import org.apache.cordova.PluginResult;
import org.json.JSONArray;
import org.json.JSONException;

/*
 * Android: TRVALY receiver. Puvodni implementace byla jednorazova (po kazde udalosti se
 * receiver odregistroval a JS ho musel znovu naarmovat pres setTimeout). Skryta stranka
 * WebView ale ma po ~60 s na pozadi JS timery zmrazene (zmereno 2026-11-05, WebView 156),
 * takze se listener po prvni udalosti uz nikdy nenaarmoval a automaticky mod "umrel"
 * (docs/analyza-spotreba-faze1.md, B8). Nativni callbacky do JS pritom prochazeji i ve
 * zmrazenem stavu, proto receiver zustava registrovany a kazdou udalost posila pres
 * keepCallback. Opakovane volani listenerInit jen vymeni callback.
 */
public class ScreenEvents extends CordovaPlugin {
    private static final String TAG = "ScreenEvents";
    private Activity activity;
    private CallbackContext callbackContext;

    private static final String LISTENER_INIT = "listenerInit";
    private static final String SCREEN_TURNED_ON = "SCREEN_TURNED_ON";
    private static final String SCREEN_TURNED_OFF = "SCREEN_TURNED_OFF";

    private class ScreenStateReceiver extends BroadcastReceiver {
        @Override
        public void onReceive(Context context, Intent intent) {
            String action = intent.getAction();
            String state = null;
            if (Intent.ACTION_SCREEN_ON.equals(action)) {
                state = SCREEN_TURNED_ON;
            } else if (Intent.ACTION_USER_PRESENT.equals(action)) {
                // odemceni telefonu; hlasime jako SCREEN_TURNED_ON, aby JS strana nepotrebovala
                // novy stav - pro automaticky mod je odemceni presnejsi signal "uzivatel vzal
                // telefon do ruky" nez samotne rozsviceni displeje
                state = SCREEN_TURNED_ON;
            } else if (Intent.ACTION_SCREEN_OFF.equals(action)) {
                state = SCREEN_TURNED_OFF;
            }
            if (state != null) {
                sendState(state);
            }
        }
    }

    private ScreenStateReceiver mReceiver;

    @Override
    public void initialize(CordovaInterface cordova, CordovaWebView webView) {
        super.initialize(cordova, webView);
        activity = cordova.getActivity();
    }

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        try {
            if (LISTENER_INIT.equals(action)) {
                this.callbackContext = callbackContext;
                this.listenerInit();
                // callback zustava otevreny pro vsechny dalsi udalosti
                PluginResult result = new PluginResult(PluginResult.Status.NO_RESULT);
                result.setKeepCallback(true);
                callbackContext.sendPluginResult(result);
                return true;
            }
        } catch (Exception e) {
            e.printStackTrace();
            callbackContext.error(e.getMessage());
            return false;
        }
        return false;
    }

    private void sendState(String state) {
        if (callbackContext == null) {
            return;
        }
        PluginResult result = new PluginResult(PluginResult.Status.OK, state);
        result.setKeepCallback(true);
        callbackContext.sendPluginResult(result);
    }

    private void listenerInit() {
        if (mReceiver != null) {
            // uz registrovano - staci vymenit callback (viz execute)
            return;
        }
        IntentFilter intentFilter = new IntentFilter(Intent.ACTION_SCREEN_ON);
        intentFilter.addAction(Intent.ACTION_SCREEN_OFF);
        intentFilter.addAction(Intent.ACTION_USER_PRESENT);
        mReceiver = new ScreenStateReceiver();
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            // systemove broadcasty se doruci i receiveru bez exportu; flag je od API 34 povinny
            activity.registerReceiver(mReceiver, intentFilter, Context.RECEIVER_NOT_EXPORTED);
        } else {
            activity.registerReceiver(mReceiver, intentFilter);
        }
    }

    private void unregister() {
        if (mReceiver == null) {
            return;
        }
        try {
            activity.unregisterReceiver(mReceiver);
        } catch (IllegalArgumentException e) {
            LOG.w(TAG, "receiver already unregistered");
        }
        mReceiver = null;
    }

    @Override
    public void onReset() {
        unregister();
        callbackContext = null;
    }

    @Override
    public void onDestroy() {
        unregister();
        callbackContext = null;
    }
}
