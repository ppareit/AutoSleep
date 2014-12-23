package be.ppareit.autosleep

import android.content.Intent
import android.os.Bundle
import android.preference.PreferenceActivity
import android.preference.SwitchPreference
import org.xtendroid.annotations.AddLogTag

import static extension be.ppareit.autosleep.AndroidUtils.*
import static extension be.ppareit.autosleep.App.*
import static extension be.ppareit.autosleep.Settings.*

import static extension org.xtendroid.utils.AlertUtils.*

import android.content.ComponentName
import android.app.admin.DevicePolicyManager
import android.util.Log
import android.preference.Preference
import android.app.AlertDialog
import android.text.util.Linkify

@AddLogTag
class AsPreference extends PreferenceActivity {

    SwitchPreference servicerunningSwitch
    Preference about

    static final int REQUEST_ADMIN_RIGHTS = 14

    override onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState)

        addPreferencesFromResource(R.xml.mainpreferences)

        servicerunningSwitch = findPref("runservice")
        servicerunningSwitch.onPreferenceChangeListener = [ pref, value |
            var intent = new Intent(this, AsService)
            if (value == true) {
                Log.d(TAG, "Checking admin rights")
                if (app.hasAdminRights() == false) {
                    Log.d(TAG, "No admin rights, asking for permission")
                    var admin = new ComponentName(this, AdminReceiver)
                    var adminIntent = new Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN)
                    adminIntent.putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, admin)
                    startActivityForResult(adminIntent, REQUEST_ADMIN_RIGHTS)
                }
                startService(intent)
            } else {
                stopService(intent)
            }
            return true
        ]

        about = findPref("about")
        about.onPreferenceClickListener = [
            var ad = new AlertDialog.Builder(this) //
                        .setTitle(R.string.about) //
                        .setMessage(R.string.about_message) //
                        .setPositiveButton(getText(android.R.string.ok), []) //
                        .create()
            ad.show();
            Linkify.addLinks(ad.findView(android.R.id.message), Linkify.ALL);
            true
        ]
    }

    protected override def onActivityResult(int requestCode, int resultCode,
             Intent data) {
         if (requestCode == REQUEST_ADMIN_RIGHTS) {
             if (resultCode == RESULT_CANCELED) {
                 Log.d(TAG, "No admin rights given")
                 settings.runservice = false
                 servicerunningSwitch.checked = false
                 var intent = new Intent(this, AsService)
                 stopService(intent)
                 toast("No admin rights given, disabling")
             }
         }
     }
    

}



