
# default['docker']['exec_driver']    = 'lxc'
default['docker']['host']           = ['unix:///var/run/docker.sock', 'tcp://0.0.0.0:4243']
default['docker']['options']        = '-g=/mnt/docker'
default['docker']['storage_driver'] = 'aufs'
default['docker']['version']        = '1.4.1'

default['dokku']['version']         = '0.2.2'
default['dokku']['plugins']         = {
  'docker-options' => 'https://github.com/dyson/dokku-docker-options.git',
  'memcached'      => 'https://github.com/jezdez/dokku-memcached-plugin.git',
  'link'           => 'https://github.com/rlaneve/dokku-link.git',
  'redis'          => 'https://github.com/ttakamura/dokku-redis-plugin.git'
}
