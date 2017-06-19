# frozen_string_literal: true
context = ChefDK::Generator.context
cookbook_dir = File.join(context.cookbook_root, context.cookbook_name)
template_dir = File.join(cookbook_dir, 'templates')
template_filename = context.new_file_basename

unless File.extname(template_filename) == '.erb'
  # new_file_basename is a frozen string, so we have to create an entirely
  # new string here instead of using concat.
  template_filename = "#{template_filename}.erb"
end

template_path = File.join(cookbook_dir, 'templates', template_filename)

directory template_dir do
  recursive true
end

if context.content_source

  file template_path do
    content(IO.read(context.content_source))
  end

else

  template template_path do
    source 'template.erb'
    helpers(ChefDK::Generator::TemplateHelper)
  end

end
