# coding: utf-8

require "ostruct"

module OrcaApi
  # 日レセAPIの呼び出し結果を扱うクラス
  class Result
    def self.json_name_to_attr_name(name)
      name
        .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
        .gsub(/([a-z\d])([A-Z])/, '\1_\2')
        .downcase
    end

    def self.json_attr_reader(*names)
      names.map(&:to_s).each do |name|
        attr_name = json_name_to_attr_name(name)
        define_method(attr_name) do
          @body[name]
        end
      end
    end

    def self.trim_response(hash)
      result = {}
      hash.each do |k, v|
        case v
        when Hash
          result[k] = trim_response(v)
        when Array
          found = false
          v.reverse.each do |v2|
            if !v2.empty?
              found = true
            end
            if found
              result[k] ||= []
              result[k].unshift(trim_response(v2))
            end
          end
        else
          result[k] = v
        end
      end
      result
    end

    attr_reader :raw, :body

    def initialize(raw)
      @raw = self.class.trim_response(raw)
      @body = @raw.first[1]
      @attr_names = @body.keys.map { |key|
        [self.class.json_name_to_attr_name(key).to_sym, key]
      }.to_h
    end

    def ok?
      /\A0+\z/ =~ api_result ? true : false
    end

    def locked?
      api_result == "E90"
    end

    def message
      "#{api_result_message}(#{api_result})"
    end

    def method_missing(symbol, *_)
      if (key = @attr_names[symbol])
        @body[key]
      else
        super
      end
    end

    def respond_to_missing?(symbol, _)
      if @attr_names.key?(symbol)
        true
      else
        super
      end
    end
  end
end
