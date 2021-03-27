# subsound

A subsonic music player.

## Screenshots

![Screenshot](screenshots/screenshot_161625497.png)

![Screenshot](screenshots/albumview.png)

![Screenshot](screenshots/artistview.png)

## Goals

- [X] Browsing content
- [X] Audio playback
- [X] Starred songs
- [X] Media players support (lock screens)
  - [X] Android
  - [X] ios
- [ ] A nice, smooth interface
- [ ] Make play queue actually work in all contexts
  - [X] Play a song in album with queue
  - [ ] Play a song from starred with queue
- [ ] Offline support
  - [ ] Sync content for local access in database
  - [ ] Selective caching

Possible goals:
 - Chromecast
 - Airplay
 - Support other servers than Subsonic compatible APIs
 - Linux
 - Transcoding when needed
 
Non-goals:
 - Video support
 - EQ/Gain

## TODO:
 - [X] Playback support
 - [X] Media players support (lock screens) for Android
 - [X] Media players support (lock screens) for ios
 - [ ] Queue support
 - [X] cache artwork
 - [X] download files
 - [\] cache files
   - [X] partial, should cache files now, but the user has no control over this
 - [ ] link from album back to artist
 - [ ] Album page: Star button in song list
 - [ ] Album page: summary in bottom of song list
 - [ ] Album page: play button
 - [X] Album page: play on click
 - [ ] Album page: Slide to enqueue
 - [ ] Artist page: play button
 - [ ] Setup sqlite database + migrations
    - [ ] Store artist index in sqlite db for offline use
 - [ ] Make it work offline
    - [ ] Download starred
    - [ ] store artwork persistent locally
    - [ ] store files persistent locally
    - [ ] store metadata persistent locally in database (as part of a full metadata sync?)

## Eventually
 - [ ] Album page: save button
 - [ ] Artist page: save button
