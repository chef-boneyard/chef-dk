require "openssl"
require "net/https"
require "json"
require "pp"
require "uri"

THIS_DIR = File.expand_path(File.dirname(__FILE__))

UNIVERSE_JSON_PATH = File.join(THIS_DIR, "universe.json")
SMALL_UNIVERSE_JSON_PATH = File.join(THIS_DIR, "small_universe.json")
PRUNED_UNIVERSE_PATH = File.join(THIS_DIR, "pruned_small_universe.json")

COOKBOOKS_IN_SMALL_UNIVERSE = %w{apache2 application apt database mysql nginx postgresql yum}.freeze

universe = URI("https://supermarket.chef.io/universe")

universe_serialized = Net::HTTP.get(universe)

universe = JSON.parse(universe_serialized)

smaller_universe = universe.keep_if { |k, v| COOKBOOKS_IN_SMALL_UNIVERSE.include?(k) }

pruned_universe = smaller_universe.inject({}) do |pruned_graph, (cookbook_name, graph_info)|
  pruned_graph[cookbook_name] = graph_info.inject({}) do |per_version_graph, (version_number, version_info)|
    per_version_graph[version_number] = version_info["dependencies"]
    per_version_graph
  end
  pruned_graph
end

File.open(UNIVERSE_JSON_PATH, "w+") { |f| f.print(universe_serialized) }
File.open(SMALL_UNIVERSE_JSON_PATH, "w+") { |f| f.print(JSON.pretty_generate(smaller_universe)) }
File.open(PRUNED_UNIVERSE_PATH, "w+") { |f| f.print(JSON.pretty_generate(pruned_universe)) }
