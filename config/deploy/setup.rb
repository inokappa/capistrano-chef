role :servers, "xxx.xxx.xxx.1:49163","xxx.xxx.xxx.1:49164"
#
set :user, "root"
set :path_to, "/home/kappa"
#
set :chef_local_dir, "#{path_to}/chef-repo"
set :chef_remote_dir, "/root/chef"
#
namespace :chef do
  task :init, :roles => :servers do
    run "apt-get update && apt-get -y install sudo curl"
    run "curl -L https://www.opscode.com/chef/install.sh | sudo bash"
    run "mkdir -p #{chef_remote_dir}/chef-repo/"
    find_servers_for_task(current_task).each do |server|
      if server.include?(":")
        sv =
        port = 
        `rsync -avz #{chef_local_dir}/ -e "ssh -p #{port}" root@#{sv}:#{chef_remote_dir}/chef-repo/`
      else
        `rsync -avz #{chef_local_dir}/ root@#{server}:#{chef_remote_dir}/chef-repo/`
      end
    end
  end
  task :deploy, :roles => :servers do
    find_servers_for_task(current_task).each do |server|
      run "chef-solo -j #{chef_remote_dir}/chef-repo/nodes/#{server}.json -c #{chef_remote_dir}/chef-repo/solo.rb"
    end
  end
end
