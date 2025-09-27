require "net/http"
require "json"

module AI
  class OpenrouterProvider < BaseProvider
    API_URL = "https://openrouter.ai/api/v1/chat/completions"
    TIMEOUT = 30

    def initialize
      @api_key = ENV["OPENROUTER_API_KEY"]
      raise "OPENROUTER_API_KEY environment variable is required" if @api_key.blank?
    end

    def analyze_containers(html_structure)
      prompt = build_prompt(html_structure)
      response = make_request(prompt)
      parse_response(response)
    end

    private

    def build_prompt(html_structure)
      <<~PROMPT
        Analyze the following HTML structure and identify the best container for main content extraction.
        Return a JSON response with the selector and confidence score (0-100).

        HTML Structure:
        #{html_structure}

        Response format:
        {
          "selector": "CSS selector for the best container",
          "confidence_score": 85,
          "reasoning": "Brief explanation of why this container was chosen"
        }
      PROMPT
    end

    def make_request(prompt)
      uri = URI(API_URL)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = TIMEOUT
      http.read_timeout = TIMEOUT

      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "Bearer #{@api_key}"
      request["Content-Type"] = "application/json"

      request.body = {
        model: "anthropic/claude-3.5-sonnet",
        messages: [
          {
            role: "user",
            content: prompt
          }
        ],
        max_tokens: 500,
        temperature: 0.1
      }.to_json

      response = http.request(request)
      JSON.parse(response.body)
    rescue StandardError
      {}
    end

    def parse_response(response)
      content = response.dig("choices", 0, "message", "content")
      return fallback_response unless content

      # Extract JSON from response
      json_match = content.match(/\{.*\}/m)
      return fallback_response unless json_match

      JSON.parse(json_match[0])
    rescue JSON::ParserError
      fallback_response
    end

    def fallback_response
      {
        "selector" => "main",
        "confidence_score" => 50,
        "reasoning" => "AI analysis failed, using fallback"
      }
    end
  end
end
