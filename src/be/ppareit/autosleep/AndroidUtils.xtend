package be.ppareit.autosleep

import android.app.AlarmManager
import android.app.admin.DevicePolicyManager
import android.content.Context
import android.preference.Preference
import android.preference.PreferenceActivity

class AndroidUtils {

    def static <T extends Preference> T findPref(PreferenceActivity it, CharSequence key) {
        return it.findPreference(key) as T;
    }

    static def <T> T getSystemService(Context context, Class<T> t) {
        
        var name = switch t {
            case DevicePolicyManager : Context.DEVICE_POLICY_SERVICE
            case AlarmManager : Context.ALARM_SERVICE
        }
        return context.getSystemService(name) as T;
        
    }

}