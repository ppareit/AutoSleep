package be.ppareit.autosleep

import static extension be.ppareit.autosleep.AndroidUtils.*

import android.app.Application
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import org.xtendroid.annotations.AddLogTag
import android.app.AlarmManager
import android.app.PendingIntent
import android.os.SystemClock
import android.app.admin.DevicePolicyManager
import android.content.ComponentName

@AddLogTag
class App extends Application {

    static PendingIntent sAlarmIntent;
    static App sApp;

    static class BootCompletedReceiver extends BroadcastReceiver {
        override onReceive(Context arg0, Intent arg1) {
            Log.d(TAG, "Boot completed received");

        // nothing to do, the onCreate will be called automatically
        }
    }
    
    static def App getApp() {
        return sApp;
    }

    override void onCreate() {
        super.onCreate();
        Log.d(TAG, "onCreate called")
        
        sApp = this;

        var intent = new Intent(this, AsService);

        // start this one right away
        startService(intent);

        // use an alarm that will start the service every fifteen minutes, this
        // just as a safe guard in case the service would have been stopped by accident
        var am = getSystemService(AlarmManager);
        sAlarmIntent = PendingIntent.getService(this, 0, intent, 0);
        am.setInexactRepeating(AlarmManager.ELAPSED_REALTIME, //
            SystemClock.elapsedRealtime() + AlarmManager.INTERVAL_FIFTEEN_MINUTES, //
            AlarmManager.INTERVAL_FIFTEEN_MINUTES, //
            sAlarmIntent);
    }

    def boolean hasAdminRights() {
        var dpm = getSystemService(DevicePolicyManager)
        var admin = new ComponentName(this, AdminReceiver)
        return dpm.isAdminActive(admin)
    }
}
