define ipa::adminconfig (
  $host  = $name,
  $realm = {}
) {

  if $::ipa_adminhomedir and is_numeric($::ipa_adminuidnumber) {
    k5login { "${::ipa_adminhomedir}/.k5login":
      principals => $ipa::master::principals,
      notify     => File["${::ipa_adminhomedir}/.k5login"],
      require    => File["${::ipa_adminhomedir}"]
    }

    $kadminlocalcmd = shellquote('/usr/sbin/kadmin.local','-q',"ktadd -norandkey -k admin.keytab admin")
    exec { "admin_keytab":
      command => "$kadminlocalcmd > /dev/null 2>&1",
      cwd     => "${::ipa_adminhomedir}",
      unless  => shellquote('/usr/bin/kvno','-c',"/tmp/krb5cc_${::ipa_adminuidnumber}",'-k',"${::ipa_adminhomedir}/admin.keytab","admin@${realm}"),
      notify  => [
        File["${::ipa_adminhomedir}/admin.keytab"],
        Exec['k5start_admin_exec'],
      ],
      require => Cron["k5start_admin"]
    }

    exec { 'k5start_admin_exec':
      command     => "/usr/bin/k5start -f ${::ipa_adminhomedir}/admin.keytab -U > /dev/null 2>&1",
      environment => ["KRB5CCNAME=KEYRING:persistent:$::ipa_adminuidnumber"],
      user        => 'admin',
      refreshonly => true,
    }

    cron { "k5start_admin":
      command => "/usr/bin/k5start -f ${::ipa_adminhomedir}/admin.keytab -U > /dev/null 2>&1",
      user    => 'admin',
      minute  => "*/10",
      require => [Package["kstart"], K5login["${::ipa_adminhomedir}/.k5login"], File["$::ipa_adminhomedir"]]
    }

    file { "$::ipa_adminhomedir":
      ensure  => directory,
      mode    => '700',
      owner   => $::ipa_adminuidnumber,
      group   => $::ipa_adminuidnumber,
      recurse => true,
      notify  => Exec["admin_keytab"],
      require => Exec["serverinstall-${host}"]
    }

    file { "${::ipa_adminhomedir}/.k5login":
      owner   => $::ipa_adminuidnumber,
      group   => $::ipa_adminuidnumber,
      require => File[$::ipa_adminhomedir]
    }

    file { "${::ipa_adminhomedir}/admin.keytab":
      owner   => $::ipa_adminuidnumber,
      group   => $::ipa_adminuidnumber,
      mode    => '600',
      require => File[$::ipa_adminhomedir]
    }
  }
}
