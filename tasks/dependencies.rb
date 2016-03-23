class OverrideReader
  def overrides
    @overrides ||= {}
  end
  def override(name, **options)
    overrides[name] = options
  end
end

task :dependencies do
  # Read the chefdk overrides file to get the list of gems and other things besides version (like source info)
  overrides_file = File.expand_path("../../omnibus/config/chefdk_overrides.rb", __FILE__)
  puts "Reading #{overrides_file} ..."
  reader = OverrideReader.new
  reader.instance_eval(IO.read(overrides_file), overrides_file, 1)

  # Grab all matching specs
  found_gems = {}
  sources = Gem::SourceList.from [ "https://rubygems.org" ]
  sources.each_source { |s| s.load_specs(:latest) }
  specs = Gem::SpecFetcher.new(sources).detect(:latest) do |tuple|
    name = tuple.name.to_sym
    name = :'rubygems' if name == :'rubygems-update'
    reader.overrides.has_key?(name) && tuple.platform === 'ruby'
  end
  specs.each do |tuple, source|
    name = tuple.name.to_sym
    name = :'rubygems' if name == :'rubygems-update'
    # :latest will give you different versions depending on arch. Pick latest latest.
    if !found_gems[name] || tuple.version >= found_gems[name]
      found_gems[name] = tuple.version
    end
  end

  # Figure out the final override version for each override
  new_overrides = {}
  reader.overrides.each do |name, version: nil, **options|
    new_version = found_gems[name].to_s
    raise "Could not find #{gem_name} in rubygems!" unless new_version
    new_version = "v#{new_version}" if version.start_with?("v")
    if version == new_version
      puts "#{name}: #{new_version}"
    else
      puts "#{name}: #{new_version} (was #{version})"
    end
    new_overrides[name] = { version: new_version, **options }
  end

  # Write the file back out
  puts "Writing changes out to #{overrides_file} ..."
  output = File.open(overrides_file, 'w')
  new_overrides.each do |name, **options|
    line = "override #{name.inspect}"
    options.each do |key, value|
      line << ", #{key.inspect} => #{value.inspect}"
    end
    output.puts line
  end
  output.close
end
