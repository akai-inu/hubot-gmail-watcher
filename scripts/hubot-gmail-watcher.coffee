# Description:
#   Notify new mail on Gmail with XOAuth2 connection in realtime
#
# Dependencies:
#   "inbox": "^1.1.59"
#   "iconv": "^2.1.11"
#   "mailparser": "^0.5.3"
#
# Configuration:
#   GMAIL_USER          - gmail address
#   GMAIL_CLIENT_ID     - google api client id
#   GMAIL_CLIENT_SECRET - google api client secret
#   GMAIL_REFRESH_TOKEN - gmail api refresh token
#   GMAIL_ACCESS_TOKEN  - gmail api access token
#
# Commands:
#   hubot gmail start - Start to fetch new mail
#   hubot gmail stop  - Stop fetching new mail
#
# Author:
#   akai-inu <akai_inu@live.jp>
#
# Notes:
#
# See Also:
#   http://eiua-memo.tumblr.com/post/121580360233/nodejsnodemailer
#   https://github.com/udzura/hubot-gmail-fetcher/blob/master/scripts/gmail-fetcher.coffee
#   http://txclr.hatenablog.com/entry/2015/02/16/160025

inbox = require 'inbox'
{MailParser} = require 'mailparser'
imapData =
  port: false # use default
  endpoint: 'imap.gmail.com'
  options:
    secureConnection: true
    auth:
      XOAuth2:
        user: process.env.GMAIL_USER
        clientId: process.env.GMAIL_CLIENT_ID
        clientSecret: process.env.GMAIL_CLIENT_SECRET
        refreshToken: process.env.GMAIL_REFRESH_TOKEN
        accessToken: process.env.GMAIL_ACCESS_TOKEN
inboxLabel = 'INBOX'

module.exports = (robot) ->

  # register responses
  (->
    inboxClient = null
    robot.respond /gmail (re)?start/i, (res) ->
      inboxClient.close() if inboxClient
      inboxClient = establishConnection res

    robot.respond /gmail stop/i, (res) ->
      inboxClient.close() if inboxClient
  )()

  ###
  # Establish connection to gmail with XOAuth2
  #
  # @return inbox instance
  ###
  establishConnection = (res = null) ->
    robot.logger.info 'Initialize Gmail IMAP client'
    _client = inbox.createConnection imapData.port, imapData.endpoint, imapData.options

    _client.on 'error', (err) ->
      robot.logger.error 'Gmail watcher error : ' + err
      res.reply 'Gmail watcher error : ' + err if res
    _client.on 'close', ->
      robot.logger.info 'Gmail watcher IMAP client closed'
      res.reply 'Gmail watcher stopped.' if res
    _client.on 'connect', ->
      robot.logger.info 'Gmail watcher IMAP client connected'
      res.reply 'Gmail watcher started.' if res

      # open mailbox to fetch new mail
      _client.openMailbox inboxLabel, (err, info) ->
        throw err if err
    _client.on 'new', onNewMail(res, _client)
    _client.connect()

    return _client

  ###
  # Process on new mail
  #
  # @param res    hubot response
  # @param client inbox client
  # @return function (message)
  ###
  onNewMail = (res, client) ->
    return (message) ->
      robot.logger.info "Gmail watcher accepted new mail : uid=#{message.UID} title=#{message.title}"
      stream = client.createMessageStream message.UID
      mailParser = new MailParser()
      mailParser.on 'end', sendMail(res)
      stream.pipe mailParser

  ###
  # Send mail data to adapter
  #
  # @param res hubot response
  # @return function (mail)
  ###
  sendMail = (res) ->
    return (mail) ->
      switch res.robot.adapterName
        when 'slack' then sendMailWithAttachments res, mail
        else sendMailWithPlainText res, mail

  ###
  # Send mail data with slack attachments
  #
  # @param res  hubot response
  # @param mail parsed mail object
  # @see https://api.slack.com/docs/attachments
  # @see https://github.com/slackhq/hubot-slack/blob/master/src/slack.coffee#L274
  ###
  sendMailWithAttachments = (res, mail) ->
    mailSender = mail.from.pop()
    color = if mail.priority is 'high' then 'danger' else 'good'
    data =
      message: res
      username: 'Gmail'
      icon_url: 'http://www.google.com/images/icons/product/googlemail-64.png'
      text: ''
      attachments: [
        {
          fallback: "#{mail.subject} from: #{mailSender.name} <#{mailSender.address}>"
          color: color
          pretext: ''
          title: mail.subject
          text: mail.text
          fields: [
            {
              title: 'Sent by'
              value: "#{mailSender.name} <#{mailSender.address}>"
              short: true
            }
            {
              title: 'Date'
              value: mail.date.toLocaleString()
              short: true
            }
          ]
        }
      ]

    res.robot.emit 'slack-attachment', data

  ###
  # Send mail data with plain text
  #
  # @param res  hubot response
  # @param mail parsed mail object
  ###
  sendMailWithPlainText = (res, mail) ->
    str = [
      "#{mail.subject} from: #{mail.from[0].name} <#{mail.from[0].address}>"
      ""
      "#{mail.text}"
    ].join '\n'

    res.send str
