# frozen_string_literal: true

class Heap
  def initialize(app)
    @app = app
  end

  def call(env)
    heap_data = {}
    env["HTTP_COOKIE"].split("; ").each do |cookie|
      if cookie.starts_with? "_hp2_"
        key, value = cookie.split "="
        cookie_type, env_id = key.split "."
        if not heap_data[env_id]
          heap_data[env_id] = {}
        end
        heap_data[env_id][cookie_type] = JSON.parse(CGI.unescape(value))
      end
    end
    # Rails.logger.debug "request for #{path} with heap data #{heap_data}"
    heap_data.each do |env_id, cookies|
      id_cookie = cookies["_hp2_id"]
      if not id_cookie
        next
      end
      user_id = id_cookie["userId"]
      session_id = id_cookie["sessionId"]
      pageview_id = id_cookie["pageviewId"]
      ses_props = cookies["_hp2_ses_props"]
      props = cookies["_hp2_props"] || {}
      props["path"] = env["REQUEST_URI"]

      track env_id, user_id, session_id, pageview_id, ses_props || {}, "http_request", props
    end

    @status, @headers, @response = @app.call(env)

    [@status, @headers, @response]
  end

  def track(env_id, user_id, session_id, pageview_id, ses_props, type, properties)
    uri = URI("http://localhost:3000/api/track/8253958574")
    body = {
      "app_id": env_id,
      "user_id": user_id,
      "session_id": session_id,
      "pageview_id": pageview_id,
      "ses_props": ses_props,
      "event" => type,
      "properties" => properties
    }.to_json
    Rails.logger.debug(body)
    res = Net::HTTP.post uri, body, "Content-Type" => "application/json"
    Rails.logger.debug(res)
  end

  # private
end
