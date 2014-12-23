package be.ppareit.autosleep

import android.app.AlarmManager
import android.app.admin.DevicePolicyManager
import android.content.Context
import android.preference.Preference
import android.preference.PreferenceActivity
import android.os.PowerManager

class AndroidUtils {

    def static <T extends Preference> T findPref(PreferenceActivity it, CharSequence key) {
        return it.findPreference(key) as T;
    }

    static def <T> T getSystemService(Context context, Class<T> t) {
        
        var name = switch t {
            case AlarmManager : Context.ALARM_SERVICE
            case DevicePolicyManager : Context.DEVICE_POLICY_SERVICE
            case PowerManager : Context.POWER_SERVICE
        }
        return context.getSystemService(name) as T;
        
    }

}