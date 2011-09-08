require 'socket'
module TinyAPNS
    class Message
    attr_accessor :token, :alert, :badge, :sound, :params

    def apple_hash
      result = {}
      result['aps'] = {}
      result['aps']['alert'] = self.alert if self.alert
      result['aps']['badge'] = self.badge.to_i if self.badge
      if self.sound
        result['aps']['sound'] = self.sound if self.sound.is_a? String
        result['aps']['sound'] = "1.aiff" if self.sound.is_a?(TrueClass)
      end
      if self.params
        self.params.each do |key,value|
          result[key.to_s] = value.to_s
        end
      end
      result
    end

    def to_apple_json
      self.apple_hash.to_json
    end

    def get_hex_token
      [self.token.delete(' ')].pack('H*')
    end

    def to_post_string
      json = self.to_apple_json
      message = "\0\0 #{get_hex_token}\0#{json.length.chr}#{json}"
      raise ArgumentError.new("Total message size too long: #{message}") if message.size.to_i > 256
      message
    end

    def send(connection)
      raise ArgumentError.new("Missing token") if self.token.blank?
      connection.open_for_delivery do |ssl|
        ssl.write(self.to_post_string)
      end
    end
  end

  class Feedback
    def devices(conn, &block)
      devices = []

      conn.open_for_feedback do |ssl|
        while line = ssl.read(38)   # Read 38 bytes from the SSL socket
          feedback = line.unpack('N1n1H140')
          token = feedback[2].scan(/.{0,8}/).join('').strip
          devices << {:token=>token, :feedback=>feedback[0]}
          yield(token, feedback[0]) if block_given?
        end
      end
      return devices
    end # devices
  end

  class Connection
    def initialize(options)
      options.assert_valid_keys(:cert, :port, :host, :passphrase, :feedback_host, :gateway_host)
      @options=options.with_indifferent_access
    end

    def open_for_delivery(options = {}, &block)
      local_options=get_options(:gateway, options)
      open(local_options, &block)
    end

    def open_for_feedback(options = {}, &block)
      local_options=get_options(:feedback, options)
      open(local_options, &block)
    end

    private
    def get_options(mode, options={})
      raise ArgumentError.new("Invalid mode, valid options are :gateway,:feedback") unless [:gateway, :feedback].include?(mode)
      raise ArgumentError.new("Missing option :cert") unless options.has_key?(:cert) || @options.has_key?(:cert)

      default_options={:passphrase=>''}
      host_suffix="push.apple.com"
      host_suffix="sandbox.#{host_suffix}" unless Rails.env.downcase=='production'

      default_options[:host]=@options["#{mode}_host"] if @options.has_key?("#{mode}_host")
      default_options[:host]||="#{mode.to_s}.#{host_suffix}"

      default_options[:port]=(mode==:gateway ? 2195 : 2196)

      result=default_options.merge(@options.except(:feedback_host, :gateway_host)).merge(options)
      puts result.inspect

      return result.with_indifferent_access
    end


    def open(options = {}, &block) # :nodoc:
      cert = File.read(options[:cert])
      ctx = OpenSSL::SSL::SSLContext.new
      ctx.key = OpenSSL::PKey::RSA.new(cert, options[:passphrase])
      ctx.cert = OpenSSL::X509::Certificate.new(cert)

      sock = TCPSocket.new(options[:host], options[:port])
      ssl = OpenSSL::SSL::SSLSocket.new(sock, ctx)
      ssl.sync = true
      ssl.connect

      yield ssl if block_given?

      ssl.close
      sock.close
    end

  end
end
