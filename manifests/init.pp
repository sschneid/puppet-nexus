class nexus (
  $source  = 'http://www.sonatype.org/downloads',
  $dest    = '/var/www',
  $version = 'latest',
) {
  $source_url = "${source}/nexus-${version}-bundle.tar.gz"

  include apache
  include java

  apache::port { 'nexus-proxy': port => '80' }

  apache::vhost::proxy { 'nexus-proxy':
    serveraliases => 'nexus-proxy',
    port          => 80,
    dest          => 'http://localhost:8081',
  }

  file { $dest:
    ensure  => 'directory',
    recurse => 'true'
  }

  exec { 'nexus-download':
    command => "curl -v --progress-bar -o '/tmp/nexus-${version}-bundle.tar.gz' '${source_url}'",
    cwd     => '/tmp',
    path    => [ '/bin', '/usr/bin' ],
    creates => "/tmp/nexus-${version}-bundle.tar.gz",
    unless  => "test -d ${dest}/nexus-${version}"
  }

  exec { 'nexus-extract':
    command   => "tar -C ${dest} -zxvf /tmp/nexus-${version}-bundle.tar.gz",
    cwd       => '/tmp',
    path      => [ '/bin', '/usr/bin' ],
    creates   => "${dest}/nexus-${version}",
    subscribe => Exec[ 'nexus-download' ],
    require   => Exec[ 'nexus-download' ]
  }

  file { '/etc/init.d/nexus':
    ensure => 'link',
    target => "${dest}/nexus-${version}/bin/nexus"
  }

  service { 'nexus':
    ensure => 'running',
    enable => 'true'
  }
}

