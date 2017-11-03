class LinebotController < ApplicationController
  # line-bot-sdkを参照
  require 'line/bot'
  # linebot/callbackのCSRFトークン認証を無効
  protect_from_forgery :except => [:callback]

  # linebotのwebhook
  def callback
    body = request.body.read

    # シグニチャが正しくなければエラー
    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      error 400 do 'Bad Request' end
    end

    # メッセージをパース
    events = client.parse_events_from(body)

    # ログに保存
    Rails.application.config.another_logger.info(events)

    events.each { |event|
      case event
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text
          message = {
            type: 'text',
            text: event.message['text']
          }
          response = client.reply_message(event['replyToken'], message)
          p response
        end
      end
    }
    head :ok
  end

  private
  def client
    # 左辺が未定義なら代入
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
  end
end