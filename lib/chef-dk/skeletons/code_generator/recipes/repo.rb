context = ChefDK::Generator.context
repo_dir = File.join(context.repo_root, context.repo_name)

# repo root dir
directory repo_dir

# Top level files
template "#{repo_dir}/LICENSE" do
  source "LICENSE.#{context.license}.erb"
  helpers(ChefDK::Generator::TemplateHelper)
  action :create_if_missing
end

cookbook_file "#{repo_dir}/.chef-repo.txt" do
  source "repo/dot-chef-repo.txt"
  action :create_if_missing
end

cookbook_file "#{repo_dir}/README.md" do
  source "repo/README.md"
  action :create_if_missing
end

cookbook_file "#{repo_dir}/chefignore" do
  source "chefignore"
  action :create_if_missing
end

directories_to_create = %w{ cookbooks data_bags }

if context.use_roles
  directories_to_create += %w{ roles environments }
else
  directories_to_create += %w{ policies }
end

directories_to_create.each do |tlo|
  remote_directory "#{repo_dir}/#{tlo}" do
    source "repo/#{tlo}"
    action :create_if_missing
  end
end

cookbook_file "#{repo_dir}/cookbooks/README.md" do
  if context.policy_only
    source "cookbook_readmes/README-policy.md"
  else
    source "cookbook_readmes/README.md"
  end
  action :create_if_missing
end

# git
if context.have_git
  if !context.skip_git_init
    execute("initialize-git") do
      command("git init .")
      cwd repo_dir
      not_if { File.exist?("#{repo_dir}/.gitignore") }
    end
  end
  template "#{repo_dir}/.gitignore" do
    source "repo/gitignore.erb"
    helpers(ChefDK::Generator::TemplateHelper)
    action :create_if_missing
  end
end
