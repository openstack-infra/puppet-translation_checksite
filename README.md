Translation_checksite for OpenStack I18N
========================================

This puppet module provides environment for check translation in OpenStack

Features
--------
- Install and Configure DevStack
- Install Cron for Zanata Sync

Requirements
------------

For usage devstack git repo:

https://github.com/puppetlabs/puppetlabs-vcsrepo

For installing Zanata Client:

https://github.com/puppetlabs/puppetlabs-java_ks.git

https://git.openstack.org/openstack-infra/puppet-zanata


Prerequisites for installing Zanata CLI
---------------------------------------

    user { "ubuntu":
      ensure     => 'present',
      uid        => 1000,
      groups     => 'ubuntu',
      comment    => "Ubuntu User",
      managehome => false,
      shell      => '/bin/bash',
      password   => '*',
    }
    ->
    file { '/home/ubuntu/.config':
      ensure  => directory,
    }
    class {'zanata::client':
      version        => '3.8.1',
      user           => 'ubuntu',
      group          => 'ubuntu',
      server         => 'openstack',
      server_url     => 'https://translate.openstack.org:443',
      server_user    => 'user',
      server_api_key => '12345',
      homedir        => '/home/ubuntu/',
    }

Usage
-----

Install DevStack without any plugins:

    class {'translation_checksite':
      minimal           => 1,                 # no extra plugins loaded
      revision          => "stable/liberty",  # used branch in DevStack Repo
      project_version   => "stable-liberty",  # used version in Zanata Project
    }

Install DevStack with parameter:

    class {'translation_checksite':
      zanata_cli        => "/opt/zanata/zanata-cli-3.8.1/bin/zanata-cli",
      devsstack_dir     => "/home/ubuntu/devstack2",
      stack_user        => "ubuntu",
      revision          => "master",
      project_version   => "master",
      admin_password    => "12345678",
      database_password => "12121212",
      rabbit_password   => "34343434",
      service_password  => "56565656",
      service_token     => "78787878787878",
      swift_hash        => "78787878787878",
      sync_hour         => 18,
      sync_minute       => 30,
      restack           => 1, # refresh DevStack installation
      restack_hour      => 18,
      restack_minute    => 00,
    }

Deinstall DevStack:

    class {'translation_checksite':
      devsstack_dir     => "/home/ubuntu/devstack2",
      stack_user        => "ubuntu",
      shutdown          => 1, # this stops DevStack and deletes the installation
    }

Note: Developed for Ubuntu 14.04 LTS
