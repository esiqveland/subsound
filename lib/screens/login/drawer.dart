import 'package:flutter/material.dart';
import 'package:subsound/screens/login/homescreen.dart';
import 'package:subsound/screens/login/loginscreen.dart';

class MyDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
                //color: Colors.blue,
                ),
            child: Text(
              'Subsound',
              style: TextStyle(
                //color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.star),
            title: Text("Starred"),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => HomeScreen(
                        initialTabIndex: 0,
                      )));
            },
          ),
          ListTile(
            leading: Icon(Icons.music_note),
            title: Text("Artists"),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => HomeScreen(
                        initialTabIndex: 1,
                      )));
            },
          ),
          ListTile(
            leading: Icon(Icons.album),
            title: Text("Albums"),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => HomeScreen(
                        initialTabIndex: 2,
                      )));
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text("Settings"),
            onTap: () {
              Navigator.of(context).pushNamed(LoginScreen.routeName);
            },
          ),
        ],
      ),
    );
  }
}
