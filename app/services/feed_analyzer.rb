require "net/http"
require "nokogiri"

class FeedAnalyzer
  TIMEOUT = 10
  MAX_SIZE = 5.megabytes

  def initialize(url)
    @url = url
  end

  def analyze
    html = fetch_html
    doc = Nokogiri::HTML(html)

    # Use AI analysis if available, fallback to heuristic scoring
    if use_ai_analysis?
      ai_result = analyze_with_ai(doc)
      element = find_element_by_selector(doc, ai_result["selector"])

      if element
        return {
          url: @url,
          primary_container: {
            selector: ai_result["selector"],
            confidence_score: ai_result["confidence_score"],
            tag_name: element.name,
            class_names: element["class"]&.split(" ") || [],
            id: element["id"],
            ai_reasoning: ai_result["reasoning"]
          },
          analyzed_at: Time.current.iso8601,
          analysis_method: "ai"
        }
      end
    end

    # Fallback to heuristic analysis
    containers = find_content_containers(doc)
    scored_containers = score_containers(containers)
    best_container = scored_containers.max_by { |c| c[:score] }

    {
      url: @url,
      primary_container: {
        selector: generate_selector(best_container[:element]),
        confidence_score: best_container[:score],
        tag_name: best_container[:element].name,
        class_names: best_container[:element]["class"]&.split(" ") || [],
        id: best_container[:element]["id"]
      },
      analyzed_at: Time.current.iso8601,
      analysis_method: "heuristic"
    }
  end

  private

  def fetch_html
    uri = URI(@url)

    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https",
                    open_timeout: TIMEOUT, read_timeout: TIMEOUT) do |http|
      request = Net::HTTP::Get.new(uri)
      request["User-Agent"] = "FeedGenerator/1.0"

      response = http.request(request)

      if response.body.bytesize > MAX_SIZE
        raise "Content too large (#{response.body.bytesize} bytes)"
      end

      response.body
    end
  end

  def find_content_containers(doc)
    doc.css("div, article, section, main, aside").select do |element|
      element.text.strip.length > 50
    end
  end

  def score_containers(containers)
    containers.map do |container|
      {
        element: container,
        score: calculate_score(container)
      }
    end
  end

  def calculate_score(element)
    score = 0

    # Text content density
    text_length = element.text.strip.length
    html_length = element.to_html.length
    text_ratio = text_length.to_f / html_length
    score += text_ratio * 40

    # Semantic tags bonus
    score += 20 if %w[article main].include?(element.name)
    score += 10 if %w[section].include?(element.name)

    # Class/ID hints
    content_indicators = %w[content main article post entry body text]
    class_names = (element["class"] || "").downcase
    id_name = (element["id"] || "").downcase

    content_indicators.each do |indicator|
      score += 15 if class_names.include?(indicator)
      score += 20 if id_name.include?(indicator)
    end

    # Position bonus (elements higher up get slight bonus)
    position_score = [ 0, 100 - element.ancestors.length ].max
    score += position_score * 0.1

    score
  end

  def generate_selector(element)
    if element["id"].present?
      "##{element['id']}"
    elsif element["class"].present?
      ".#{element['class'].split(' ').first}"
    else
      element.name
    end
  end

  def use_ai_analysis?
    ENV["USE_AI_ANALYSIS"] == "true" && ENV["OPENROUTER_API_KEY"].present?
  end

  def analyze_with_ai(doc)
    # Simplify HTML structure for AI analysis
    simplified_html = simplify_html_structure(doc)
    ai_provider = AI::Factory.create_provider
    ai_provider.analyze_containers(simplified_html)
  end

  def simplify_html_structure(doc)
    # Extract key structural elements with their attributes
    elements = doc.css('main, article, section, div[class*="content"], div[id*="content"]')

    elements.map do |el|
      {
        tag: el.name,
        id: el["id"],
        class: el["class"],
        text_length: el.text.strip.length,
        selector: generate_selector(el)
      }
    end.to_json
  end

  def find_element_by_selector(doc, selector)
    doc.css(selector).first
  rescue
    nil
  end
end
