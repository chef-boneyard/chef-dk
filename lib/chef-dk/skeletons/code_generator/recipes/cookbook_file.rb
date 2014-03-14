
context = ChefDK::Generator.context
cookbook_dir = File.join(context.root, context.cookbook_name)
files_dir = File.join(cookbook_dir, "files/default")
cookbook_file_path = File.join(cookbook_dir, "files/default", "#{context.new_file_basename}")

directory files_dir do
  recursive true
end

if source_file = context.content_source

  file cookbook_file_path do
    content(IO.read(source_file))
  end

else

  template cookbook_file_path do
    source "template.erb"
    helpers(ChefDK::Generator::TemplateHelper)
  end

end

