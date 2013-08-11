require 'spec_helper'

describe Fontcustom::Util do
  def util
    Fontcustom::Util
  end

  context ".check_fontforge" do
    it "should raise error if fontforge isn't installed" do
      util.stub(:"`").and_return("")
      expect { util.check_fontforge }.to raise_error Fontcustom::Error, /install fontforge/
    end
  end

  context ".collect_options" do
    it "should raise error if fontcustom.yml isn't valid" do
      options = { 
        :project_root => fixture,
        :input => "shared/vectors",
        :config => "util/fontcustom-malformed.yml" 
      }
      expect { util.collect_options(options) }.to raise_error Fontcustom::Error, /couldn't read your configuration/
    end

    it "should overwrite defaults with config file" do
      options = { 
        :project_root => fixture,
        :input => "shared/vectors",
        :config => "util/fontcustom.yml" 
      }
      options = util.collect_options options
      options[:font_name].should == "Custom-Name-From-Config"
    end

    it "should overwrite config file and defaults with CLI options" do
      options = { 
        :project_root => fixture,
        :input => "shared/vectors",
        :font_name => "custom-name-from-cli",
        :config => "util/fontcustom.yml" 
      }
      options = util.collect_options options
      options[:font_name].should == "custom-name-from-cli"
    end

    it "should normalize file name" do
      options = { 
        :project_root => fixture,
        :input => "shared/vectors",
        :font_name => " A_stR4nG3  nAm3 Ø&  "
      }
      options = util.collect_options options
      options[:font_name].should == "A_stR4nG3--nAm3---"
    end
  end

  context ".get_config_path" do
    it "should search for fontcustom.yml if options[:config] is a dir" do
      options = { 
        :project_root => fixture,
        :config => "util/config-is-in-dir"
      }
      util.get_config_path(options).should == fixture("util/config-is-in-dir/fontcustom.yml")
    end

    it "should search use options[:config] if it's a file" do
      options = { 
        :project_root => fixture,
        :config => "util/fontcustom.yml"
      }
      util.get_config_path(options).should == fixture("util/fontcustom.yml")
    end

    it "should raise error if fontcustom.yml was specified but doesn't exist" do
      options = { 
        :project_root => fixture,
        :input => "shared/vectors",
        :config => "does-not-exist"
      }
      expect { util.get_config_path(options) }.to raise_error Fontcustom::Error, /couldn't find/
    end

    it "should print out which fontcustom.yml it's using"
    it "should print a warning if fontcustom.yml wasn't specified / doesn't exist"
  end

  context ".get_input_paths" do
    it "should raise error if input[:vectors] doesn't contain vectors" do
      options = {
        :project_root => fixture,
        :input => "shared/vectors-empty"
      }
      expect { util.get_input_paths(options) }.to raise_error Fontcustom::Error, /doesn't contain any vectors/
    end

    context "when passed a hash" do
      it "should return a hash of input locations" do
        options = {
          :input => { :vectors => "shared/vectors" },
          :project_root => fixture
        }
        paths = util.get_input_paths(options)
        paths.should have_key("vectors")
        paths.should have_key("templates")
      end

      it "should set :templates as :vectors if :templates isn't passed" do
        options = {
          :input => { :vectors => "shared/vectors" },
          :project_root => fixture
        }
        paths = util.get_input_paths(options)
        paths[:vectors].should equal(paths[:templates])
      end

      it "should preserve :templates if it is passed" do
        options = {
          :input => { :vectors => "shared/vectors", :templates => "shared/templates" },
          :project_root => fixture
        }
        paths = util.get_input_paths(options)
        paths[:templates].should_not equal(paths[:vectors])
      end

      it "should raise an error if :vectors isn't included" do
        options = {
          :input => { :templates => "shared/templates" },
          :project_root => fixture
        }
        expect { util.get_input_paths(options) }.to raise_error Fontcustom::Error, /should be a string or a hash/
      end

      it "should raise an error if :vectors doesn't point to an existing directory" do
        options = {
          :input => { :vectors => "shared/not-a-dir" },
          :project_root => fixture
        }
        expect { util.get_input_paths(options) }.to raise_error Fontcustom::Error, /should be a directory/
      end
    end

    context "when passed a string" do
      it "should return a hash of input locations" do
        options = { 
          :input => "shared/vectors",
          :project_root => fixture
        }
        paths = util.get_input_paths(options)
        paths.should have_key("vectors")
        paths.should have_key("templates")
      end

      it "should set :templates to match :vectors" do
        options = { 
          :input => "shared/vectors",
          :project_root => fixture
        }
        paths = util.get_input_paths(options)
        paths[:vectors].should equal(paths[:templates])
      end

      it "should raise an error if :vectors doesn't point to a directory" do
        options = { 
          :input => "shared/not-a-dir",
          :project_root => fixture
        }
        expect { util.collect_options options }.to raise_error Fontcustom::Error, /should be a directory/
      end
    end
  end

  context ".get_output_paths" do
    it "should default to :project_root/:font_name if no output is specified" do
      options = { :project_root => fixture, :font_name => "test" }
      paths = util.get_output_paths(options)
      paths[:fonts].should eq(fixture("test"))
    end

    it "should print a warning when defaulting to :project_root/fonts"

    context "when passed a hash" do
      it "should return a hash of output locations" do 
        options = {
          :output => { :fonts => "output/fonts" },
          :project_root => fixture
        }
        paths = util.get_output_paths(options)
        paths.should have_key("fonts")
        paths.should have_key("css")
        paths.should have_key("preview")
      end

      it "should set :css and :preview to match :fonts if either aren't passed" do
        options = {
          :output => { :fonts => "output/fonts" },
          :project_root => fixture
        }
        paths = util.get_output_paths(options)
        paths[:css].should equal(paths[:fonts])
        paths[:preview].should equal(paths[:fonts])
      end

      it "should preserve :css and :preview if they do exist" do
        options = {
          :output => { 
            :fonts => "output/fonts",
            :css => "output/styles",
            :preview => "output/preview"
          },
          :project_root => fixture
        }
        paths = util.get_output_paths(options)
        paths[:css].should_not equal(paths[:fonts])
        paths[:preview].should_not equal(paths[:fonts])
      end

      it "should create additional paths if they are given" do
        options = {
          :output => { 
            :fonts => "output/fonts",
            "special.js" => "assets/javascripts"
          },
          :project_root => fixture
        }
        paths = util.get_output_paths(options)
        paths["special.js"].should eq(File.join(options[:project_root], "assets/javascripts"))
      end
      
      it "should raise an error if :fonts isn't included" do
        options = {
          :output => { :css => "output/styles" },
          :project_root => fixture
        }
        expect { util.get_output_paths(options) }.to raise_error Fontcustom::Error, /containing a "fonts" key/
      end
    end

    context "when passed a string" do
      it "should return a hash of output locations" do
        options = {
          :output => "output/fonts",
          :project_root => fixture
        }
        paths = util.get_output_paths(options)
        paths.should have_key("fonts")
        paths.should have_key("css")
        paths.should have_key("preview")
      end

      it "should set :css and :preview to match :fonts" do
        options = {
          :output => "output/fonts",
          :project_root => fixture
        }
        paths = util.get_output_paths(options)
        paths[:css].should equal(paths[:fonts])
        paths[:preview].should equal(paths[:fonts])
      end

      it "should raise an error if :fonts exists but isn't a directory" do
        options = {
          :output => "shared/not-a-dir",
          :project_root => fixture
        }
        expect { util.get_output_paths(options) }.to raise_error Fontcustom::Error, /directory, not a file/
      end
    end
  end

  context ".get_templates" do
    it "should ensure that 'css' is included with 'preview'" do
      lib = util.gem_lib_path
      options = { :input => fixture("shared/vectors"), :templates => %W|preview| }
      templates = util.get_templates options
      templates.should =~ [
        File.join(lib, "templates", "fontcustom.css"),
        File.join(lib, "templates", "fontcustom-preview.html")
      ]
    end

    it "should expand shorthand for packaged templates" do
      lib = util.gem_lib_path
      options = { :input => fixture("shared/vectors"), :templates => %W|preview css scss bootstrap bootstrap-scss bootstrap-ie7 bootstrap-ie7-scss| }
      templates = util.get_templates options
      templates.should =~ [
        File.join(lib, "templates", "fontcustom-preview.html"),
        File.join(lib, "templates", "fontcustom.css"),
        File.join(lib, "templates", "_fontcustom.scss"),
        File.join(lib, "templates", "fontcustom-bootstrap.css"),
        File.join(lib, "templates", "_fontcustom-bootstrap.scss"),
        File.join(lib, "templates", "fontcustom-bootstrap-ie7.css"),
        File.join(lib, "templates", "_fontcustom-bootstrap-ie7.scss")
      ]
    end

    it "should find custom templates in :template_path" do
      options = { 
        :project_root => fixture, 
        :input => { 
          :vectors => fixture("shared/vectors"), 
          :templates => fixture("shared/templates") 
        },
        :templates => %W|custom.css|
      }
      templates = util.get_templates options
      templates.should eq([ fixture("shared/templates/custom.css") ])
    end

    it "should raise an error if a template does not exist" do
      options = {
        :project_root => fixture,
        :input => { :templates => "shared/templates" },
        :templates => %W|css fake-template|
      }
      expect { util.get_templates options }.to raise_error Fontcustom::Error, /couldn't find.+fake-template/
    end
  end
end
