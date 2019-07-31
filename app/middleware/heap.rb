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
        heap_data[env_id] = {
          cookie_type => JSON.parse(CGI.unescape(value))
        }
      end
    end
    # Rails.logger.debug "request for #{path} with heap data #{heap_data}"
    heap_data.each do |env_id, cookies|
      id_cookie = cookies["_hp2_id"]
      if not id_cookie
        break
      end
      user_id = id_cookie["user_id"]
      ses_props = cookies["_hp2_ses_props"]
      if ses_props
        session_id = cookies["_hp2_ses_props"]["session_id"]
      else
        session_id = nil
      end
      props = cookies["_hp2_props"] || {}
      props["path"] = env["REQUEST_URI"]

      track env_id, user_id, session_id, ses_props, "http_request", props
    end

    # request_started_on = Time.now
    @status, @headers, @response = @app.call(env)
    # request_ended_on = Time.now

    # Rails.logger.debug "=" * 50
    # Rails.logger.debug "Request delta time: #{request_ended_on - request_started_on} seconds."
    # Rails.logger.debug "=" * 50
    # byebug

    [@status, @headers, @response]
  end

  def track(env_id, user_id, session_id, ses_props, type, props)
    uri = URI("http://localhost:3000/api/track/8253958574")
    http = Net::HTTP.new(uri.host, uri.port)
    req = Net::HTTP::Post.new(uri.path, "Content-Type" => "application/json")
    req.body = {
      "app_id": env_id,
      "user_id": user_id,
      "session_id": session_id,
      "ses_props": ses_props,
      "event" => type,
      "props" => props
    }.to_json
    Rails.logger.debug(req)
    Rails.logger.debug(req.body)
    res = http.request(req)
    Rails.logger.debug(res)
  end

  # private
end
