class Api::V1::FeedsController < ApplicationController
  def analyze
    url = params[:url]

    if url.blank?
      render json: { error: "URL parameter is required" }, status: :bad_request
      return
    end

    begin
      analyzer = FeedAnalyzer.new(url)
      result = analyzer.analyze

      render json: result
    rescue StandardError => e
      render json: { error: e.message }, status: :internal_server_error
    end
  end

  def items
    format = params[:format] || "json"
    url = params[:url]
    selector = params[:selector]

    unless %w[rss json html].include?(format)
      render json: { error: "Invalid format. Must be 'rss', 'json', or 'html'" }, status: :bad_request
      return
    end

    if url.blank?
      render json: { error: "url parameter is required" }, status: :bad_request
      return
    end

    begin
      result = FeedItemsService.new(url, selector).generate_items

      case format
      when "rss"
        render xml: FeedFormatter.to_rss(url, result[:items], result[:feed_title], result[:feed_description]), content_type: "application/rss+xml"
      when "html"
        render html: FeedFormatter.to_html(url, result[:items], result[:feed_title], result[:feed_description]), content_type: "text/html"
      else
        render json: FeedFormatter.to_json(url, result[:items], result[:feed_title], result[:feed_description])
      end
    rescue StandardError => e
      render json: { error: e.message }, status: :internal_server_error
    end
  end
end
