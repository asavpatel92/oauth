require 'oauth/signature'
require 'oauth/request_proxy/base'
require 'base64'

module OAuth::Signature
  class Base

    def self.implements(signature_method)
      OAuth::Signature.available_methods[signature_method] = self
    end

    def self.digest_class(digest_class = nil)
      return @digest_class if digest_class.nil?
      @digest_class = digest_class
    end

    attr_reader :token_secret, :consumer_secret, :request

    def initialize(request, &block)
      raise TypeError unless request.kind_of?(OAuth::RequestProxy::Base)
      @request = request
      @token_secret, @consumer_secret = yield block.arity == 1 ? token : [token, consumer_key]
    end

    def signature
      Base64.encode64(digest).chomp
    end

    def ==(cmp_signature)
      Base64.decode64(signature) == Base64.decode64(cmp_signature)
    end

    def verify
      self == self.request.signature
    end

    def signature_base_string
      normalized_params = request.parameters_for_signature.sort.map { |k,v| [k,v] * "=" }.join("&")
      base = [request.method, request.uri, normalized_params]
      base.map { |v| escape(v) }.join("&")
    end

    private

    def token
      request.token
    end
    
    def consumer_key
      request.consumer_key
    end

    def secret
      "#{escape(consumer_secret)}&#{escape(token_secret)}"
    end

    def digest
      self.class.digest_class.digest(signature_base_string)
    end

    def escape(value)
      CGI.escape(value.to_s).gsub("%7E", '~')
    end
  end
end
