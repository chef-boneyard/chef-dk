context = ChefDK::Generator.context
repo_dir = File.join(context.repo_root, context.repo_name)

# repo root dir
directory repo_dir

# Top level files
template "#{repo_dir}/LICENSE" do
  source "LICENSE.#{context.license}.erb"
  helpers(ChefDK::Generator::TemplateHelper)
end

cookbook_file "#{repo_dir}/.chef-repo.txt" do
  source "repo/dot-chef-repo.txt"
end

cookbook_file "#{repo_dir}/README.md" do
  source "repo/README.md"
end

cookbook_file "#{repo_dir}/chefignore" do
  source "chefignore"
end

# By default, we now create a policies directory and don't create a roles or
# environments directory. The skeleton files for those still exist, so just add
# roles and environments to the array here to generate a repo with these
# directories.
%w{cookbooks data_bags policies}.each do |tlo|
  remote_directory "#{repo_dir}/#{tlo}" do
    source "repo/#{tlo}"
  end
end

cookbook_file "#{repo_dir}/cookbooks/README.md" do
  if context.policy_only
    source "cookbook_readmes/README-policy.md"
  else
    source "cookbook_readmes/README.md"
  end
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
  end
end
