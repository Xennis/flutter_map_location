# Flutter Map – Location plugin

[![Flutter](https://github.com/Xennis/flutter_map_location/workflows/Flutter/badge.svg?branch=master&event=push)](https://github.com/Xennis/flutter_map_location/actions?query=workflow%3A%22Flutter%22+event%3Apush+branch%3Amaster) [![Pub](https://img.shields.io/pub/v/flutter_map_location.svg)](https://pub.dev/packages/flutter_map_location)

A [flutter_map](https://pub.dev/packages/flutter_map) plugin to request and display the users location and heading on the map. The core features of the plugin are:

* Customization: The location button and marker can be completly customized.
* Energy efficiency: The location service is turned off if the app runs in the background.
* Usability: Developers are empowered to ensure a good [user experience](#User-experience).

## Development branch

Use the [dev](https://github.com/Xennis/flutter_map_location/tree/dev) for the latest changes. `flutter_map` merged recently a lot of changes but did not create a release yet. It's only possible to release Flutter packages with dependencies that are released as well. Therefore checkout this branch for the newest (unreleased) changes:

```yaml
  flutter_map_location:
    git:
      url: https://github.com/Xennis/flutter_map_location.git
      ref: dev
```

## User experience

Status

* [x] The location button can be changed dependening on the location services status. For example also Google Maps shows a different icon if the location service is off.
* [x] The marker icon can be changed depending on the location accuracy.
* [x] It's possible to show the information (e.g. in form of a snackbar) to the user that the user location is outside of the map bounds.
* [x] The location heading is also shown for devices without an gyroscope. We [patched flutter_compass](https://github.com/hemanthrajv/flutter_compass/pull/38) for that.

## Installation

Add flutter_map to your pubspec:

```yaml
dependencies:
  flutter_map_location: any # or the latest version on Pub
```

### Android

Ensure the following permissions are present in `<project-root>/android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

See [reference example code](https://github.com/Xennis/flutter_map_location/blob/f864b737cfe6371a297cee3be076b6bc117f572c/example/android/app/src/main/AndroidManifest.xml#L4-L5)

### iOS

Ensure the following permission is present in `<project-root>/ios/Runner/Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>App needs access to location and direction when open.</string>
```

See [reference example code](https://github.com/Xennis/flutter_map_location/blob/f864b737cfe6371a297cee3be076b6bc117f572c/example/ios/Runner/Info.plist#L5-L6)

## Usage

Look at the [default example](https://github.com/Xennis/flutter_map_location/blob/master/example/lib/pages/default.dart) and the notes inside the code. That's a working example.

## Demo / example

A working example can be found in the `example/` directory. It contains a page with the default settings:

![Default example](https://raw.githubusercontent.com/Xennis/flutter_map_location/master/example/default.png)

... and one with customized button and marker:

![Custom example](https://raw.githubusercontent.com/Xennis/flutter_map_location/master/example/custom.png)

(Map attribution: © [OpenStreetMap](https://www.openstreetmap.org/copyright) contributors)

## Credits

The plugin is inspired by [user_location_plugin](https://github.com/igaurab/user_location_plugin) by [igaurab](https://github.com/igaurab).