# @api private
# @summary
#   This class add ssh client management
#
# @example Puppet usage
#   class { 'ssh::client':
#     ensure               => present,
#     storeconfigs_enabled => true,
#     use_augeas           => false,
#   }
#
# @param ensure
#   Ensurable param to ssh client
#
# @param storeconfigs_enabled
#   Collected host keys from servers will be written to known_hosts unless storeconfigs_enabled is false
#
# @param options
#   Dynamic hash for openssh client options
#
# @param options_absent
#   Remove options (with augeas style)
#
class ssh::client (
  String  $ensure               = present,
  Boolean $storeconfigs_enabled = true,
  Hash    $options              = {},
  Boolean $use_augeas           = false,
  Array   $options_absent       = [],
) {
  assert_private()

  if $use_augeas {
    $merged_options = sshclient_options_to_augeas_ssh_config($options, $options_absent, { 'target' => $ssh::ssh_config })
  } else {
    $merged_options = $options
  }

  include ssh::client::install
  include ssh::client::config

  # Provide option to *not* use storeconfigs/puppetdb, which means not managing
  #  hostkeys and knownhosts
  if ($storeconfigs_enabled) {
    include ssh::knownhosts

    Class['ssh::client::install']
    -> Class['ssh::client::config']
    -> Class['ssh::knownhosts']
  } else {
    Class['ssh::client::install']
    -> Class['ssh::client::config']
  }
}
