# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# == Class: translation_checksite
#
# Maintaining environment for translation checksite
#
# === Parameters
#
# === Variables
#
# [*devstack_dir*]
# Destination of DevStack installation
#
# [*minimal*]
# Minimal DevStack installation without plugins
#
# [*zanata_cli*]
# Location of Zanata Client
#
# [*stack_user*]
# Unix user of DecStack installation
# needs sudo rights without password
#
# [*revision*]
# used branch (check https://git.opentsack.org/openstack-dev/devstack.git
# for available branches )
#
# [*project_version*]
# used project version in Zanata (check Zanata for available versions )
#
# [*admin_password*]
# Password of admin (taking care)
#
# [*database_password*]
# Password of databse
#
# [*rabbit_password*]
# Password of RabbitMQ
#
# [*service_password*]
# Password of services
#
# [*service_token*]
# Password of service token
#
# [*swift_hash*]
# Password of swift hash
#
# [*sync_hour*]
# [*sync_minute*]
# configure cron to sync translation files from Zanata
#
# [*shutdown*]
# Shutdown and delete DevStack
#
# [*restack*]
# daily cron to unstack and stack
#
# [*restack_hour*]
# [*restack_minute*]
# configure cron to restack the environment
#
# === Authors
#
# Ying Chun Guo <guoyingc@cn.ibm.com>
# KATO Tomoyuki <kato.tomoyuki@jp.fujitsu.com>
# Ian Y. CHoi <ianyrchoi@gmail.com>
# Akihiro Motoki <amotoki@gmail.com>
# Frank Kloeker <f.kloeker@telekom.de>
#
#

class translation_checksite (
  $devstack_dir      = "/home/ubuntu/devstack",
  $minimal           = undef,
  $zanata_cli        = "/opt/zanata/zanata-cli-3.8.1/bin/zanata-cli",
  $stack_user        = "ubuntu",
  $revision          = "master",
  $project_version   = "master",
  $admin_password    = "password",
  $database_password = "password",
  $rabbit_password   = "password",
  $service_password  = "password",
  $service_token     = "password",
  $swift_hash        = "password",
  $sync_hour         = 1,
  $sync_minute       = 0,
  $shutdown          = undef,
  $restack           = undef,
  $restack_hour      = 0,
  $restack_minute    = 0,
) {

  vcsrepo { "$devstack_dir":
    ensure   => present,
    provider => git,
    owner    => "${stack_user}",
    group    => "${stack_user}",
    source   => 'https://git.openstack.org/openstack-dev/devstack.git',
    revision => "${revision}",
  }

  if ($minimal == 1) {
    file {"${devstack_dir}/local.conf":
      ensure  => file,
      mode    => '0600',
      owner   => "${stack_user}",
      group   => "${stack_user}",
      content => template('translation_checksite/local.conf.minimal.erb'),
      force   => true,
      require => [ Vcsrepo["${devstack_dir}"] ],
    }
  } else {
    file {"${devstack_dir}/local.conf":
      ensure  => file,
      mode    => '0600',
      owner   => "${stack_user}",
      group   => "${stack_user}",
      content => template('translation_checksite/local.conf.erb'),
      force   => true,
      require => [ Vcsrepo["${devstack_dir}"] ],
    }
  }

  exec { "run_devstack":
    cwd       => $devstack_dir,
    command   => "/bin/su ${stack_user} -c ${devstack_dir}/stack.sh &",
    unless    => "/bin/ps aux | /usr/bin/pgrep stack",
    timeout   => 3600,
    require   => [ Vcsrepo["${devstack_dir}"], File["${devstack_dir}/local.conf"] ],
    logoutput => true
  }

  file {"/home/${stack_user}/zanata.xml":
    ensure  => file,
    mode    => '0644',
    owner   => "${stack_user}",
    group   => "${stack_user}",
    content => template('translation_checksite/zanata.xml.erb'),
    force   => true,
  }

  file {"/home/${stack_user}/zanata-sync.sh":
    ensure  => file,
    mode    => '0755',
    owner   => "${stack_user}",
    group   => "${stack_user}",
    content => template('translation_checksite/zanata-sync.sh.erb'),
    force   => true,
  }

  file {"/home/${stack_user}/update-lang-list.py":
    ensure  => file,
    mode    => '0755',
    owner   => "${stack_user}",
    group   => "${stack_user}",
    source  => 'puppet:///modules/translation_checksite/update-lang-list.py',
    force   => true,
  }

  cron { 'zanata-sync':
    ensure      => present,
    environment => 'PATH=/bin:/usr/bin:/usr/local/bin',
    command     => "/home/${stack_user}/zanata-sync.sh",
    user        => "${stack_user}",
    hour        => "${sync_hour}",
    minute      => "${sync_minute}",
  }

  if ($shutdown == 1) {
    exec { "unstack_devstack":
      cwd       => $devstack_dir,
      path      => '/bin:/usr/bin:/usr/local/bin',
      command   => "/bin/su ${stack_user} -c ${devstack_dir}/unstack.sh &",
      timeout   => 600,
      logoutput => true
    }
    ->
    exec { "clean_devstack":
      cwd       => $devstack_dir,
      path      => '/bin:/usr/bin:/usr/local/bin',
      command   => "/bin/su ${stack_user} -c ${devstack_dir}/clean.sh &",
      unless    => "/bin/ps aux | /usr/bin/pgrep stack",
      timeout   => 300,
      logoutput => true
    }
  }

  if ($restack == 1) {
    cron { 'devstack-restack':
      ensure      => present,
      environment => 'PATH=/bin:/usr/bin:/usr/local/bin',
      command     => "cd ${devstack_dir}; ./unstack.sh && ./stack.sh",
      user        => "${stack_user}",
      hour        => "${restack_hour}",
      minute      => "${restack_minute}",
    }
  }
}
