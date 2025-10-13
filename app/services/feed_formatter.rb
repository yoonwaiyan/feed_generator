class FeedFormatter
  def self.to_json(url, items, feed_title = nil, feed_description = nil)
    {
      feed: {
        title: feed_title || url,
        description: feed_description || "Feed generated from #{url}",
        url: url
      },
      items: items.map do |item|
        {
          title: item[:title],
          link: item[:link],
          published_at: item[:published_at]&.iso8601
        }.compact
      end
    }
  end

  def self.to_rss(url, items, feed_title = nil, feed_description = nil)
    require "builder"

    xml = Builder::XmlMarkup.new(indent: 2)
    xml.instruct! :xml, version: "1.0", encoding: "UTF-8"

    xml.rss version: "2.0" do
      xml.channel do
        xml.title feed_title || url
        xml.description feed_description || "Feed generated from #{url}"
        xml.link url
        xml.lastBuildDate Time.current.rfc2822

        items.each do |item|
          xml.item do
            xml.title item[:title]
            xml.link item[:link] if item[:link]
            xml.pubDate item[:published_at].rfc2822 if item[:published_at]
          end
        end
      end
    end
  end

  def self.to_html(url, items, feed_title = nil, feed_description = nil)
    title = feed_title || url
    html = <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <title>#{title}</title>
        <style>
          body { font-family: Arial, sans-serif; margin: 40px; }
          .item { margin-bottom: 30px; padding: 20px; border: 1px solid #ddd; }
          .title { font-size: 18px; font-weight: bold; margin-bottom: 10px; }
          .description { margin-bottom: 10px; }
          .meta { color: #666; font-size: 14px; }
        </style>
      </head>
      <body>
        <h1>#{title}</h1>
        #{feed_description ? "<p>#{feed_description}</p>" : ""}
    HTML

    items.each do |item|
      html += <<~HTML
        <div class="item">
          <div class="title">#{item[:title]}</div>
          <div class="meta">
            #{item[:link] ? "<a href='#{item[:link]}'>Read more</a>" : ""}
            #{item[:published_at] ? " | Published: #{item[:published_at].strftime('%B %d, %Y')}" : ""}
          </div>
        </div>
      HTML
    end

    html += "</body></html>"
    html
  end
end
