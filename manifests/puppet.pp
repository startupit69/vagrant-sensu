#
# install rabbitmq
#


# get hiera variables for title resource

$rabbitmq_sensu_user = hiera('rabbitmq::sensu_user','sensu')
$rabbitmq_sensu_vhost = hiera('rabbitmq::sensu_vhost','sensu')
$rabbitmq_sensu_permissions = hiera('rabbitmq::sensu_user_permissions','sensu@/sensu')

class { '::rabbitmq':
  delete_guest_user        => true,
  admin_enable             => true,
  ssl                      => true,
  ssl_cacert               => hiera('rabbitmq::ssl_cacert','/etc/ssl/sensu/cacert.pem'),
  ssl_cert                 => hiera('rabbitmq::ssl_cert','/etc/ssl/sensu/server/cert.pem'),
  ssl_key                  => hiera('rabbitmq::ssl_key','/etc/ssl/sensu/server/key.pem'),
  ssl_management_port      => hiera('rabbitmq::ssl_port','5671'),
  ssl_verify               => 'verify_peer',
  ssl_fail_if_no_peer_cert => true,
}

rabbitmq_user { $rabbitmq_sensu_user:
  admin    => false,
  password => hiera('rabbitmq::sensu_pass','mypsas'),
}

rabbitmq_vhost { $rabbitmq_sensu_vhost:
  ensure => present,
}

rabbitmq_user_permissions { $rabbitmq_sensu_permissions:
  configure_permission => '.*',
  read_permission      => '.*',
  write_permission     => '.*',
}

#
# install autogenerated certs - use only for dev box
#

file { ['/etc/ssl/sensu','/etc/ssl/sensu/server', '/etc/ssl/sensu/client']:
  ensure => directory,
} ->

file { '/etc/ssl/sensu/server/cert.pem':
  ensure  => present,
  source  => '/root/ssl_certs/server/cert.pem',
} ->

file { '/etc/ssl/sensu/server/key.pem':
  ensure  => present,
  source  => '/root/ssl_certs/server/key.pem',
} ->

file { '/etc/ssl/sensu/cacert.pem':
  ensure => present,
  source => '/root/ssl_certs/sensu_ca/cacert.pem',
  before => Class['::rabbitmq'],
} ->

file { '/etc/ssl/sensu/client/cert.pem':
  ensure => present,
  source => '/root/ssl_certs/client/cert.pem',
  before => Class['::rabbitmq'],
} ->

file { '/etc/ssl/sensu/client/key.pem':
  ensure => present,
  source => '/root/ssl_certs/client/key.pem',
  before => Class['::rabbitmq'],
}

#
# install default redis
#

class {'::redis':
  manage_repo => true,
  bind        => '127.0.0.1',
}

#
# install sensu
#

class { '::sensu':
  rabbitmq_password        => hiera('rabbitmq::sensu_pass','mypsas'),
  rabbitmq_port            => hiera('rabbitmq::ssl_port', '5671'),
  server                   => true,
  api                      => true,
  rabbitmq_ssl_cert_chain  => hiera('sensu::client_ssl_cert_chain','/etc/ssl/sensu/client/cert.pem'),
  rabbitmq_ssl_private_key => hiera('sensu::client_ssl_private_key','/etc/ssl/sensu/client/key.pem'),
  require                  => [ Class['::redis'], Class['::rabbitmq'] ],
} ->

class {'::uchiwa':
  install_repo => false,
}
