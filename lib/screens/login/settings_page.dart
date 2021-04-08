// TODO:
// - edit server settings
// - clear artwork cache
// - clear file cache

import 'dart:developer';

import 'package:async_redux/async_redux.dart';
import 'package:flutter/material.dart';
import 'package:subsound/screens/login/homescreen.dart';
import 'package:subsound/state/appstate.dart';
import 'package:subsound/storage/cache.dart';
import 'package:subsound/subsonic/context.dart';
import 'package:subsound/subsonic/requests/ping.dart';
import 'package:subsound/subsonic/response.dart';
import 'package:subsound/utils/utils.dart';

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        //ServerSettings(),
        DownloadCacheStatsWidget(
          stats: DownloadCacheManager().getStats(),
        ),
        ArtworkCacheStats(),
      ],
    );
  }
}

class ServerSettings extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ServerSetupForm();
  }
}

class ArtworkCacheStats extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text("Artwork Cache"),
        Text("Not implemented"),
      ],
    );
  }
}

class DownloadCacheStatsWidget extends StatelessWidget {
  final Future<CacheStats> stats;

  DownloadCacheStatsWidget({Key? key, required this.stats}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CacheStats>(
      future: stats,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          CacheStats data = snapshot.data!;
          return Column(
            children: [
              Text("Items: ${data.itemCount}"),
              Text("Storage used: ${formatFileSize(data.totalSize)}"),
            ],
          );
        } else {
          return Text("Calculating...");
        }
      },
    );
  }
}

class ServerSetupModel {
  final ServerData? inititalData;
  final Future<void> Function(ServerData) onSave;

  ServerSetupModel({
    this.inititalData,
    required this.onSave,
  });
}

class ServerSetupForm extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, ServerSetupModel>(
        converter: (store) => ServerSetupModel(
            inititalData: store.state.loginState,
            onSave: (next) => store.dispatchFuture(SaveServerState(
                  next.uri,
                  next.username,
                  next.password,
                ))),
        builder: (context, model) => _ServerSetupForm(
              onSave: model.onSave,
              inital: model.inititalData,
            ));
  }
}

class _ServerSetupForm extends StatefulWidget {
  final ServerData initialData;
  final Function(ServerData) onSave;

  const _ServerSetupForm({
    Key? key,
    ServerData? inital,
    required this.onSave,
  })   : this.initialData =
            inital ?? const ServerData(uri: '', username: '', password: ''),
        super(key: key);

  @override
  State<_ServerSetupForm> createState() => _ServerSetupFormState();
}

class _ServerSetupFormState extends State<_ServerSetupForm> {
  final _formKey = GlobalKey<FormState>();
  late ServerData _dataHolder;
  bool _canSave = false;
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    this._dataHolder = ServerData(
      uri: widget.initialData.uri,
      username: widget.initialData.username,
      password: widget.initialData.password,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
        key: _formKey,
        onChanged: () {},
        child: Column(
          children: <Widget>[
            Text('Server setup'),
            TextFormField(
              initialValue: _dataHolder.uri,
              decoration: const InputDecoration(hintText: "Enter url"),
              validator: (value) {
                log('validator: uri: $value');
                if (value?.isEmpty ?? true) {
                  return "Uri can not be blank";
                }
                var test = Uri.tryParse(value!);
                if (test == null) {
                  return "Uri must be valid";
                } else {
                  return null;
                }
              },
              onChanged: (value) {
                log("uri:onChanged $value");

                setState(() {
                  var old = _dataHolder;
                  _dataHolder = new ServerData(
                    uri: value,
                    username: old.username,
                    password: old.password,
                  );
                });
              },
            ),
            TextFormField(
              initialValue: _dataHolder.username,
              decoration: const InputDecoration(hintText: "Enter username"),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return "Username can not be blank";
                } else {
                  return null;
                }
              },
              onChanged: (value) {
                log("username:onChanged $value");

                setState(() {
                  var old = _dataHolder;
                  _dataHolder = new ServerData(
                    uri: old.uri,
                    username: value,
                    password: old.password,
                  );
                });
              },
            ),
            TextFormField(
              initialValue: _dataHolder.password,
              obscureText: true,
              decoration: const InputDecoration(hintText: "Enter password"),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return "Password can not be blank";
                } else {
                  return null;
                }
              },
              onChanged: (value) {
                log("password:onChanged");

                setState(() {
                  var old = _dataHolder;
                  _dataHolder = new ServerData(
                    uri: old.uri,
                    username: old.username,
                    password: value,
                  );
                });
              },
            ),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  ElevatedButton(
                    child: Text("Test"),
                    onPressed: _isTesting
                        ? null
                        : () async {
                            if (!_formKey.currentState!.validate()) {
                              return;
                            }
                            setState(() {
                              _isTesting = true;
                            });

                            var data = _dataHolder;
                            var ctx = new SubsonicContext(
                                serverId: '',
                                name: '',
                                endpoint: Uri.parse(data.uri),
                                user: data.username,
                                pass: data.password);
                            var pong = await Ping().run(ctx).catchError((err) {
                              log('error: network issue?', error: err);
                              return Future.value(SubsonicResponse(
                                ResponseStatus.failed,
                                "Network issue",
                                '',
                              ));
                            });
                            if (pong.status == ResponseStatus.ok) {
                              setState(() {
                                _canSave = true;
                                _isTesting = false;
                              });
                              ScaffoldMessenger.of(context)
                                ..removeCurrentSnackBar()
                                ..showSnackBar(SnackBar(
                                    content: Text("Connection successful!")));
                            } else {
                              setState(() {
                                _canSave = false;
                                _isTesting = false;
                              });

                              final errorText =
                                  "Ping server ${data.uri} failed.";

                              ScaffoldMessenger.of(context)
                                ..removeCurrentSnackBar()
                                ..showSnackBar(
                                    SnackBar(content: Text(errorText)));
                            }
                          },
                  ),
                  ElevatedButton(
                    child: _canSave ? Text("Save") : Text("Save..."),
                    onPressed: _canSave
                        ? () {
                            save().then((value) {
                              Navigator.of(context)
                                  .pushReplacementNamed(HomeScreen.routeName);
                            });
                          }
                        : null,
                  ),
                ],
              ),
            )
          ],
        ));
  }

  Future<void> save() {
    return widget.onSave(ServerData(
      uri: _dataHolder.uri,
      username: _dataHolder.username,
      password: _dataHolder.password,
    ));
  }
}
