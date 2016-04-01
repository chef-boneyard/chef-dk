name "chef-dk-complete"

license :project_license

dependency "chef-dk"
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
dependency "clean-static-libs"
