A Widget for detecting face inside your defined box or not in real-time


## Getting started

Just add
```
face_box_camera: ^<latest-version>
```
<br/> to your `pubspec.yaml` and enjoy the widget! 

## Requirements

### Android
As this package use MLKit to detecting the face, you need to setup your app to be 
```
minSdkVersion 21
targetSdkVersion 35
compileSdkVersion 35
```
You can use higher but not lower

### iOS
<b>IMPORTANT: THIS PACKAGE IS NOT TESTED ON IOS YET. PLEASE KINDLY TEST IT BEFORE YOU DEPLOY YOUR APP TO PRODUCTION</b>
- Minimum iOS Deployment Target is 15.5
- XCode 15.3.0 or newer

_*Note: ML Kit does not support 32 bit architecture (i386 and armv7) for more info please kindly check this [link](https://developers.google.com/ml-kit/migration/ios)_


## Contribution
I'm really open to any contribution on the repository, please kindly raise an issue if you encounter any issue when you use this package. I will check it as soon as possible

## Limitation
This package is only return the first face and it is not capable to detect more face yet since the idea to create this package to detect the face inside a box or not. <br/>

And also you may detecting the liveness with this package, i can suggest you to create such steps such like blink, look right or left, and then smile. But not recommended since this steps also can reproduce with video or maybe a set of photo.
