# Retro Radio (Android)

Background-playing radio app: group cards -> station carousel, notification /
lock-screen / Bluetooth controls, keeps playing after you close the app.


## Offline mode (bundled audio)
Put audio in `assets/audio/<Group_Name>/<Station_Name>.mp3` (see `assets/audio/README.txt`),
delete `assets/audio/Example_Group/`, upload, and let the workflow build. The build
script turns folders into group cards and files into stations automatically, and the
app then plays fully offline. Only use audio you have the rights to.
Size tips: use 64-128 kbps MP3s. GitHub's browser upload allows 25 MB per file (100 MB
via git); everything you add makes the APK bigger.

Online streams still work too: if you add no audio, `assets/stations.json` (editable by
hand) is used, and a station `url` may be a stream link or an `assets/...` path.

## Keep it playing on Xiaomi/Oppo/Vivo/Samsung
Settings -> Apps -> Retro Radio -> Battery -> set to "Unrestricted"/"No restrictions".
"# gta-radio-app" 
