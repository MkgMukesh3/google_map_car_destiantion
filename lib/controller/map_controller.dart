import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mukesh_gupta_task/consts.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class MapController extends GetxController {
  RxInt val = 0.obs;
  RxDouble currrentLat = 0.0.obs;
  RxDouble currrentlong = 0.0.obs;
  RxDouble destinationLat = 0.0.obs;
  RxDouble destinationLong = 0.0.obs;
  RxDouble sourceLat = 0.0.obs;
  RxDouble sourceLong = 0.0.obs;
  RxDouble dreaggedLat = 0.0.obs;
  RxDouble draggedLong = 0.0.obs;
  Location _locationController = new Location();
  RxBool isDestinationChoose = false.obs;
  Completer<GoogleMapController> mapController =
      Completer<GoogleMapController>();
  Map<PolylineId, Polyline> polylines = {};

  @override
  void onInit() {
    super.onInit();
    getMarkerImages();
    getLocationUpdates();
  }

  Uint8List? bytes;
  getMarkerImages() async {
    String imgurl = "https://cdn-icons-png.flaticon.com/128/1048/1048313.png";
    bytes = (await NetworkAssetBundle(Uri.parse(imgurl)).load(imgurl))
        .buffer
        .asUint8List();
    refresh();
  }

  void updateDestinationAndSource() {
    destinationLat.value = dreaggedLat.value;
    destinationLong.value = draggedLong.value;
    sourceLat.value = currrentLat.value;
    sourceLong.value = currrentlong.value;
  }

  double calculateAngle(LatLng from, LatLng to) {
    final double lat1 = from.latitude * (pi / 180);
    final double long1 = from.longitude * (pi / 180);
    final double lat2 = to.latitude * (pi / 180);
    final double long2 = to.longitude * (pi / 180);

    final double deltaLong = long2 - long1;

    final double y = sin(deltaLong) * cos(lat2);
    final double x =
        cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(deltaLong);

    return atan2(y, x) * (180 / pi);
  }

  Future<void> getLocationUpdates() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await _locationController.serviceEnabled();
    if (_serviceEnabled) {
      _serviceEnabled = await _locationController.requestService();
    } else {
      return;
    }

    _permissionGranted = await _locationController.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await _locationController.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    _locationController.onLocationChanged
        .listen((LocationData currentLocation) {
      if (currentLocation.latitude != null &&
          currentLocation.longitude != null) {
        currrentLat.value = currentLocation.latitude!;
        currrentlong.value = currentLocation.longitude!;
        isDestinationChoose.value == false
            ? _cameraToPosition(
                LatLng(currentLocation.latitude!, currentLocation.longitude!)!)
            : null;
        destinationLat.value != 0.0
            ? getPolylinePoints().then((coordinates) => {
                  generatePolyLineFromPoints(coordinates),
                })
            : null;
      }
    });
  }

  Future<void> _cameraToPosition(LatLng pos) async {
    final GoogleMapController controller = await mapController.future;
    CameraPosition _newCameraPosition = CameraPosition(
      target: pos,
      zoom: 13,
    );
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(_newCameraPosition),
    );
  }

  Future<List<LatLng>> getPolylinePoints() async {
    List<LatLng> polylineCoordinates = [];
    PolylinePoints polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      GOOGLE_MAPS_API_KEY,
      PointLatLng(currrentLat.value, currrentlong.value),
      PointLatLng(destinationLat.value, destinationLong.value),
      travelMode: TravelMode.driving,
    );
    if (result.points.isNotEmpty) {
      result.points.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
    } else {
      print(result.errorMessage);
    }
    return polylineCoordinates;
  }

  void generatePolyLineFromPoints(List<LatLng> polylineCoordinates) async {
    PolylineId id = PolylineId("poly");
    Polyline polyline = Polyline(
        polylineId: id,
        color: Colors.blue,
        points: polylineCoordinates,
        width: 8);

    polylines[id] = polyline;
  }
}
