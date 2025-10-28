import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_map/constants.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class GoogleMapPage extends StatefulWidget {
  const GoogleMapPage({super.key});

  @override
  State<GoogleMapPage> createState() => _GoogleMapPageState();
}

class _GoogleMapPageState extends State<GoogleMapPage> {
  final locationController = Location();
  static const googlePlex = LatLng(37.4223, -122.0848);
  static const mountainView = LatLng(37.3861, -122.0839);
  CameraPosition _initialCameraPosition= const CameraPosition(
      target: googlePlex, zoom: 13
  );
  LatLng? currentPosition;
  Map<PolylineId,Polyline> polylines={};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_)async=>await initializeGoogleMap());
  }
  Future<void> initializeGoogleMap()async{
    await fetchLocationUpdates();
    final coordinates= await fetchPolyLinePoints();
    generatePolyLineFromPoints(coordinates);
  }
  Future<void> fetchLocationUpdates() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await locationController.serviceEnabled();
    if (serviceEnabled) {
      serviceEnabled = await locationController.requestService();
    } else {
      return;
    }

    permissionGranted = await locationController.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await locationController.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }
    locationController.onLocationChanged.listen((currentLocation) {
      if (currentLocation.latitude != null &&
          currentLocation.longitude != null) {
        setState(() {
          currentPosition =
              LatLng(currentLocation.latitude!, currentLocation.longitude!);
          _initialCameraPosition= CameraPosition(
            target: currentPosition!
          );
        });
      }
    });
  }
  Future<List<LatLng>> fetchPolyLinePoints()async{
    final polyLinePoints= PolylinePoints();
    final result= await polyLinePoints.getRouteBetweenCoordinates(
        googleApiKey: googleMapsApiKey,
      request: PolylineRequest(
          origin: PointLatLng(googlePlex.latitude, googlePlex.longitude),
          destination: PointLatLng(mountainView.latitude, mountainView.longitude),
          mode:TravelMode.driving
      )
    );
    if(result.points.isNotEmpty){
      return result.points.map((point)=>LatLng(point.latitude, point.longitude)).toList();
    }else{
      return[];
    }
  }
  Future<void> generatePolyLineFromPoints(List<LatLng> polylineCoordinates)async{
    const id= PolylineId('polyline');
    final polyline= Polyline(polylineId: id,
    color: Colors.black54,
      points: polylineCoordinates,
      width: 7
    );
    setState(() {
      polylines[id]= polyline;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: currentPosition == null
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : GoogleMap(
              initialCameraPosition:_initialCameraPosition,
              markers: {
                Marker(
                    markerId: MarkerId('currentLocation'),
                    icon: BitmapDescriptor.defaultMarker,
                    position: currentPosition!),
                Marker(
                    markerId: MarkerId('sourceLocation'),
                    icon: BitmapDescriptor.defaultMarker,
                    position: googlePlex),
                Marker(
                    markerId: MarkerId('destinationLocation'),
                    icon: BitmapDescriptor.defaultMarker,
                    position: mountainView),
              },
        polylines: Set<Polyline>.of(polylines.values),
            ),
    );
  }
}
