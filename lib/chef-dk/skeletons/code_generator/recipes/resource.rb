# frozen_string_literal: true
context = ChefDK::Generator.context
cookbook_dir = File.join(context.cookbook_root, context.cookbook_name)

resource_dir = File.join(cookbook_dir, 'resources')
resource_path = File.join(resource_dir, "#{context.new_file_basename}.rb")

directory resource_dir

template resource_path do
  source 'resource.rb.erb'
  helpers(ChefDK::Generator::TemplateHelper)
end
