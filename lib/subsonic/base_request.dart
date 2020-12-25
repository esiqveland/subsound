import 'context.dart';
import 'response.dart';

abstract class BaseRequest<T> {
  String get sinceVersion;

  Future<SubsonicResponse<T>> run(SubsonicContext ctx);
}
