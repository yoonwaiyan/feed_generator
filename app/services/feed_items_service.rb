require "mechanize"

class FeedItemsService
  def initialize(url, selector = nil)
    @url = url
    @selector = selector
  end

  def generate_items
    page = fetch_page
    return { feed_title: nil, feed_description: nil, items: [] } unless page

    extract_with_ai(page)
  end

  private

  def fetch_page
    agent = Mechanize.new
    agent.user_agent = "FeedGenerator/1.0"
    agent.open_timeout = 10
    agent.read_timeout = 10
    agent.get(@url)
  rescue StandardError => e
    Rails.logger.error("[FeedItemsService] Failed to fetch #{@url}: #{e.message}")
    nil
  end

  def extract_with_ai(page)
    # Simplify HTML for AI processing
    simplified_html = simplify_html_for_ai(page)

    ai_provider = AI::Factory.create_provider
    result = ai_provider.extract_feed_items(simplified_html, @url)

    parse_ai_result(result)
  rescue StandardError => e
    Rails.logger.error("[FeedItemsService] AI extraction failed: #{e.message}")
    { feed_title: nil, feed_description: nil, items: [] }
  end

  def simplify_html_for_ai(page)
    # Extract relevant content containers
    containers = page.search(@selector || "article, .post, .entry, .thing, li")

    containers.first(20).map do |container|
      {
        html: container.to_html.truncate(1000),
        text: container.text.strip.truncate(500)
      }
    end.to_json
  end

  def parse_ai_result(result)
    return { feed_title: nil, feed_description: nil, items: [] } unless result.is_a?(Hash)

    items = (result["items"] || []).map do |item|
      {
        title: item["title"],
        link: absolute_url(item["link"]),
        published_at: parse_published_at(item["published_at"])
      }
    end.compact

    {
      feed_title: result["feed_title"],
      feed_description: result["feed_description"],
      items: items
    }
  end

  def parse_published_at(date_str)
    return nil if date_str.blank?
    Time.parse(date_str)
  rescue ArgumentError
    nil
  end

  def absolute_url(href)
    return nil if href.blank?
    return href if href.start_with?("http")

    uri = URI(@url)
    if href.start_with?("/")
      "#{uri.scheme}://#{uri.host}#{href}"
    else
      "#{uri.scheme}://#{uri.host}/#{href}"
    end
  end
end
