
context = ChefDK::Generator.context
cookbook_dir = File.join(context.cookbook_root, context.cookbook_name)
template_dir = File.join(cookbook_dir, "templates", "default")
template_filename = context.new_file_basename

unless File.extname(template_filename) == ".erb"
  # new_file_basename is a frozen string, so we have to create an entirely
  # new string here instead of using concat.
  template_filename = "#{template_filename}.erb"
end

template_path = File.join(cookbook_dir, "templates", "default", template_filename)

directory template_dir do
  recursive true
end

if source_file = context.content_source

  file template_path do
    content(IO.read(source_file))
  end

else

  template template_path do
    source "template.erb"
    helpers(ChefDK::Generator::TemplateHelper)
  end

end
