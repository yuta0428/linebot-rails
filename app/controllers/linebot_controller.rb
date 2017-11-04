class LinebotController < ApplicationController
  # linebot/callbackのCSRFトークン認証を無効
  protect_from_forgery :except => [:callback]
  # callbackアクションでシグニチャ検証を行う
  before_action :is_validate_signature, only: :callback
  
  # linebotのwebhook
  def callback
    body = request.body.read

    # メッセージをパース
    events = line_client.client.parse_events_from(body)
    events.each { |event|
      case event
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text
          response = reply_text(event['replyToken'], event.message['text'])
          p response
        end
      end
    }
    head :ok
  end

  private
  def reply_text(replyToken, event_text)
      text = event_text
      line_client.reply_text(replyToken, text)
  end

  private
  # lib/line_clinet
  def line_client
    @line_client ||= LineClient.new
  end
  
  private
  # シグニチャ検証
  def is_validate_signature
    unless Rails.env.development?
      signature = request.env[:'HTTP_X_LINE_SIGNATURE']
      unless line_client.validate_signature(request.body, signature)
        render json: { status: 400, error: :'Bad Request' }, status: 400
      end
    end
  end
end