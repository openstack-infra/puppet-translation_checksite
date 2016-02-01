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
# Minimal DevStack installation with default configuration
#
# [*zanata_cli*]
# Location of Zanata Client
#
# [*stack_user*]
# Unix user of DevStack installation
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

class translation_checksite (
  $devstack_dir        = '/home/stack/devstack',
  $minimal             = undef,
  $zanata_cli          = '/opt/zanata/zanata-cli-3.8.1/bin/zanata-cli',
  $zanata_url          = undef,
  $stack_user          = 'stack',
  $revision            = 'master',
  $project_version     = 'master',
  $admin_password      = undef,
  $database_password   = undef,
  $rabbit_password     = undef,
  $service_password    = undef,
  $service_token       = undef,
  $swift_hash          = undef,
  $sync_hour           = 1,
  $sync_minute         = 0,
  $shutdown            = undef,
  $restack             = undef,
  $restack_hour        = 0,
  $restack_minute      = 0,
  $devstack_ssh_pubkey = undef,
) {

  user { $stack_user:
    ensure     => present,
    groups     => $stack_user,
    comment    => 'Stack User',
    managehome => true,
    shell      => '/bin/bash',
    password   => '*',
    require    => Group[$stack_user]
  }

  group { $stack_user:
    ensure     => present,
  }

  file {"/home/${stack_user}/.config":
    ensure  => directory,
    owner   => $stack_user,
    group   => $stack_user,
    require => [User[$stack_user],Group[$stack_user]]
  }

  ssh_authorized_key {'i18n project team':
    ensure  => present,
    type    => 'ssh-rsa',
    key     => $devstack_ssh_pubkey,
    user    => $stack_user,
    require => User[$stack_user],
  }

  package {'sudo':
    ensure => 'present',
  }

  file {'/etc/sudoers.d/10-stack-devstack':
    ensure  => file,
    mode    => '0600',
    content => "${stack_user} ALL=(root) NOPASSWD:ALL\n",
    require => Package['sudo'],
  }

  vcsrepo { $devstack_dir:
    ensure   => present,
    provider => git,
    owner    => $stack_user,
    group    => $stack_user,
    source   => 'https://git.openstack.org/openstack-dev/devstack.git',
    revision => $revision,
  }

  if ($minimal == 1) {
    file {"${devstack_dir}/local.conf":
      ensure  => file,
      mode    => '0600',
      owner   => $stack_user,
      group   => $stack_user,
      content => template('translation_checksite/local.conf.minimal.erb'),
      force   => true,
      require => [ Vcsrepo[$devstack_dir] ],
    }
  } else {
    file {"${devstack_dir}/local.conf":
      ensure  => file,
      mode    => '0600',
      owner   => $stack_user,
      group   => $stack_user,
      content => template('translation_checksite/local.conf.erb'),
      force   => true,
      require => [ Vcsrepo[$devstack_dir] ],
    }
  }

  exec { 'run_devstack':
    cwd       => $devstack_dir,
    command   => "/bin/su ${stack_user} -c ${devstack_dir}/stack.sh",
    unless    => ['/bin/ps aux | /usr/bin/pgrep stack 2>/dev/null',
                  '/usr/bin/test -d /opt/stack/'],
    timeout   => 3600,
    require   => [ Vcsrepo[$devstack_dir], File["${devstack_dir}/local.conf"] ],
    logoutput => true
  }

  file {"/home/${stack_user}/zanata.xml":
    ensure  => file,
    mode    => '0644',
    owner   => $stack_user,
    group   => $stack_user,
    content => template('translation_checksite/zanata.xml.erb'),
    force   => true,
  }

  file {"/home/${stack_user}/zanata-sync.sh":
    ensure  => file,
    mode    => '0755',
    owner   => $stack_user,
    group   => $stack_user,
    content => template('translation_checksite/zanata-sync.sh.erb'),
    force   => true,
  }

  file {"/home/${stack_user}/update-lang-list.py":
    ensure => file,
    mode   => '0755',
    owner  => $stack_user,
    group  => $stack_user,
    source => 'puppet:///modules/translation_checksite/update-lang-list.py',
    force  => true,
  }

  cron { 'zanata-sync':
    ensure      => present,
    environment => 'PATH=/bin:/usr/bin:/usr/local/bin',
    command     => "/home/${stack_user}/zanata-sync.sh",
    user        => $stack_user,
    hour        => $sync_hour,
    minute      => $sync_minute,
  }

  if ($shutdown == 1) {
    exec { 'unstack_devstack':
      cwd       => $devstack_dir,
      path      => '/bin:/usr/bin:/usr/local/bin',
      command   => "/bin/su ${stack_user} -c ${devstack_dir}/unstack.sh",
      creates   => "${devstack_dir}/shutdown.puppet",
      timeout   => 600,
      logoutput => true
    }
    ->
    exec { 'clean_devstack':
      cwd       => $devstack_dir,
      path      => '/bin:/usr/bin:/usr/local/bin',
      command   => "/bin/su ${stack_user} -c ${devstack_dir}/clean.sh",
      unless    => '/bin/ps aux | /usr/bin/pgrep stack',
      timeout   => 300,
      logoutput => true
    }
  }

  if ($restack == 1) {
    cron { 'devstack-restack':
      ensure      => present,
      environment => 'PATH=/bin:/usr/bin:/usr/local/bin',
      command     => "${devstack_dir}/unstack.sh && ${devstack_dir}/stack.sh",
      user        => $stack_user,
      hour        => $restack_hour,
      minute      => $restack_minute,
    }
  }
}
