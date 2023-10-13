import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

import '../controller/map_controller.dart';

class MapScreen extends StatelessWidget {
  MapScreen({super.key});
  final controller = Get.put(MapController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(
        () => controller.currrentLat.value == 0
            ? Center(
                child: CircularProgressIndicator(),
              )
            : Stack(
                children: [
                  GoogleMap(
                    onMapCreated: ((GoogleMapController googleMapController) =>
                        controller.mapController.complete(googleMapController)),
                    initialCameraPosition: CameraPosition(
                      target: LatLng(controller.currrentLat.value,
                          controller.currrentlong.value)!,
                      zoom: 13,
                    ),
                    onCameraIdle: () {},
                    onCameraMove: (cameraPosition) {
                      controller.dreaggedLat.value =
                          cameraPosition.target.latitude;
                      controller.draggedLong.value =
                          cameraPosition.target.longitude;
                    },
                    markers: {
                      Marker(
                        markerId: MarkerId("_currentLocation"),
                        icon: BitmapDescriptor.fromBytes(controller.bytes!),
                        // icon: BitmapDescriptor.defaultMarker,
                        position: LatLng(controller.currrentLat.value,
                            controller.currrentlong.value)!,
                        infoWindow: const InfoWindow(title: "Current Location"),
                        rotation: controller.destinationLat.value == 0.0
                            ? 200.0
                            : 120.0 +
                                controller.calculateAngle(
                                    LatLng(controller.currrentLat.value,
                                        controller.currrentlong.value)!,
                                    LatLng(controller.destinationLat.value,
                                        controller.destinationLong.value)!),
                      ),
                      if (controller.sourceLat.value != 0.0)
                        Marker(
                          markerId: MarkerId("_sourceLocation"),
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                              BitmapDescriptor.hueAzure),
                          position: LatLng(controller.sourceLat.value,
                              controller.sourceLong.value)!,
                          infoWindow: const InfoWindow(title: "Source"),
                        ),
                      if (controller.destinationLat.value != 0.0)
                        Marker(
                          markerId: MarkerId("_destinationLocation"),
                          icon: BitmapDescriptor.defaultMarker,
                          infoWindow: const InfoWindow(title: "Destination"),
                          position: LatLng(controller.destinationLat.value,
                              controller.destinationLong.value)!,
                        )
                    },
                    polylines: Set<Polyline>.of(controller.polylines.values),
                  ),
                  if (controller.isDestinationChoose.value == true)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 70,
                            child: Image.asset("assets/pin.png"),
                          ),
                        ],
                      ),
                    ),
                  if (controller.isDestinationChoose.value == true)
                    Positioned(
                      bottom: 60,
                      left: 50,
                      right: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          controller.updateDestinationAndSource();
                          controller.getPolylinePoints().then((coordinates) => {
                                controller
                                    .generatePolyLineFromPoints(coordinates),
                              });
                          controller.isDestinationChoose.value = false;
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                        child: const Text(
                          "Confirm Destination",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  if (controller.isDestinationChoose.value == false)
                    Positioned(
                      bottom: 60,
                      left: 50,
                      right: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          controller.isDestinationChoose.value = true;
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                        child: const Text(
                          "Choose Destination",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
