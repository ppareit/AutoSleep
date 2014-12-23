package be.ppareit.autosleep

import android.app.ProgressDialog
import android.os.Bundle
import android.util.Log
import org.xtendroid.annotations.AddLogTag
import org.xtendroid.app.AndroidActivity
import org.xtendroid.app.OnCreate
import org.xtendroid.utils.BgTask

import static be.ppareit.autosleep.Device.*

import static extension be.ppareit.autosleep.Settings.*

@AddLogTag
@AndroidActivity(R.layout.cancel_layout) class CancelActivity {

    @OnCreate
    def init(Bundle savedInstanceState) {
        Log.d(TAG, "initializing")

        val cancelMessage = resources.getString(R.string.cancel_message)
        val progressDialog = new ProgressDialog(this)
        val delay = settings.delay
        progressDialog.title = R.string.cancel_title
        progressDialog.message = String.format(cancelMessage, delay)
        progressDialog.indeterminate = false
        progressDialog.max = delay
        progressDialog.progress = delay
        progressDialog.progressStyle = ProgressDialog.STYLE_SPINNER // change this or progressbar
        progressDialog.setButton(ProgressDialog.BUTTON_NEGATIVE, resources.getString(R.string.cancel),
            [
                finish()
            ])
        progressDialog.setButton(ProgressDialog.BUTTON_POSITIVE, resources.getString(R.string.sleepnow),
            [
                device.turnScreenOff()
                finish()
            ])

        new BgTask().runInBgWithProgress(progressDialog,
            [
                for (i : delay .. 0) {
                    Thread.sleep(1000)
                    progressDialog.progress = i
                    runOnUiThread(
                        [
                            progressDialog.message = String.format(cancelMessage, i)
                        ])
                    if (progressDialog.showing == false) {
                        // user has removed the dialog, stop now
                        return false
                    }
                }
                progressDialog.dismiss()
                device.turnScreenOff()
                finish()
                return true
            ])
    }

}
