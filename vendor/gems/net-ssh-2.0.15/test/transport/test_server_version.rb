require 'common'
require 'net/ssh/transport/server_version'

module Transport

  class TestServerVersion < Test::Unit::TestCase

    def test_1_99_server_version_should_be_acceptible
      s = subject(socket(true, "SSH-1.99-Testing_1.0\r\n"))
      assert s.header.empty?
      assert_equal "SSH-1.99-Testing_1.0", s.version
    end

    def test_2_0_server_version_should_be_acceptible
      s = subject(socket(true, "SSH-2.0-Testing_1.0\r\n"))
      assert s.header.empty?
      assert_equal "SSH-2.0-Testing_1.0", s.version
    end

    def test_trailing_whitespace_should_be_preserved
      # some servers, like Mocana, send a version string with trailing
      # spaces, which are significant when exchanging keys later.
      s = subject(socket(true, "SSH-2.0-Testing_1.0    \r\n"))
      assert_equal "SSH-2.0-Testing_1.0    ", s.version
    end

    def test_unacceptible_server_version_should_raise_exception
      assert_raises(Net::SSH::Exception) { subject(socket(false, "SSH-1.4-Testing_1.0\r\n")) }
    end

    def test_header_lines_should_be_accumulated
      s = subject(socket(true, "Welcome\r\nAnother line\r\nSSH-2.0-Testing_1.0\r\n"))
      assert_equal "Welcome\r\nAnother line\r\n", s.header
      assert_equal "SSH-2.0-Testing_1.0", s.version
    end

    def test_server_disconnect_should_raise_exception
      assert_raises(Net::SSH::Disconnect) { subject(socket(false, "SSH-2.0-Aborting")) }
    end

    private

      def socket(good, version_header)
        socket = mock("socket")

        data = version_header.split('')
        recv_times = data.length
        if data[-1] != "\n"
            recv_times += 1
        end
        socket.expects(:recv).with(1).times(recv_times).returns(*data).then.returns(nil)

        if good
          socket.expects(:write).with("#{Net::SSH::Transport::ServerVersion::PROTO_VERSION}\r\n")
          socket.expects(:flush)
        else
          socket.expects(:write).never
        end

        socket
      end

      def subject(socket)
        Net::SSH::Transport::ServerVersion.new(socket, nil)
      end
  end

end
