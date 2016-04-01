require 'shellwords'

module BundleUtil
  PLATFORMS = { "windows" => %w{ruby x86-mingw32} }

  def project_root
    File.expand_path("../..", __FILE__)
  end

  def bundle_platform
    File.join(project_root, "bin", "bundle-platform")
  end

  # Parse the output of "bundle outdated" and get the list of gems that
  # were outdated
  def parse_bundle_outdated(bundle_outdated_output)
    result = []
    bundle_outdated_output.each_line do |line|
      if line =~ /^\s*\* (.+) \(newest ([^,]+), installed ([^,)])*/
        gem_name, newest_version, installed_version = $1, $2, $3
        result << [ line, gem_name ]
      end
    end
    result
  end

  # Run bundle-platform with the given ruby platform(s)
  def bundle(args, platform: nil, cwd: nil, extract_output: false)
    args = args.split(/\s+/)
    # Set the env var that lets Gemfile know it's
    puts ""
    if cwd
      prefix = "[#{cwd}] "
    end
    cwd = File.expand_path(cwd || ".", project_root)
    Dir.chdir(cwd) do
      raise "No platform #{platform} (supported: #{PLATFORMS.keys.join(", ")})" if platform && !PLATFORMS[platform]
      ruby_platforms = platform ? PLATFORMS[platform].join(" ") : "ruby"
      cmd = Shellwords.join([bundle_platform, ruby_platforms, *args])
      puts "#{prefix}#{Shellwords.join(["bundle", *args])}#{platform ? " for #{platform} platform" : ""}:"
      puts "#{prefix}> #{cmd}"
      if extract_output
        `#{cmd}`
      else
        sh bundle_platform, ruby_platforms, *args
      end
    end
  end

  def platforms
    PLATFORMS.keys
  end
end
