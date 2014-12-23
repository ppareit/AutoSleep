package be.ppareit.autosleep

import static extension be.ppareit.autosleep.App.*
import static extension be.ppareit.autosleep.AndroidUtils.*

import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.ContextWrapper
import android.content.Context
import android.content.Intent

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
        var dpm = getSystemService(DevicePolicyManager)
        var admin = new ComponentName(this, AdminReceiver)
        if (dpm.isAdminActive(admin) == true) {
            dpm.lockNow
        } else {
            var intent = new Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN)
            intent.putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, admin)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
        }
    }

}