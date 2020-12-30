import 'dart:developer';

import 'package:async_redux/async_redux.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:subsound/screens/login/homescreen.dart';
import 'package:subsound/screens/login/myscaffold.dart';
import 'package:subsound/state/appstate.dart';
import 'package:subsound/subsonic/context.dart';
import 'package:subsound/subsonic/requests/ping.dart';
import 'package:subsound/subsonic/response.dart';

class LoginScreen extends StatelessWidget {
  static final routeName = "/settings";

  LoginScreen({Key key}) : super(key: key);

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
      builder: (context, model) => MyScaffold(
        title: const Text("Settings"),
        body: (context) => Center(
          child: ServerSetupForm(
            initialData: model.inititalData,
            onSave: model.onSave,
            //onSave: ,
          ),
        ),
      ),
    );
  }
}

class ServerSetupModel {
  final ServerData inititalData;
  final Future<void> Function(ServerData) onSave;

  ServerSetupModel({
    this.inititalData,
    this.onSave,
  });
}

class ServerSetupForm extends StatefulWidget {
  final ServerData initialData;
  final Function(ServerData) onSave;

  const ServerSetupForm({
    Key key,
    this.initialData,
    this.onSave,
  }) : super(key: key);

  @override
  _ServerSetupFormState createState() => _ServerSetupFormState(
        initialData: initialData,
        onSave: onSave,
      );
}

class _ServerSetupFormState extends State<ServerSetupForm> {
  final ServerData initialData;
  final Function(ServerData) onSave;

  final _formKey = GlobalKey<FormState>();
  ServerData _dataHolder;
  bool _canSave = false;
  bool _isTesting = false;

  _ServerSetupFormState({
    ServerData initialData,
    this.onSave,
  })  : this.initialData = initialData,
        this._dataHolder = ServerData(
          uri: initialData.uri,
          username: initialData.username,
          password: initialData.password,
        );

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
              decoration: const InputDecoration(hintText: "Enter uri"),
              validator: (value) {
                log('validator: uri: $value');
                if (value.isEmpty) {
                  return "Uri can not be blank";
                }
                var test = Uri.tryParse(value);
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
                if (value.isEmpty) {
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
                if (value.isEmpty) {
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
                            if (!_formKey.currentState.validate()) {
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
                              return SubsonicResponse(
                                  ResponseStatus.failed, "Network issue", null);
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
    return onSave(ServerData(
      uri: _dataHolder.uri,
      username: _dataHolder.username,
      password: _dataHolder.password,
    ));
  }
}
