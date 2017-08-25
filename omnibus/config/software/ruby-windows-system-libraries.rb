name "ruby-windows-system-libraries"

default_version "0.0.1"

license :project_license
skip_transitive_dependency_licensing true

dependency "ruby"

build do
  if windows?
    # Needed now that we switched to msys2 and have not figured out how to tell
    # it how to statically link yet
    dlls = [
      "libwinpthread-1",
      "libstdc++-6",
    ]
    if windows_arch_i386?
      dlls << "libgcc_s_dw2-1"
    else
      dlls << "libgcc_s_seh-1"
    end
    dlls.each do |dll|
      mingw = ENV["MSYSTEM"].downcase
      msys_path = ENV["OMNIBUS_TOOLCHAIN_INSTALL_DIR"] ? "#{ENV["OMNIBUS_TOOLCHAIN_INSTALL_DIR"]}/embedded/bin" : "C:/msys2"
      windows_path = "#{msys_path}/#{mingw}/bin/#{dll}.dll"
      if File.exist?(windows_path)
        copy windows_path, "#{install_dir}/embedded/bin/#{dll}.dll"
      else
        raise "Cannot find required DLL needed for dynamic linking: #{windows_path}"
      end
    end

    if version.satisfies?(">= 2.4")
      %w{ erb gem irb rdoc ri }.each do |cmd|
        copy "#{project_dir}/bin/#{cmd}", "#{install_dir}/embedded/bin/#{cmd}"
      end
    end

  end
end
