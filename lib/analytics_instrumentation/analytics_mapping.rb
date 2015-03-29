class AnalyticsMapping
  def self.createMappings
    # TODO: Reload this on Rails Auto-reload
    mappings = {}
    @mappingFiles = Dir.glob("config/analytics/*.yml")
    for file in @mappingFiles
      yaml = YAML.load_file(file)
      mappings.merge! yaml
    end
    mappings
  end

  @@mappings = AnalyticsMapping.createMappings

  def self.to_event(params, view_assigns)
    methodName = "#{params[:controller]}##{params[:action]}"
    analysis = @@mappings[methodName]

    return nil if analysis.nil?

    replaceAllTokens(analysis, params, view_assigns)

    analysis
  end

  def self.replaceAllTokens(obj, params, view_assigns)
    if obj.is_a? String
      replaceTokens(obj, params, view_assigns)
    elsif obj.is_a? Hash
      obj.each {|k, v| replaceAllTokens(v, params, view_assigns)}
    end
  end

  def self.replaceTokens(str, params, view_assigns)
    return if str["@"].nil? && str["params["].nil?
    properties = {}
    view_assigns.each {|k, v| properties.instance_variable_set "@#{k}", v}
    properties["params"] = params
    result = ERB.new("<%= #{str} %>").result(properties.instance_eval {binding})
    str[0..-1] = result
  end
end
