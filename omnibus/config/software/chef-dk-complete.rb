name "chef-dk-complete"

license :project_license

# For the Delivery build nodes
dependency "delivery-cli"
# This is a build-time dependency, so we won't leave it behind:
dependency "rust-uninstall"

# Leave for last so system git is used for most of the build.
if windows?
  dependency "git-windows"
else
  dependency "git-custom-bindir"
end

dependency "chef-dk"
dependency "chef-dk-appbundle"

dependency "gem-permissions"

if windows?
  dependency "chef-dk-env-customization"
  dependency "chef-dk-powershell-scripts"
  # TODO can this be safely moved to before the chef-dk?
  # It would make caching better ...
  dependency "ruby-windows-devkit"
end

dependency "chef-dk-cleanup"
dependency "rubygems-customization"
dependency "shebang-cleanup"
dependency "version-manifest"
dependency "openssl-customization"

dependency "stunnel" if fips_mode?
