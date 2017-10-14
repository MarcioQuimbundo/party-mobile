import 'dart:async';

import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';

import 'package:party/app_context.dart';
import 'package:party/constants.dart';
import 'package:spotify/spotify_io.dart' show PlaylistSimple;

class PlaylistsPage extends StatefulWidget {
  PlaylistsPage({Key key}) : super(key: key);

  static final handler = new Handler(
      handlerFunc: (BuildContext context, Map<String, dynamic> params) {
        // TODO: Figure out how to properly logout if necessary
//        app.logoutIfNecessary(context);
        
        return new PlaylistsPage();
      }
  );

  @override
  _PlaylistsPageState createState() => new _PlaylistsPageState();
}

class _PlaylistsPageState extends State<PlaylistsPage> {
  bool _loading = true;

  bool _forceLoad = false;
  Future<Iterable<PlaylistSimple>> get _loadPlaylists {
    if (app.playlists.length == 0 || _forceLoad) {
      _forceLoad = false;
      var futurePlaylists = app.spotify.client.playlists.me();
      return futurePlaylists.then((playlists) {
        app.playlists.clear();
        app.playlists.addAll(playlists);
        return playlists;
      });
    } else {
      return new Future.value(app.playlists);
    }
  }

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[
//      new IconButton(
//        icon: new Icon(Icons.playlist_play),
//        tooltip: 'Now Playing',
//        onPressed: null,
//      ),
      new PopupMenuButton(
        onSelected: (String result) { app.logout(context); },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          const PopupMenuItem(value: 'logout', child: const Text('Logout'))
        ],
      )
    ];

    if (!_loading) {
      actions.insert(0, new IconButton(
        icon: new Icon(Icons.refresh, color: Constants.colorAccentLight),
        tooltip: 'Refresh',
        onPressed: () {
          setState(() {
            _forceLoad = true;
          });
        },
      ));
    }

//    if (_playlists.length > 0) {
//      playlists.add(
//          new LinearProgressIndicator(
//            valueColor: Constants.loadingColorAnimation, ,
//            backgroundColor: Constants.colorPrimary,
//          )
//      );
//    }

    return new Scaffold(
        appBar: new AppBar(
          title: new Text("Your Playlists"),
          actions: actions,
          backgroundColor: Constants.statusBarColor,
          elevation: 4.0,
        ),
        backgroundColor: Constants.colorPrimaryDark,
        bottomNavigationBar: Constants.footer,
        body: new FutureBuilder<Iterable<PlaylistSimple>>(
            future: _loadPlaylists,
            builder: (BuildContext context, AsyncSnapshot<Iterable<PlaylistSimple>> snapshot) {
              switch (snapshot.connectionState) {
                case ConnectionState.none:
                case ConnectionState.waiting:
                  return new Column(children: [
                    new Expanded(child: Constants.loading)
                  ], crossAxisAlignment: CrossAxisAlignment.stretch);
                default:
                  if (snapshot.connectionState == ConnectionState.done) {
                    _loading = false;
                  }
                  return new Column(children: [
                    new Expanded(child: new ListView(
                        children: app.playlists.map((playlist) {
                          return new ListTile(
                            leading: new Image.network(
                              playlistLargestImageUrl(playlist)
                            ),
                            title: new Text(playlist.name),
                            subtitle: new Text(playlistSubtitle(playlist)),
                          );
                        }).toList()
                    ))
                  ]);
              }
            }
        ),
    );
  }

  String playlistLargestImageUrl(PlaylistSimple playlist) {
    var oldWidth = playlist.images.first.width;
    return playlist.images.reduce((prevImg, img) {
      if (img.width > oldWidth && img.width < 1000) {
        oldWidth = img.width;
        return img;
      } else {
        return prevImg;
      }
    }).url;
  }

  String playlistSubtitle(PlaylistSimple playlist) {
    int total = playlist.tracksLink.total;
    String suffix = total == 1 ? 'song' : 'songs';
    return '$total $suffix';
  }
}
