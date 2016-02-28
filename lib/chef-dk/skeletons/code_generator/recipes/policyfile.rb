
context = ChefDK::Generator.context
policyfile_path = File.join(context.policyfile_dir, "#{context.new_file_basename}.rb")

directory File.dirname(policyfile_path) do
  action :create
  recursive true
end

template policyfile_path do
  source "Policyfile.rb.erb"
  helpers(ChefDK::Generator::TemplateHelper)
end
