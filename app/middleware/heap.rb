# frozen_string_literal: true

class Heap
  def initialize(app)
    @app = app
  end

  def call(env)
    heap_context = {}
    env["HTTP_COOKIE"].split("; ").each do |cookie|
      if cookie.starts_with? "_hp2_"
        key, value = cookie.split "="
        cookie_type, env_id = key.split "."
        if not heap_context[env_id]
          heap_context[env_id] = {}
        end
        heap_context[env_id][cookie_type] = JSON.parse(CGI.unescape(value))
      end
    end


    # :KLUDGE: assuming 1:1 relation between thread and request lifecycle
    Thread.current[:heap_context] = heap_context

    Heap.track "http_request", "path" => env["REQUEST_URI"]

    @status, @headers, @response = @app.call(env)

    [@status, @headers, @response]
  end

  # TODO this public-facing function should not live in the middleware
  def self.track(type, custom_props)
    Thread.current[:heap_context].each do |env_id, cookies|
      id_cookie = cookies["_hp2_id"]
      if not id_cookie
        next
      end
      user_id = id_cookie["userId"]
      session_id = id_cookie["sessionId"]
      pageview_id = id_cookie["pageviewId"]
      ses_props = cookies["_hp2_ses_props"]
      event_props = cookies["_hp2_props"] || {}

      properties = event_props.merge custom_props

      Heap._track_once env_id, user_id, session_id, pageview_id, ses_props || {}, type, properties
    end
  end

  def self._track_once(env_id, user_id, session_id, pageview_id, ses_props, type, properties)
    uri = URI("http://heapanalytics.com/api/integrations/sessiontrack/8253958574")
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
end
