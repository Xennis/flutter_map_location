import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_location/src/location_controller.dart';
import 'package:flutter_map_location/src/types.dart';

import 'location_marker.dart';
import 'location_options.dart';
import 'types.dart';

LocationMarkerBuilder _defaultMarkerBuilder =
    (BuildContext context, LatLngData ld, ValueNotifier<double?> heading) {
  final double diameter = ld.highAccuracy() ? 60.0 : 120.0;
  return Marker(
    point: ld.location,
    builder: (_) => LocationMarker(ld, heading),
    height: diameter,
    width: diameter,
    rotate: false,
  );
};

class LocationLayer extends StatefulWidget {
  const LocationLayer(this.options, this.map, this.stream, {Key? key})
      : super(key: key);

  final LocationOptions options;
  final MapState map;
  final Stream<Null> stream;

  @override
  _LocationLayerState createState() => _LocationLayerState();
}

class _LocationLayerState extends State<LocationLayer>
    with WidgetsBindingObserver {

  bool _locationRequested = false;
  bool _subscriptionPaused = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addObserver(this);
    if (widget.options.initiallyRequest) {
      _locationRequested = true;
      widget.options.controller.unsubscribe().then((value) => widget.options.controller.subscribe(intervalDuration: widget.options.updateInterval));
    }
    final ValueNotifier<LatLngData?> location = widget.options.controller.location;
    location.addListener(() {
      final LatLngData? loc = location.value;
      widget.options.onLocationUpdate?.call(loc);
      if (loc == null) {
        return;
      }
      if (_locationRequested) {
        _locationRequested = false;
        widget.options.onLocationRequested?.call(loc);
      }
      //setState(() {});
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance?.removeObserver(this);
    widget.options.controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.paused:
        widget.options.controller.unsubscribe();
        _subscriptionPaused = true;
        break;
      case AppLifecycleState.resumed:
        if (_subscriptionPaused) {
          widget.options.controller.subscribe();
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final LocationController controller = widget.options.controller;
    return Container(
        child: Stack(
      children: <Widget>[
        ValueListenableBuilder<LatLngData?>(
            valueListenable: controller.location,
            builder: (BuildContext context, LatLngData? ld, Widget? child) {
              if (ld == null) {
                return Container();
              }
              final LocationMarkerBuilder? customBuilder =
                  widget.options.markerBuilder;
              final Marker marker = customBuilder != null
                  ? customBuilder(context, ld, controller.heading)
                  : _defaultMarkerBuilder(context, ld, controller.heading);
              return MarkerLayerWidget(
                  options: MarkerLayerOptions(markers: <Marker>[marker]));
            }),
        widget.options.buttonBuilder(context, controller.status, () async {
          if (await controller.noSub()) {
                      widget.options.controller.unsubscribe().then((value) => widget.options.controller.subscribe(updateInterval: widget.options.updateInterval));
            _locationRequested = true;
            return;
          }

          widget.options.onLocationRequested?.call(controller.location.value);
        })
      ],
    ));
  }
    }