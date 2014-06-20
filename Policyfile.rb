default_source :community

run_list "apache2", "omnibus"

cookbook "omnibus", git: "git@github.com:opscode-cookbooks/omnibus.git", branch: "master"
