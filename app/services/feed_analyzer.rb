require "mechanize"

class FeedAnalyzer
  TIMEOUT = 10
  MAX_SIZE = 5.megabytes

  def initialize(url)
    @url = url
  end

  def analyze
    page = fetch_page
    doc = page.parser

    ai_result = analyze_with_ai(doc)
    element = find_element_by_selector(doc, ai_result["selector"])

    raise "Could not find element with selector: #{ai_result['selector']}" unless element

    {
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

  private

  def fetch_page
    agent = Mechanize.new
    agent.user_agent = "FeedGenerator/1.0"
    agent.open_timeout = TIMEOUT
    agent.read_timeout = TIMEOUT

    page = agent.get(@url)

    if page.body.bytesize > MAX_SIZE
      raise "Content too large (#{page.body.bytesize} bytes)"
    end

    page
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

  def analyze_with_ai(doc)
    simplified_html = simplify_html_structure(doc)
    ai_provider = AI::Factory.create_provider
    ai_provider.analyze_containers(simplified_html)
  end

  def simplify_html_structure(doc)
    elements = doc.search('main, article, section, div[class*="content"], div[id*="content"]')

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
    doc.search(selector).first
  rescue
    nil
  end
end
