package be.ppareit.autosleep

import android.app.AlarmManager
import android.app.PendingIntent
import android.app.ProgressDialog
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Intent
import android.content.IntentFilter
import android.os.AsyncTask
import android.os.BatteryManager
import android.os.Build
import android.os.SystemClock
import android.util.Log
import android.view.WindowManager
import org.xtendroid.annotations.AddLogTag

import static be.ppareit.autosleep.Device.*

import static extension be.ppareit.autosleep.AndroidUtils.*
import static extension be.ppareit.autosleep.Settings.*

@AddLogTag
class AsService extends Service {

    volatile boolean mRunning = false;

    BroadcastReceiver mPowerDisconnectReceiver = [ context, intent |
        Log.d(TAG, "We are now running on battery power")
        if (settings.allowcancel) {
            showCancelDialog()
        } else {
            device.turnScreenOff()
        }
    ]

    def showCancelDialog() {
        new AsyncTask<Void, Integer, Void> {
            val progressDialog = new ProgressDialog(AsService.this)
            val delay = settings.delay
            val cancelMessage = resources.getString(R.string.cancel_message)
            override protected onPreExecute() {
                super.onPreExecute();
                progressDialog.title = R.string.cancel_title
                progressDialog.message = String.format(cancelMessage, delay)
                progressDialog.window.type = WindowManager.LayoutParams.TYPE_SYSTEM_ALERT
                progressDialog.indeterminate = false
                progressDialog.max = delay
                progressDialog.progress = delay
                progressDialog.progressStyle = ProgressDialog.STYLE_SPINNER // change this or progressbar
                progressDialog.setButton(ProgressDialog.BUTTON_NEGATIVE, resources.getString(R.string.cancel),
                    [
                        progressDialog.dismiss()
                    ])
                progressDialog.setButton(ProgressDialog.BUTTON_POSITIVE, resources.getString(R.string.sleepnow),
                    [
                        progressDialog.dismiss()
                        device.turnScreenOff()
                    ])
                progressDialog.show
            }
            override protected doInBackground(Void... params) {
                for (i : delay .. 0) {
                    // check if the device is not been plugged in again
                    if (device.isPlugged() == true) {
                        progressDialog.dismiss()
                    }
                    Thread.sleep(1000)
                    publishProgress(i)
                }
                null as Void
            }
            override protected onProgressUpdate(Integer... arg) {
                var i = arg.get(0)
                progressDialog.progress = i
                progressDialog.message = String.format(cancelMessage, i)
            }
            override protected onPostExecute(Void v) {
                if (progressDialog.showing == true) {
                    // only do this when we had full countdown
                    progressDialog.dismiss()
                    device.turnScreenOff()
                }
            }
        }.execute()
    }

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
