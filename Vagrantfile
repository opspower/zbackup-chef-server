require 'berkshelf/vagrant'

HEIMDALL_PORT             = 5959
HEIMDALL_FORWARD_PORT    = 15959

HEIMDALL_DB_PORT         =  5432
HEIMDALL_FORWARD_DB_PORT = 15432

# See Berksfile for more on this
ENABLE_GRAPHITE = false

Vagrant::Config.run do |config|
  # All Vagrant configuration is done here. The most common configuration
  # options are documented and commented below. For a complete reference,
  # please see the online documentation at vagrantup.com.

  # The path to the Berksfile to use with Vagrant Berkshelf
  # config.berkshelf.berksfile_path = "./Berksfile"

  # An array of symbols representing groups of cookbook described in the Vagrantfile
  # to skip installing and copying to Vagrant's shelf.
  # config.berkshelf.only = []

  # An array of symbols representing groups of cookbook described in the Vagrantfile
  # to skip installing and copying to Vagrant's shelf.
  # config.berkshelf.except = []

  config.vm.host_name = "oc-heimdall-berkshelf"

  config.vm.box = "opscode-ubuntu-10.04"
  config.vm.box_url = "https://opscode-vm.s3.amazonaws.com/vagrant/boxes/opscode-ubuntu-10.04.box"

  # Boot with a GUI so you can see the screen. (Default is headless)
  # config.vm.boot_mode = :gui

  # Assign this VM to a host-only network IP, allowing you to access it
  # via the IP. Host-only networks can talk to the host machine as well as
  # any other machines on the same network, but cannot be accessed (through this
  # network interface) by any external networks.
  config.vm.network :hostonly, "33.33.33.10", :adapter => 2

  # Use virtio networking, cuz heimdall is FAST
  config.vm.customize ["modifyvm", :id, "--nictype1", "virtio"] # NAT NIC
  config.vm.customize ["modifyvm", :id, "--nictype2", "virtio"] # host-only NIC

  # Assign this VM to a bridged network, allowing you to connect directly to a
  # network using the host's network device. This makes the VM appear as another
  # physical device on your network.

  # config.vm.network :bridged

  # Forward a port from the guest to the host, which allows for outside
  # computers to access the VM, whereas host only networking does not.
  # config.vm.forward_port 80, 8080

  config.vm.forward_port HEIMDALL_PORT, HEIMDALL_FORWARD_PORT
  config.vm.forward_port HEIMDALL_DB_PORT, HEIMDALL_FORWARD_DB_PORT

  # Share an additional folder to the guest VM. The first argument is
  # an identifier, the second is the path on the guest to mount the
  # folder, and the third is the path on the host to the actual folder.
  # config.vm.share_folder "v-data", "/vagrant_data", "../data"

  config.ssh.max_tries = 40
  config.ssh.timeout   = 120

  config.ssh.forward_agent = true

  config.vm.provision :chef_solo do |chef|
    chef.json = {
      # When running in a chef-solo setting, the postgres user
      # password must be defined here, since there is no Chef Server
      # to persist it to.
      "postgresql" => {
        "password" => {
          "postgres" => "honeybadger"
        },
        "config" => {
          "port" => HEIMDALL_DB_PORT
        }
      },
      "oc_heimdall" => {
        "host" => "0.0.0.0",
        "port" => HEIMDALL_PORT,
        "database" => {
          "port" => HEIMDALL_DB_PORT
        }
      },
      # These values are hard-coded into the PIAB monitoring cookbooks
      # we're currently using for graphite in dev... we don't need a
      # running estatsd server for this to work, though.
      "stats_hero" => {
        "estatsd_host" => "127.0.0.1",
        "estatsd_port" => 5665
      }
    }

    chef.roles_path = "#{ENV['OPSCODE_PLATFORM_REPO']}/roles"
    chef.data_bags_path = "#{ENV['OPSCODE_PLATFORM_REPO']}/data_bags"

    chef.run_list = [
                     "recipe[opscode-dev-shim]",
                     "recipe[opscode-heimdall::dev]"
                    ]
  end

  if ENABLE_GRAPHITE
    # The dev-vm cookbooks assume an Omnibus directory structure; this shell provisioner fakes it
    config.vm.provision :shell, :inline => "mkdir -p /opt/opscode"
    config.vm.provision :chef_solo do |chef|
      chef.roles_path = "#{ENV['OPSCODE_PLATFORM_REPO']}/roles"
      chef.data_bags_path = "#{ENV['OPSCODE_PLATFORM_REPO']}/data_bags"
      chef.run_list = ["recipe[opscode-dev-shim]",
                       "recipe[piab::monitoring]"]
    end
  end
end
