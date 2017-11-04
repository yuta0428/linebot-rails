  # line-bot-sdkを参照
require 'line/bot'

class LineClient

  # clientへのgetter定義
  attr_reader :client

  def initialize
    # 左辺が未定義なら代入
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV['LINE_CHANNEL_SECRET']
      config.channel_token = ENV['LINE_CHANNEL_TOKEN']
    }
  end

  def reply_text(reply_token, text)
      reply(reply_token, text_message(text))
  end

  def push_text(push_id, text)
      push(push_id, text_message(text))
  end

  private
  def reply(reply_token, message)
      client.reply_message(reply_token, message)
  end

  private
  def push(push_id, message)
      client.reply_message(reply_token, message)
  end

  private
  def text_message(text) 
    { "type" => "text", "text" => text, } 
  end
end