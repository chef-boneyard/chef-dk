context = ChefDK::Generator.context
cookbook_dir = File.join(context.cookbook_root, context.cookbook_name)
files_dir = File.join(cookbook_dir, 'files')
cookbook_file_path = File.join(files_dir, context.new_file_basename)

directory files_dir do
  recursive true
end

if context.content_source

  file cookbook_file_path do
    content(IO.read(context.context_source))
  end

else

  template cookbook_file_path do
    source 'cookbook_file.erb'
    helpers(ChefDK::Generator::TemplateHelper)
  end

end
