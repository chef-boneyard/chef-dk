name "chef-dk-complete"

license :project_license

dependency "chef-dk"
dependency "chef-dk-appbundle"

if windows?
  dependency "chef-dk-env-customization"
  dependency "chef-dk-powershell-scripts"
  # TODO can this be safely moved to before the chef-dk?
  # It would make caching better ...
  dependency "ruby-windows-devkit"
end

dependency "chef-dk-remove-docs"
dependency "rubygems-customization"
dependency "shebang-cleanup"
dependency "version-manifest"
dependency "openssl-customization"

unless windows?
  # For the Delivery build nodes
  dependency "delivery-cli"
  # This is a build-time dependency, so we won't leave it behind:
  dependency "rust-uninstall"
end

# Leave for last so system git is used for most of the build.
# TODO we have a card for getting git working on windows in the future
dependency "git" unless windows?

dependency "clean-static-libs"
