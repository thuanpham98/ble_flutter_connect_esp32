import 'package:permission_handler/permission_handler.dart';

class PermissionsService {
  Future<bool> _requestPermission(Permission permission) async {
    final status = await permission.request();
    if (status == PermissionStatus.granted) {
      return true;
    }

    return false;
  }

  Future<bool> requestContactsPermission({Function onPermissionDenied}) async {
    var granted = await _requestPermission(Permission.contacts);
    if (!granted) {
      onPermissionDenied();
    }
    return granted;
  }
  Future<bool> hasContactsPermission() async {
    return hasPermission(Permission.contacts);
  }

  /// Requests the users permission to read their location when the app is in use
  Future<bool> requestLocationPermission() async {
    return _requestPermission(Permission.locationWhenInUse);
  }

  Future<bool> requestPhotoPermission() async {
    return _requestPermission(Permission.photos);
  }

  Future<bool> hasPhotoPermission() async {
    return hasPermission(Permission.photos);
  }


  Future<bool> hasPermission(Permission permission) async {
    var permissionStatus = await permission.status;
    return permissionStatus == PermissionStatus.granted;
  }
}
