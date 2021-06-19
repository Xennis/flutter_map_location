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
    (BuildContext context, LatLngData ld) {
  final double diameter = ld.highAccuracy() ? 60.0 : 120.0;
  return Marker(
    point: ld.location,
    builder: (_) => LocationMarker(ld),
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
  Stream<LatLngData?>? _positionStream;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addObserver(this);
    if (widget.options.initiallyRequest) {
      _locationRequested = true;
      subscribeToPosition();
    }
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
          _subscriptionPaused = false;
          subscribeToPosition();
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  void subscribeToPosition() {
    // Ensure there is just one subscription
    widget.options.controller.unsubscribe().then((void value) {
      setState(() {
        _positionStream = widget.options.controller.subscribe(widget.options.updateInterval);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final LocationController controller = widget.options.controller;
    return Container(
        child: Stack(
      children: <Widget>[
        StreamBuilder<LatLngData?>(
            stream: widget.options.controller
                .subscribe(widget.options.updateInterval),
            initialData: null,
            builder:
                (BuildContext context, AsyncSnapshot<LatLngData?> snapshot) {
              final LatLngData? ld = snapshot.data;
              if (ld == null) {
                return Container();
              }

              widget.options.onLocationUpdate?.call(ld);
              if (_locationRequested) {
                _locationRequested = false;
                widget.options.onLocationRequested?.call(ld);
              }

              final LocationMarkerBuilder? customBuilder =
                  widget.options.markerBuilder;
              final Marker marker = customBuilder != null
                  ? customBuilder(context, ld)
                  : _defaultMarkerBuilder(context, ld);
              return MarkerLayerWidget(
                  options: MarkerLayerOptions(markers: <Marker>[marker]));
            }),
        widget.options.buttonBuilder(context, controller.status, () async {
          if (await controller.noSub()) {
            _locationRequested = true;
            subscribeToPosition();
            return;
          }

          widget.options.onLocationRequested?.call(controller.location.value);
        })
      ],
    ));
  }
}
