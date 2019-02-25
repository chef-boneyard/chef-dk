name "rbnaclk-libsodium-fix"

default_version "0.0.1"

license :project_license
skip_transitive_dependency_licensing true

build do
  if windows?
    copy "#{install_dir}/embedded/bin/libsodium-23.dll", "#{install_dir}/embedded/bin/sodium.dll"
  end
end
