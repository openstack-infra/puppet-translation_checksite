Translation_checksite for testing translations against DevStack
===============================================================

This puppet module provides environment for check translation in OpenStack

Features
--------
- Install and Configure DevStack
- Install Cron for Zanata Sync

Requirements
------------

For usage devstack git repo:

https://git.openstack.org/cgit/openstack-infra/puppet-vcsrepo/

For installing Zanata Client:

https://github.com/puppetlabs/puppetlabs-java_ks.git

https://git.openstack.org/openstack-infra/puppet-zanata/


Prerequisites for installing Zanata CLI
---------------------------------------

    class {'zanata::client':
      version        => '1.2.3',
      user           => 'stack',
      group          => 'stack',
      server         => 'openstack',
      server_url     => 'https://zanata.example.org:443',
      server_user    => 'user',
      server_api_key => '12345',
      homedir        => '/home/stack/',
    }

Usage
-----

Install DevStack without any plugins:

    class {'translation_checksite':
      minimal           => 1,                                # no extra plugins loaded
      server_url        => 'https://zanata.example.org:443', # from where to fetch translation files
      revision          => 'master',                         # used branch in DevStack Repo
      project_version   => 'master',                         # used version in Zanata Project
    }

Install DevStack with parameter:

    class {'translation_checksite':
      zanata_cli        => '/opt/zanata/zanata-cli-3.8.1/bin/zanata-cli',
      server_url        => 'https://zanata.example.org:443',
      devsstack_dir     => '/home/stack/devstack',
      stack_user        => 'stack',
      revision          => 'master',
      project_version   => 'master',
      admin_password    => '12345678',
      database_password => '12121212',
      rabbit_password   => '34343434',
      service_password  => '56565656',
      service_token     => '78787878787878',
      swift_hash        => '78787878787878',
      sync_hour         => 18,
      sync_minute       => 30,
      restack           => 1, # refresh DevStack installation
      restack_hour      => 18,
      restack_minute    => 00,
    }

Deinstall DevStack:

    class {'translation_checksite':
      devsstack_dir     => '/home/stack/devstack',
      stack_user        => 'stack',
      shutdown          => 1, # this stops DevStack and deletes the installation
    }

Note: Developed for Ubuntu 14.04 LTS
