# subsound

A subsonic music player.

## Screenshots

![Screenshot](screenshots/albumview.png)

![Screenshot](screenshots/artistview.png)

## Goals

- [X] Browsing content
- [ ] A nice, smooth interface
- [ ] Audio playback
- [ ] Starred songs
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
 - [ ] Playback support
 - [X] cache artwork
 - [X] download files
 - [ ] cache files
 - [ ] Album page: Star button in song list
 - [ ] Album page: summary in bottom of song list
 - [ ] Album page: play button
 - [ ] Album page: Slide to enqueue
 - [ ] Artist page: play button
 - [ ] Setup sqlite database + migrations
    - [ ] Store artist index in sqlite db for offline use
 - [ ] Make it work offline
    - [ ] store artwork persistent locally
    - [ ] store files persistent locally
    - [ ] store metadata persistent locally in database (as part of a full metadata sync?)

## Eventually
 - [ ] Album page: save button
 - [ ] Artist page: save button