class LinebotController < ApplicationController
  # linebot/callbackのCSRFトークン認証を無効
  protect_from_forgery :except => [:callback]
  # callbackアクションでシグニチャ検証を行う
  before_action :is_validate_signature, only: :callback
  
  # linebotのwebhook
  def callback
    body = request.body.read

    # メッセージをパース
    response, text = nil # 画面出力用
    events = line_client.client.parse_events_from(body)
    events.each { |event|
      case event
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text
          response, text = reply_text(event['replyToken'], event.message['text'])
        end
      end
    }
    render json: { response: response.to_s, text: text }
  end

  def new_push
    render
  end

  def push
    push_id, text = params[:push_id], params[:text]
    status = line_client.push_text(push_id, text)
    redirect_to :new_push, flash: { status_code: status.code }
  end

  # private
  # def push(push_id, text)
  #   line_client.push_text(push_id, text)
  #   redirect_to :new_push
  # end

  private
  def reply_text(replyToken, event_text)
    text = text_match_respond?(event_text)
    text = text_match_hear?(event_text) if text == nil
    text = text_match_hear_random?(event_text) if text == nil
    text = text_match_all?(event_text) if text == nil
    response = line_client.reply_text(replyToken, text) if text != nil
    return response, text
  end

  private 
  def text_match_respond?(text)
    return nil if text !~ Regexp.new(Settings.mention) # マッチしない場合true
    Settings.respond.each{ |res|
      return res.msg unless text !~ Regexp.new(res.key) # マッチした場合false
    }
    return nil
  end

  private 
  def text_match_hear?(text)
    Settings.hear.each{ |res|
      return res.msg unless text !~ Regexp.new(res.key) # マッチした場合false
    }
    return nil
  end

  private 
  def text_match_hear_random?(text)
    Settings.hear_random.each{ |res|
      return res.msg.sample.text unless text !~ Regexp.new(res.key) # マッチした場合false
    }
    return nil
  end

  private 
  def text_match_all?(text)
    return Settings.all.msg.empty? ? nil : Settings.all.msg.sample.text
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
      unless line_client.client.validate_signature(request.body, signature)
        render json: { status: 400, error: :'Bad Request' }, status: 400
      end
    end
  end
end