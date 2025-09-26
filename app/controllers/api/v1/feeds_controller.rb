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
end
