package be.ppareit.autosleep

import android.app.AlarmManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.Build
import android.os.SystemClock
import android.util.Log
import org.xtendroid.annotations.AddLogTag

import static be.ppareit.autosleep.App.*
import static be.ppareit.autosleep.Device.*

import static extension be.ppareit.autosleep.AndroidUtils.*
import static extension be.ppareit.autosleep.Settings.*

@AddLogTag
class AsService extends Service {

    volatile boolean mRunning = false;

    BroadcastReceiver mPowerDisconnectReceiver = [ context, intent |
            Log.d(TAG, "We are now running on battery power")
            if (settings.allowcancel) {
                var cancelIntent = new Intent(app.applicationContext, CancelActivity)
                cancelIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(cancelIntent)
            } else {
                device.turnScreenOff()
            }
        ]

    override onCreate() {
        Log.d(TAG, "onCreate called")
        if (settings.runservice == false) {
            Log.w(TAG, "No need to run service, closing down")
            mRunning = false
            stopSelf()
            return
        }

        var powerDisconnectFilter = new IntentFilter(Intent.ACTION_POWER_DISCONNECTED)
        registerReceiver(mPowerDisconnectReceiver, powerDisconnectFilter)

        mRunning = true
    }

    override onStartCommand(Intent intent, int flags, int startId) {
        Log.d(TAG, "onStartCommand called")
        if(settings.runservice) START_STICKY else START_NOT_STICKY
    }

    override onDestroy() {
        Log.d(TAG, "onDestroy called")
        if (mRunning == false) {
            return
        }

        unregisterReceiver(mPowerDisconnectReceiver)

        mRunning = false
    }

    def boolean isPlugged() {
        var isPlugged = false
        var intent = registerReceiver(null, new IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        var plugged = intent.getIntExtra(BatteryManager.EXTRA_PLUGGED, -1)
        isPlugged = plugged == BatteryManager.BATTERY_PLUGGED_AC
        isPlugged = isPlugged || plugged == BatteryManager.BATTERY_PLUGGED_USB
        if (Build.VERSION.SDK_INT > Build.VERSION_CODES.JELLY_BEAN) {
            isPlugged = isPlugged || plugged == BatteryManager.BATTERY_PLUGGED_WIRELESS
        }
        return isPlugged;
    }

    override void onTaskRemoved(Intent rootIntent) {
        super.onTaskRemoved(rootIntent);
        Log.d(TAG, "user has removed my activity, we got killed! restarting...");

        // restart my service
        var restartService = new Intent(getApplicationContext(), class);
        restartService.setPackage(getPackageName());
        var restartServicePI = PendingIntent.getService(getApplicationContext(), 1, restartService,
            PendingIntent.FLAG_ONE_SHOT);
        var alarmService = getSystemService(AlarmManager);
        alarmService.set(AlarmManager.ELAPSED_REALTIME, SystemClock.elapsedRealtime() + 2000, restartServicePI);
    }

    override onBind(Intent arg0) {
    }

}
