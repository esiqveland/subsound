import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:subsound/screens/login/homescreen.dart';
import 'package:subsound/subsonic/context.dart';
import 'package:subsound/subsonic/requests/ping.dart';
import 'package:subsound/subsonic/response.dart';

class LoginScreen extends StatefulWidget {
  static final routeName = "/settings";

  LoginScreen({Key key}) : super(key: key);

  @override
  LoginScreenState createState() => LoginScreenState();
}

class ServerData {
  String uri;
  String username;
  String password;

  ServerData({
    @required this.uri,
    @required this.username,
    @required this.password,
  });

  static fromPrefs(SharedPreferences prefs) {
    return new ServerData(
      uri: prefs.getString("uri") ?? "https://",
      username: prefs.getString("username") ?? "",
      password: prefs.getString("password") ?? "",
    );
  }

  static Future<ServerData> store(SharedPreferences prefs, ServerData data) {
    return Future.wait([
      prefs.setString("uri", data.uri),
      prefs.setString("username", data.username),
      prefs.setString("password", data.password),
    ]).then((value) => data);
  }
}

class LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  ServerData _data;
  bool _canSave = false;
  bool _isTesting = false;

  Future<void> save() async {
    final SharedPreferences prefs = await _prefs;
    var copy = _data;
    await ServerData.store(prefs, copy);
  }

  void load() async {
    log('load:init');
    final SharedPreferences prefs = await _prefs;
    log('load:init:prefs');
    var data = ServerData.fromPrefs(prefs);
    setState(() {
      log('load:init:set');
      _data = data;
    });
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SharedPreferences Demo"),
      ),
      body: Center(
          child: FutureBuilder<SharedPreferences>(
              future: _prefs,
              builder: (BuildContext context,
                  AsyncSnapshot<SharedPreferences> snapshot) {
                switch (snapshot.connectionState) {
                  case ConnectionState.waiting:
                    return const CircularProgressIndicator();
                  default:
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else {
                      return Form(
                          key: _formKey,
                          onChanged: () {},
                          child: Column(
                            children: <Widget>[
                              Text('Server setup'),
                              TextFormField(
                                initialValue: _data.uri,
                                decoration: const InputDecoration(
                                    hintText: "Enter uri"),
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
                                    var old = _data;
                                    _data = new ServerData(
                                        uri: value,
                                        username: old.username,
                                        password: old.password);
                                  });
                                },
                              ),
                              TextFormField(
                                initialValue: _data.username,
                                decoration: const InputDecoration(
                                    hintText: "Enter username"),
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
                                    var old = _data;
                                    _data = new ServerData(
                                        uri: old.uri,
                                        username: value,
                                        password: old.password);
                                  });
                                },
                              ),
                              TextFormField(
                                initialValue: _data.password,
                                obscureText: true,
                                decoration: const InputDecoration(
                                    hintText: "Enter password"),
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
                                    var old = _data;
                                    _data = new ServerData(
                                        uri: old.uri,
                                        username: old.username,
                                        password: value);
                                  });
                                },
                              ),
                              Center(
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: <Widget>[
                                    ElevatedButton(
                                      child: Text("Test"),
                                      onPressed: _isTesting
                                          ? null
                                          : () async {
                                              if (!_formKey.currentState
                                                  .validate()) {
                                                return;
                                              }
                                              setState(() {
                                                _isTesting = true;
                                              });

                                              var data = _data;
                                              var ctx = new SubsonicContext(
                                                  serverId: '',
                                                  name: '',
                                                  endpoint: Uri.parse(data.uri),
                                                  user: data.username,
                                                  pass: data.password);
                                              var pong = await Ping()
                                                  .run(ctx)
                                                  .catchError((err) {
                                                log('error: network issue?',
                                                    error: err);
                                                return SubsonicResponse(
                                                    ResponseStatus.failed,
                                                    "Network issue",
                                                    null);
                                              });
                                              if (pong.status ==
                                                  ResponseStatus.ok) {
                                                setState(() {
                                                  _canSave = true;
                                                  _isTesting = false;
                                                });
                                                ScaffoldMessenger.of(context)
                                                  ..removeCurrentSnackBar()
                                                  ..showSnackBar(SnackBar(
                                                      content: Text(
                                                          "Connection successful!")));
                                              } else {
                                                setState(() {
                                                  _canSave = false;
                                                  _isTesting = false;
                                                });

                                                final errorText =
                                                    "Ping server ${data.uri} failed.";

                                                ScaffoldMessenger.of(context)
                                                  ..removeCurrentSnackBar()
                                                  ..showSnackBar(SnackBar(
                                                      content:
                                                          Text(errorText)));
                                              }
                                            },
                                    ),
                                    ElevatedButton(
                                      child: _canSave
                                          ? Text("Save")
                                          : Text("Save..."),
                                      onPressed: _canSave
                                          ? () {
                                              save().then((value) {
                                                Navigator.of(context)
                                                    .pushReplacementNamed(
                                                        HomeScreen.routeName);
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
                }
              })),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: _incrementCounter,
      //   tooltip: 'Increment',
      //   child: const Icon(Icons.add),
      // ),
    );
  }
}
