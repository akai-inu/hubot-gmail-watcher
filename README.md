[![npm version](https://badge.fury.io/js/hubot-gmail-watcher.svg)](https://badge.fury.io/js/hubot-gmail-watcher)

Hubot gmail watcher
=======================

Watches your new mail to gmail and send by hubot.

Install
-----------------------

1. `$ npm install --save hubot-gmail-watcher`
1. add `hubot-gmail-watcher` to `external-scripts.json`
1. send `gmail start` to your hubot

Environment variables
-----------------------

- GMAIL_USER          - gmail address
- GMAIL_CLIENT_ID     - google api client id
- GMAIL_CLIENT_SECRET - google api client secret
- GMAIL_REFRESH_TOKEN - gmail api refresh token
- GMAIL_ACCESS_TOKEN  - gmail api access token

TODO
-----------------------

- Environment variables faq
- Get refresh/access tokens automatically
- Add label support
    - label color
- Adapter support
    - ChatWork
    - HipChat
    - IRC
    - SkypeWeb

Contribution
-----------------------

Usual github way
