module AI
  class Factory
    def self.create_provider(provider_name = nil)
      provider_name ||= ENV["AI_PROVIDER"] || "openrouter"

      case provider_name.downcase
      when "openrouter"
        OpenrouterProvider.new
      else
        raise "Unknown AI provider: #{provider_name}"
      end
    end
  end
end
