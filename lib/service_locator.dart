import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'services/logger_service.dart';
import 'services/permissions_service.dart';
import 'services/ble_service.dart';

final GetIt locator =GetIt.instance;
Logger log =Logger();

Future setupLocator() async {
  locator.registerSingleton<LoggerService>(LoggerService.getInstance());
  log = locator<LoggerService>().getLog();

  locator.registerSingleton<PermissionsService>(PermissionsService());

  locator.registerSingleton<BleService>(BleService.getInstance());
}