package 'wget'
package 'python-software-properties'

bash 'Install dokku' do
  code <<-EOT
wget -qO- https://raw.github.com/progrium/dokku/v#{node[:dokku][:version]}/bootstrap.sh | DOKKU_TAG=v#{node[:dokku][:version]} bash
echo '#{ node[:dokku][:vhost] }' > /home/dokku/VHOST
EOT
  creates '/home/dokku/VHOST'
end

node['dokku']['plugins'].each do |name, repos|
  bash "Install dokku plugins #{name}" do
    code <<-EOT
cd /var/lib/dokku/plugins
git clone #{repos} #{name}
dokku plugins-install
EOT
    not_if "file /var/lib/dokku/plugins/#{name}"
  end
end


cookbook_file '/tmp/dokku_id_rsa.pub' do
  source 'dokku_id_rsa.pub'
end

bash 'Add ssh pub-key to dokku' do
  code   'cat /tmp/dokku_id_rsa.pub | sshcommand acl-add dokku dokku-user'
  not_if 'cat /home/dokku/.ssh/authorized_keys | grep dokku-user'
end
