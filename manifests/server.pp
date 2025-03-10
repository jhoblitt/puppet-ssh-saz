# @api private
# @summary
#   This class managed ssh server
#
# @example Puppet usage
#   class { 'ssh::server':
#     ensure               => present,
#     storeconfigs_enabled => true,
#     use_issue_net        => false,
#   }
#
# @param ensure
#   Ensurable param to ssh server
#
# @param storeconfigs_enabled
#   Host keys will be collected and distributed unless storeconfigs_enabled is false.
#
# @param options
#   Dynamic hash for openssh server option
#
# @param validate_sshd_file
#   Add sshd file validate cmd
#
# @param use_augeas
#   Use augeas for configuration (default concat)
#
# @param options_absent
#   Remove options (with augeas style)
#
# @param match_block
#   Add sshd match_block (with concat)
#
# @use_issue_net
#   Add issue_net banner
#
class ssh::server (
  String  $ensure               = present,
  Boolean $storeconfigs_enabled = true,
  Hash    $options              = {},
  Boolean $validate_sshd_file   = false,
  Boolean $use_augeas           = false,
  Array   $options_absent       = [],
  Hash    $match_block          = {},
  Boolean $use_issue_net        = false
) {
  assert_private()

  if $use_augeas {
    $merged_options = sshserver_options_to_augeas_sshd_config($options, $options_absent, { 'target' => $ssh::sshd_config })
  } else {
    $merged_options = $options
  }

  include ssh::server::install
  include ssh::server::config
  include ssh::server::service

  # Provide option to *not* use storeconfigs/puppetdb, which means not managing
  #  hostkeys and knownhosts
  if ($storeconfigs_enabled) {
    include ssh::hostkeys
    include ssh::knownhosts

    Class['ssh::server::install']
    -> Class['ssh::server::config']
    ~> Class['ssh::server::service']
    -> Class['ssh::hostkeys']
    -> Class['ssh::knownhosts']
  } else {
    Class['ssh::server::install']
    -> Class['ssh::server::config']
    ~> Class['ssh::server::service']
  }

  create_resources('ssh::server::match_block', $match_block)
}
