require "test_helper"

class Api::V1::FeedsControllerTest < ActionDispatch::IntegrationTest
  test "should return error when url parameter is missing" do
    post api_v1_feeds_analyze_path

    assert_response :bad_request
    assert_equal "URL parameter is required", JSON.parse(response.body)["error"]
  end

  test "should analyze feed url successfully" do
    mock_result = {
      url: "https://example.com",
      primary_container: {
        selector: "#main-content",
        confidence_score: 85.5,
        tag_name: "main",
        class_names: [ "content-area" ],
        id: "main-content"
      },
      analyzed_at: Time.current.iso8601
    }

    FeedAnalyzer.any_instance.expects(:analyze).returns(mock_result)

    post api_v1_feeds_analyze_path, params: { url: "https://example.com" }

    assert_response :success
    response_data = JSON.parse(response.body)
    assert_equal "https://example.com", response_data["url"]
    assert_equal "#main-content", response_data["primary_container"]["selector"]
    assert_equal "main", response_data["primary_container"]["tag_name"]
    assert_includes response_data["primary_container"]["class_names"], "content-area"
  end
end
