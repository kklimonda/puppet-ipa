define ipa::hostadd (
  $host     = $name,
  $otp      = {},
  $desc     = {},
  $clientos = {},
  $clientpf = {},
  $locality = {},
  $location = {}
) {

  $timestamp = strftime("%a %b %d %Y %r")
  $descinfo = rstrip(join(['Added by HUIT IPA Puppet module on',$timestamp,$desc], " "))

  if $::ipa_adminhomedir and is_numeric($::ipa_adminuidnumber) {
    @@ipa::clientinstall { $host:
      masterfqdn => $::fqdn,
      domain     => $ipa::master::domain,
      realm      => $ipa::master::realm,
      otp        => '',
      mkhomedir  => '',
      ntp        => ''
    }

    exec { "hostadd-${host}":
      command   => "/sbin/runuser -l admin -c \'/usr/bin/ipa host-add ${host} --locality=\"${locality}\" --location=\"${location}\" --desc=\"${descinfo}\" --platform=\"${clientpf}\" --os=\"${clientos}\" --password=${otp} --force\'",
      unless    => "/sbin/runuser -l admin -c \'/usr/bin/ipa host-show ${host} >/dev/null 2>&1\'",
      tries     => '60',
      try_sleep => '60'
    }
  }
}
