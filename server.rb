require "webrick"
require "json"
require "net/smtp"

ROOT = __dir__
CONFIG_PATH = File.join(ROOT, "mail_config.json")
EMAIL = /\A[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\z/

class ApplyServlet < WEBrick::HTTPServlet::AbstractServlet
  def do_POST(req, res)
    data = JSON.parse(req.body.to_s)
    name = clean(data["name"], 80)
    email = clean(data["email"], 120)
    course = clean(data["course"], 120)

    unless name && email =~ EMAIL && course
      return json(res, 400, ok: false, error: "Enter a name, a valid email, and a course.")
    end

    config = load_config
    unless config
      return json(res, 503, ok: false, error: "Email is not set up yet. Add mail_config.json with the sender account.")
    end

    send_confirmation(config, name, email, course)
    json(res, 200, ok: true)
  rescue StandardError => e
    json(res, 500, ok: false, error: "The email could not be sent. #{e.message}")
  end

  def clean(value, max)
    text = value.to_s.gsub(/[\r\n]/, " ").strip
    return nil if text.empty? || text.length > max
    text
  end

  def load_config
    return nil unless File.file?(CONFIG_PATH)
    config = JSON.parse(File.read(CONFIG_PATH))
    return nil if config["user"].to_s.empty? || config["password"].to_s.empty?
    config
  end

  def send_confirmation(config, name, email, course)
    from = config["from"].to_s.empty? ? config["user"] : config["from"]
    body = <<~TEXT
      Hello #{name},

      Your application for #{course} at Ghana Communication Technology University has been received.
      This email is your confirmation. Keep it for your records.

      Admissions office
      Ghana Communication Technology University
    TEXT
    message = <<~MAIL
      From: Ghana Communication Technology University <#{from}>
      To: #{email}
      Subject: Your application has been received
      MIME-Version: 1.0
      Content-Type: text/plain; charset=UTF-8

      #{body}
    MAIL

    smtp = Net::SMTP.new(config.fetch("address", "smtp.gmail.com"), config.fetch("port", 587).to_i)
    smtp.enable_starttls_auto
    smtp.start("localhost", config["user"], config["password"], :login) do |connection|
      connection.send_message(message, from, email)
    end
  end

  def json(res, status, payload)
    res.status = status
    res["Content-Type"] = "application/json"
    res.body = JSON.generate(payload)
  end
end

server = WEBrick::HTTPServer.new(
  Port: 8765,
  BindAddress: "127.0.0.1",
  DocumentRoot: ROOT
)
server.mount "/apply", ApplyServlet
trap("INT") { server.shutdown }
server.start
