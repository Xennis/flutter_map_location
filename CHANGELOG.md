## 0.12.0

* Update flutter_map to support null safety, map rotation and latlong2 (#66)
* Add null safety (#66)
* Add map rotation support (#66)
* Use latlong2 package instead of latlong (#66)

Thanks to TheOneWithTheBraid for the contribution.

## 0.11.0

* BREAKING CHANGE: Plugin option `updateIntervalMs` of type `int` was removed. Instead the option `updateInterval` of type `Duration` was added. Example: Replace `updateIntervalMs: 1000` by `updateInterval: Duration(seconds: 1)`.
* Update flutter_compass to remove indirect rxdart dependency

## 0.10.0

* Switch from `location` to `geolocator` package (#54)

Thanks to TheOneWithTheBraid for the contribution.

## 0.9.0

* Add `initiallyRequest` option to set if location should initially requested (#38)

Thanks to TheOneWithTheBraid for the contribution.

## 0.8.0

* BREAKING CHANGE: Integrated the marker layer into the plugin. The option `markers` is removed. A `MarkerLayerOptions` outside of the plugin is not needed anymore. See update example for usage.

## 0.7.1+2

* Update dependencies

## 0.7.1+1

* Update dependencies

## 0.7.1

* Fix location marker is centered correctly (#29 by @sjmallon)

## 0.7.0+2

* Update dependencies

## 0.7.0+1

* Update dependencies

## 0.7.0

* Show larger circle for inaccurate location.
* Show heading for accurate location only.
* Add possiblity to change marker icon depending on the location accuracy.
* BREAKING CHANGE: All options return the type `LatLngData` instead of `LatLng`.

## 0.6.0

* Update flutter_compass to allow usage of geomagnetic rotation sensor as fallback on Android.

## 0.5.0

* First public development release.
