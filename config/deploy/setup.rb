role :servers, "",""
#
set :user, "root"
set :path_to, ""
#
set :chef_local_dir, "#{path_to}/chef-repo"
set :chef_remote_dir, "/root/chef"
#
namespace :chef do
  task :init, :roles => :servers do
    run "apt-get update && apt-get -y install sudo curl rsync"
    run "curl -L https://www.opscode.com/chef/install.sh | sudo bash"
  end
  task :sync, :roles => :servers do
    run "mkdir -p #{chef_remote_dir}/chef-repo/"
    find_servers_for_task(current_task).each do |server|
      if ( "#{server.port}" == nil )
        `rsync -avz #{chef_local_dir}/ -e "ssh -p #{server.port}" root@#{server.host}:#{chef_remote_dir}/chef-repo/`
      else
        `rsync -avz #{chef_local_dir}/ root@#{server.host}:#{chef_remote_dir}/chef-repo/`
      end
    end
  end
  task :deploy, :roles => :servers do
    find_servers_for_task(current_task).each do |server|
      run "chef-solo -j #{chef_remote_dir}/chef-repo/nodes/localhost.json -c #{chef_remote_dir}/chef-repo/solo.rb"
    end
  end
end
