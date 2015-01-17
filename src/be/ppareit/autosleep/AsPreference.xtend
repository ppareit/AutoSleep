package be.ppareit.autosleep

import android.app.AlertDialog
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Intent
import android.os.Bundle
import android.preference.Preference
import android.preference.PreferenceActivity
import android.preference.SwitchPreference
import android.text.util.Linkify
import android.util.Log
import com.anjlab.android.iab.v3.BillingProcessor
import com.anjlab.android.iab.v3.TransactionDetails
import org.xtendroid.annotations.AddLogTag

import static be.ppareit.autosleep.App.*

import static extension be.ppareit.autosleep.AndroidUtils.*
import static extension be.ppareit.autosleep.Settings.*
import static extension org.xtendroid.utils.AlertUtils.*
import android.content.SharedPreferences

@AddLogTag
class AsPreference //
extends PreferenceActivity //
implements BillingProcessor.IBillingHandler, //
SharedPreferences.OnSharedPreferenceChangeListener {

    SwitchPreference mServicerunningSwitch
    Preference mAllowCancelPref
    Preference mDelayPref
    Preference mAboutPref
    Preference mDonatePref

    BillingProcessor mBillingProcessor

    static final String LICENSE_KEY = "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAnLPzGoqwyIp8hhZG+mnzY4JI3giOxY6y7xrRGTf0FdA3rKGeBBTexjyBCFJjYR89QYBou8ihrFTYQEdge3Vh5Pm/u77iKkDi7EDKF7zWR/ColnTTwayooSPiBgQ/DitYQeKqKROod85GN5uMfqT6IeGU4sN+lP70e+SHrlyAAWRG16QTuWx/tPbCx5i4/MDDmxCK5FcAaAk63moEuaih4iX+nkj5ZlbUX4jAqnERcdS9IeaBoUZeNa4L1qAtbxwvdIYfGKLBRVVRD042erNvr0nHJuVNSWJPaNthvHSN1YwMqq/CkVTr9Y4fZGInuIR1dLTvgQ71CNobLYbsqq/RRQIDAQAB"

    static final int REQUEST_ADMIN_RIGHTS = 14

    override onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState)

        addPreferencesFromResource(R.xml.mainpreferences)

        mServicerunningSwitch = findPref("runservice")
        mServicerunningSwitch.onPreferenceChangeListener = [ pref, value |
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

        mAllowCancelPref = findPref("allowcancel")
        mAllowCancelPref.enabled = settings.runservice

        mDelayPref = findPref("delay")
        mDelayPref.enabled = settings.runservice && settings.allowcancel

        mAboutPref = findPref("about")
        mAboutPref.onPreferenceClickListener = [
            var ad = new AlertDialog.Builder(this) //
            .setTitle(R.string.about) //
            .setMessage(R.string.about_message) //
            .setPositiveButton(getText(android.R.string.ok), []) //
            .create()
            ad.show();
            Linkify.addLinks(ad.findView(android.R.id.message), Linkify.ALL);
            true
        ]

        mBillingProcessor = new BillingProcessor(this, LICENSE_KEY, this)

        mDonatePref = findPref("donate")
        mDonatePref.onPreferenceChangeListener = [ pref, value |
            var item = value as String
            mBillingProcessor.purchase(this, item)
            Log.d(TAG, "Great, user is donating item: " + item)
            true
        ]
    }

    override onResume() {
        super.onResume()
        sharedPreferences.registerOnSharedPreferenceChangeListener(this)
    }

    override onPause() {
        super.onPause()
        sharedPreferences.unregisterOnSharedPreferenceChangeListener(this)
    }

    override onDestroy() {
        mBillingProcessor?.release()
        super.onDestroy()
    }

    override onSharedPreferenceChanged(SharedPreferences sp, String key) {
        mAllowCancelPref.enabled = settings.runservice
        mDelayPref.enabled = settings.runservice && settings.allowcancel
    }

    override onActivityResult(int requestCode, int resultCode, Intent data) {

        if (!mBillingProcessor.handleActivityResult(requestCode, resultCode, data))
            super.onActivityResult(requestCode, resultCode, data);

        if (requestCode == REQUEST_ADMIN_RIGHTS) {
            if (resultCode == RESULT_CANCELED) {
                Log.d(TAG, "No admin rights given")
                settings.runservice = false
                mServicerunningSwitch.checked = false
                var intent = new Intent(this, AsService)
                stopService(intent)
                toast("No admin rights given, disabling")
            }
        }
    }

    override onBillingError(int errorCode, Throwable error) {
        Log.d(TAG, "Billing Error")
        Log.e(TAG, "\terrorCode = " + errorCode)
        Log.e(TAG, "\terror = " + error?.toString())
    }

    override onBillingInitialized() {
        Log.d(TAG, "Billing Initialized")
    }

    override onProductPurchased(String productId, TransactionDetails details) {
        Log.d(TAG, "Product Purchased")
        mBillingProcessor.consumePurchase(productId)
        toast(getString(R.string.donated_thank_user))
    }

    override onPurchaseHistoryRestored() {
        Log.d(TAG, "Purchase History Restored")
    }

}
