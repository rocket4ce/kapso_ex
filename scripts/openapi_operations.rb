# Regenerates test/support/openapi_operations.txt from Kapso's OpenAPI specs.
#
#     ruby scripts/openapi_operations.rb > test/support/openapi_operations.txt
#
# Then run `mix test test/kapso_ex/endpoints_test.exs` to see which documented
# operations are missing a function. Uses only the Ruby standard library.
require "net/http"
require "uri"
require "yaml"

SPECS = {
  "whatsapp" => "https://docs.kapso.ai/api/meta/whatsapp/openapi-whatsapp.yaml",
  "platform" => "https://docs.kapso.ai/api/platform/v1/openapi-platform.yaml",
  "workflows" => "https://docs.kapso.ai/api/platform/v1/openapi-workflows.yaml",
  "kapso-agent" => "https://docs.kapso.ai/api/platform/v1/openapi-kapso-agent.yaml"
}.freeze

puts "# Generated from Kapso's OpenAPI specs (https://docs.kapso.ai/llms.txt)."
puts "# One line per documented operation: <api> <METHOD> <path>."

SPECS.each do |name, url|
  spec = YAML.safe_load(Net::HTTP.get(URI(url)), aliases: true, permitted_classes: [Date, Time])
  api = name == "whatsapp" ? "whatsapp" : "platform"

  spec.fetch("paths").each do |path, item|
    item.each_key do |method|
      next unless %w[get post put patch delete].include?(method)

      puts "#{api} #{method.upcase} #{path}"
    end
  end
end
