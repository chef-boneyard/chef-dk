%w(unit lint syntax).each do |phase|
  args = "--server localhost --ent test --org kitchen"
  # TODO: This works on Linux/Unix. Not Windows.
  execute "HOME=/home/vagrant delivery job verify #{phase} #{args}" do
    cwd '/tmp/repo-data'
    user 'vagrant'
    environment('GIT_DISCOVERY_ACROSS_FILESYSTEM' => '1')
  end
end
