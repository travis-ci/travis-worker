class Hash
  def deep_symbolize_keys
    inject({}) { |result, (key, value)|
      value = value.deep_symbolize_keys if value.is_a?(Hash)
      result[(key.to_sym rescue key) || key] = value
      result
    }
  end unless Hash.method_defined?(:deep_symbolize_keys)
end
