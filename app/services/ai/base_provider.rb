module AI
  class BaseProvider
    def analyze_containers(html_structure)
      raise NotImplementedError, "Subclasses must implement analyze_containers"
    end

    def extract_feed_items(html_structure, url)
      raise NotImplementedError, "Subclasses must implement extract_feed_items"
    end

    private

    def make_request(payload)
      raise NotImplementedError, "Subclasses must implement make_request"
    end
  end
end
