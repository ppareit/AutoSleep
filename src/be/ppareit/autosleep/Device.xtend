package be.ppareit.autosleep

import static extension be.ppareit.autosleep.App.*
import static extension be.ppareit.autosleep.AndroidUtils.*

import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.ContextWrapper
import android.content.Context
import android.content.Intent
import org.xtendroid.utils.BgTask
import android.os.PowerManager
import org.xtendroid.annotations.AddLogTag
import android.util.Log

@AddLogTag
class Device extends ContextWrapper {

    private static Device sDevice;
    
    private new(Context context) {
        super(context)
    }

    static def Device getDevice() {
        if (sDevice == null) {
            sDevice = new Device(app.applicationContext)
        }
        return sDevice
    }

    def void turnScreenOff() {
        val dpm = getSystemService(DevicePolicyManager)
        val admin = new ComponentName(this, AdminReceiver)
        if (dpm.isAdminActive(admin) == true) {
            Log.d(TAG, "We got admin rights, enter lock")
            dpm.lockNow
            // some apps don't sleep well, force them here
            new BgTask().runInBg[
                val pm = getSystemService(PowerManager)
                var delay = 1000
                while (pm.isScreenOn() == true && delay > 0) {
                    Log.w(TAG, "Device was still interactive, try to sleep again")
                    Thread.sleep(delay)
                    delay -= 100
                    dpm.lockNow
                }
                true
            ]
        } else {
            Log.e(TAG, "Device does not have the admin rights, try to get them")
            var intent = new Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN)
            intent.putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, admin)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
        }
    }

}