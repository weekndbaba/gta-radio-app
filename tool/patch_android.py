"""Run after `flutter create`: adds background-playback wiring for audio_service."""
import glob, re

man = "android/app/src/main/AndroidManifest.xml"
x = open(man, encoding="utf-8").read()

perms = """    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.WAKE_LOCK"/>
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
"""
svc = """        <service android:name="com.ryanheise.audioservice.AudioService"
            android:foregroundServiceType="mediaPlayback"
            android:exported="true">
            <intent-filter>
                <action android:name="android.media.browse.MediaBrowserService"/>
            </intent-filter>
        </service>
        <receiver android:name="com.ryanheise.audioservice.MediaButtonReceiver"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MEDIA_BUTTON"/>
            </intent-filter>
        </receiver>
"""
if "AudioService" not in x:
    x = x.replace("<application", perms + "    <application", 1)
    x = x.replace("<application", '<application android:usesCleartextTraffic="true"', 1)
    x = x.replace("</application>", svc + "    </application>", 1)
x = re.sub(r'android:label="[^"]*"', 'android:label="Retro Radio"', x, count=1)
open(man, "w", encoding="utf-8").write(x)

for f in glob.glob("android/app/src/main/**/MainActivity.kt", recursive=True):
    k = open(f, encoding="utf-8").read()
    k = k.replace("import io.flutter.embedding.android.FlutterActivity",
                  "import com.ryanheise.audioservice.AudioServiceActivity")
    k = k.replace("FlutterActivity()", "AudioServiceActivity()")
    open(f, "w", encoding="utf-8").write(k)
print("patched")
