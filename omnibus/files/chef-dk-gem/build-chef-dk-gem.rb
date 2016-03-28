require "shellwords"
require "pathname"
require "bundler"

# We use this to break up the `build` method into readable parts
module BuildChefDKGem
  def embedded_bin(binary)
    windows_safe_path("#{install_dir}/embedded/bin/#{binary}")
  end
  def appbundler_bin
    embedded_bin("appbundler")
  end
  def bundle_bin
    embedded_bin("bundle")
  end
  def gem_bin
    embedded_bin("gem")
  end
  def rake_bin
    embedded_bin("rake")
  end
  def env
    # A common env for building everything including nokogiri and dep-selector-libgecode
    env = with_standard_compiler_flags(with_embedded_path, bfd_flags: true)

    # From dep-selector-libgecode
    # On some RHEL-based systems, the default GCC that's installed is 4.1. We
    # need to use 4.4, which is provided by the gcc44 and gcc44-c++ packages.
    # These do not use the gcc binaries so we set the flags to point to the
    # correct version here.
    if File.exist?("/usr/bin/gcc44")
      env["CC"]  = "gcc44"
      env["CXX"] = "g++44"
    end

    # From dep-selector-libgecode
    # Ruby DevKit ships with BSD Tar
    env["PROG_TAR"] = "bsdtar" if windows?
    env["ARFLAGS"] = "rv #{env["ARFLAGS"]}" if env["ARFLAGS"]

    # Set up nokogiri environment and args
    env["NOKOGIRI_USE_SYSTEM_LIBRARIES"] = "true"
    env
  end
  def all_install_args
    @all_install_args = {
      "nokogiri" => [
        "--use-system-libraries",
        "--with-xml2-lib=#{Shellwords.escape("#{install_dir}/embedded/lib")}",
        "--with-xml2-include=#{Shellwords.escape("#{install_dir}/embedded/include/libxml2")}",
        "--with-xslt-lib=#{Shellwords.escape("#{install_dir}/embedded/lib")}",
        "--with-xslt-include=#{Shellwords.escape("#{install_dir}/embedded/include/libxslt")}",
        "--with-iconv-dir=#{Shellwords.escape("#{install_dir}/embedded")}",
        "--with-zlib-dir=#{Shellwords.escape("#{install_dir}/embedded")}"
      ].join(" ")
    }
  end
  def install_args_for(gem_name)
    all_install_args[gem_name] || ""
  end

  # Give block all the variables
  def block(*args, &block)
    super do
      extend BuildChefDKGem
      instance_eval(&block)
    end
  end

  # Give build all the variables
  def build(*args, &block)
    super do
      extend BuildChefDKGem
      instance_eval(&block)
    end
  end
end
