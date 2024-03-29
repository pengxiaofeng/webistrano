@spec = Gem::Specification.new do |s|
	s.name = "net-ssh"
  s.rubyforge_project = 'net-ssh'
	s.version = "2.0.15"
	s.summary = "Net::SSH: a pure-Ruby implementation of the SSH2 client protocol."
	s.description = s.summary
	s.authors = ["Jamis Buck", "Delano Mandelbaum"]
	s.email = ["net-ssh@solutious.com", "net-ssh@solutious.com"]
	s.homepage = "http://rubyforge.org/projects/net-ssh/"
  
  s.extra_rdoc_files = %w[README.rdoc THANKS.rdoc CHANGELOG.rdoc]
  s.has_rdoc = true
  s.rdoc_options = ["--line-numbers", "--title", s.summary, "--main", "README.rdoc"]
  s.require_paths = %w[lib]
  s.rubygems_version = '1.3.2'
  
  s.executables = %w[]
  
  # = MANIFEST =
  s.files = %w(
  CHANGELOG.rdoc
  Manifest
  README.rdoc
  Rakefile
  Rudyfile
  THANKS.rdoc
  lib/net/ssh.rb
  lib/net/ssh/authentication/agent.rb
  lib/net/ssh/authentication/constants.rb
  lib/net/ssh/authentication/key_manager.rb
  lib/net/ssh/authentication/methods/abstract.rb
  lib/net/ssh/authentication/methods/hostbased.rb
  lib/net/ssh/authentication/methods/keyboard_interactive.rb
  lib/net/ssh/authentication/methods/password.rb
  lib/net/ssh/authentication/methods/publickey.rb
  lib/net/ssh/authentication/pageant.rb
  lib/net/ssh/authentication/session.rb
  lib/net/ssh/buffer.rb
  lib/net/ssh/buffered_io.rb
  lib/net/ssh/config.rb
  lib/net/ssh/connection/channel.rb
  lib/net/ssh/connection/constants.rb
  lib/net/ssh/connection/session.rb
  lib/net/ssh/connection/term.rb
  lib/net/ssh/errors.rb
  lib/net/ssh/key_factory.rb
  lib/net/ssh/known_hosts.rb
  lib/net/ssh/loggable.rb
  lib/net/ssh/packet.rb
  lib/net/ssh/prompt.rb
  lib/net/ssh/proxy/errors.rb
  lib/net/ssh/proxy/http.rb
  lib/net/ssh/proxy/socks4.rb
  lib/net/ssh/proxy/socks5.rb
  lib/net/ssh/ruby_compat.rb
  lib/net/ssh/service/forward.rb
  lib/net/ssh/test.rb
  lib/net/ssh/test/channel.rb
  lib/net/ssh/test/extensions.rb
  lib/net/ssh/test/kex.rb
  lib/net/ssh/test/local_packet.rb
  lib/net/ssh/test/packet.rb
  lib/net/ssh/test/remote_packet.rb
  lib/net/ssh/test/script.rb
  lib/net/ssh/test/socket.rb
  lib/net/ssh/transport/algorithms.rb
  lib/net/ssh/transport/cipher_factory.rb
  lib/net/ssh/transport/constants.rb
  lib/net/ssh/transport/hmac.rb
  lib/net/ssh/transport/hmac/abstract.rb
  lib/net/ssh/transport/hmac/md5.rb
  lib/net/ssh/transport/hmac/md5_96.rb
  lib/net/ssh/transport/hmac/none.rb
  lib/net/ssh/transport/hmac/sha1.rb
  lib/net/ssh/transport/hmac/sha1_96.rb
  lib/net/ssh/transport/identity_cipher.rb
  lib/net/ssh/transport/kex.rb
  lib/net/ssh/transport/kex/diffie_hellman_group1_sha1.rb
  lib/net/ssh/transport/kex/diffie_hellman_group_exchange_sha1.rb
  lib/net/ssh/transport/openssl.rb
  lib/net/ssh/transport/packet_stream.rb
  lib/net/ssh/transport/server_version.rb
  lib/net/ssh/transport/session.rb
  lib/net/ssh/transport/state.rb
  lib/net/ssh/verifiers/lenient.rb
  lib/net/ssh/verifiers/null.rb
  lib/net/ssh/verifiers/strict.rb
  lib/net/ssh/version.rb
  net-ssh.gemspec
  setup.rb
  support/arcfour_check.rb
  test/authentication/methods/common.rb
  test/authentication/methods/test_abstract.rb
  test/authentication/methods/test_hostbased.rb
  test/authentication/methods/test_keyboard_interactive.rb
  test/authentication/methods/test_password.rb
  test/authentication/methods/test_publickey.rb
  test/authentication/test_agent.rb
  test/authentication/test_key_manager.rb
  test/authentication/test_session.rb
  test/common.rb
  test/configs/eqsign
  test/configs/exact_match
  test/configs/multihost
  test/configs/wild_cards
  test/connection/test_channel.rb
  test/connection/test_session.rb
  test/test_all.rb
  test/test_buffer.rb
  test/test_buffered_io.rb
  test/test_config.rb
  test/test_key_factory.rb
  test/transport/hmac/test_md5.rb
  test/transport/hmac/test_md5_96.rb
  test/transport/hmac/test_none.rb
  test/transport/hmac/test_sha1.rb
  test/transport/hmac/test_sha1_96.rb
  test/transport/kex/test_diffie_hellman_group1_sha1.rb
  test/transport/kex/test_diffie_hellman_group_exchange_sha1.rb
  test/transport/test_algorithms.rb
  test/transport/test_cipher_factory.rb
  test/transport/test_hmac.rb
  test/transport/test_identity_cipher.rb
  test/transport/test_packet_stream.rb
  test/transport/test_server_version.rb
  test/transport/test_session.rb
  test/transport/test_state.rb
  )

  
end
