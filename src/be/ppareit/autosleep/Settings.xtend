package be.ppareit.autosleep

import org.xtendroid.annotations.AndroidPreference

@AndroidPreference class Settings {
    boolean runservice = true
    boolean allowcancel = true
    
    /**
     * @return timeout for torch in seconds
     */
    def int getDelay() {
        var _delayString = pref.getString("delay", "15");
        var _delay = Integer.valueOf(_delayString);
        return _delay;
    }
}