require "test_helper"

class AI::OpenrouterProviderTest < ActiveSupport::TestCase
  def setup
    @provider = AI::OpenrouterProvider.new
  end

  test "should analyze containers with AI" do
    mock_response = {
      "choices" => [ {
        "message" => {
          "content" => '{"selector": "#main-content", "confidence_score": 90, "reasoning": "Main content container"}'
        }
      } ]
    }

    Net::HTTP.any_instance.expects(:request).returns(
      stub(body: mock_response.to_json)
    )

    result = @provider.analyze_containers('<div id="main-content">Content</div>')

    assert_equal "#main-content", result["selector"]
    assert_equal 90, result["confidence_score"]
  end

  test "should return fallback response on API failure" do
    Net::HTTP.any_instance.expects(:request).raises(StandardError)

    result = @provider.analyze_containers("<div>Content</div>")

    assert_equal "main", result["selector"]
    assert_equal 50, result["confidence_score"]
  end
end
