
describe "PolicyfileBuilder #FIXME - rename" do

  def id_to_dotted(sha1_id)
    major = sha1_id[0...14]
    minor = sha1_id[14...28]
    patch = sha1_id[28..40]
    decimal_integers =[major, minor, patch].map {|hex| hex.to_i(16) }
    decimal_integers.join(".")
  end

  let(:complete_policyfile) do

    Policyfile.build do |p|

      # Required
      p.name("basic_example")

      # Required. Should be fully expanded without roles
      p.set_runlist_to("recipe[foo]", "recipe[bar]", "recipe[baz::non_default]")

      p.add_cookbook("foo") do |cb|
        cb.cache_key("foo-1.0.0")
        cb.source("https://community.getchef.com/api/cookbooks/foo/1.0.0")
        cb.use_content_identifier # default (?)
      end

      p.add_cookbook("bar") do |cb|
        cb.cache_key("bar-f59ee7a5bca6a4e606b67f7f856b768d847c39bb")
        cb.source("git://github.com/opscode-cookbooks/bar.git")
        cb.use_content_identifier # default (?)
      end

      p.add_cookbook("baz") do |cb|
        # for a local source, we assume the cookbook is in development and
        # could be modified, we will check the identifier before uploading
        cb.source("my_cookbooks/baz")
        cb.use_content_identifier
      end

      p.add_cookbook("dep_of_bar") do |cb|
        cb.cache_key("dep_of_bar-1.2.3")
        cb.source("https://chef-server.example.com/cookbooks/dep_of_bar/1.2.3")
        cb.use_content_identifier
      end
    end

  end


  let(:complete_policyfile_compiled) do
    {

      "name" => "basic_example",

      "run_list" => ["recipe[foo]", "recipe[bar]", "recipe[baz::non_default]"],

      "cookbook_locks" => {

        "foo" => {
          "version" => "1.0.0",
          "identifier" => "168d2102fb11c9617cd8a981166c8adc30a6e915",
          "dotted_decimal_identifier" => id_to_dotted("168d2102fb11c9617cd8a981166c8adc30a6e915"),
          "source" => "https://community.getchef.com/api/cookbooks/foo/1.0.0",
          "cache_key" => "foo-1.0.0"
        },

        "bar" => {
          "version" => "2.0.0",
          "identifier" => "feab40e1fca77c7360ccca1481bb8ba5f919ce3a",
          "dotted_decimal_identifier" => id_to_dotted("feab40e1fca77c7360ccca1481bb8ba5f919ce3a"),
          "source" => "git://github.com/opscode-cookbooks/bar.git",
          "cache_key" => "bar-f59ee7a5bca6a4e606b67f7f856b768d847c39bb"
        },

        "baz" => {
          "version" => "1.2.3",
          "source" => "my_coookbooks/baz",
          "cache_key" => nil,
          "scm_info" => {
            "scm" => "git",
            # To get this info, you need to do something like:
            # figure out branch or assume 'master'
            # git config --get branch.master.remote
            # git config --get remote.opscode.url
            "remote" => "git@github.com:myorg/baz-cookbook.git",
            "ref" => "d867188a29db0ec438ae812a0fae90f3c267f38e",
            "working_tree_clean" => false,
            "published" => false
          },
        },

        "dep_of_bar" => {
          "version" => "1.2.3",
          "identifier" => "3d9d097332199fdafc3237c0ec11fcd784c11b4d",
          "dotted_decimal_identifier" => id_to_dotted("3d9d097332199fdafc3237c0ec11fcd784c11b4d"),
          "source" => "https://chef-server.example.com/cookbooks/dep_of_bar/1.2.3",
          "cache_key" => "dep_of_bar-1.2.3",

        },

      },

    }
  end


end
