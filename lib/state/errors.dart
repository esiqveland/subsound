import 'package:async_redux/async_redux.dart';
import 'package:subsound/state/appstate.dart';

class DisplayError extends ReduxAction<AppState> {
  final String errorMessage;

  DisplayError(this.errorMessage);

  @override
  Future<AppState?> reduce() async {
    return null;
  }
}
