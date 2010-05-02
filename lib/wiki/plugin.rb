# -*- coding: utf-8 -*-
require 'wiki/util'

module Wiki
  # Wiki plugin system
  class Plugin
    include Util

    @plugins = {}
    @failed = []
    @dir = ''
    @logger = nil

    class<< self
      attr_accessor :dir, :logger

      # Current loading plugin
      def current
        file = Kernel.caller.each do |line|
          return @plugins[$1] if line =~ %r{^#{@dir}/(.+?)\.rb}
        end
        raise RuntimeError, 'No plugin context'
      end

      # Get plugin by name
      def [](name)
        @plugins[name.to_s]
      end

      # Get all plugins
      def plugins
        @plugins.values
      end

      # Get failed plugins
      def failed
        @failed
      end

      # Start plugins
      def start
        @plugins.each_value {|plugin| plugin.start }
      end

      # Load plugins by name and return a boolean for success
      def load(*list)
        files = list.map do |name|
          name = name.cleanpath
          Dir.glob(File.join(@dir, '**', "#{name}.rb"))
        end.flatten
        return false if files.empty?
        files.inject(true) do |result,file|
          name = file[(@dir.size+1)..-4]
          if @failed.include?(name) || @plugins.include?(name)
	    result
	  elsif !enabled?(name)
	    false
	  else
            begin
	      plugin = new(name, file, logger)
              @plugins[name] = plugin
              plugin.instance_eval(File.read(file), file)
              I18n.load_locale(file.sub(/\.rb$/, '_locale.yml'))
              I18n.load_locale(File.join(File.dirname(file), 'locale.yml'))
              Templates.paths << File.dirname(file)
              logger.debug("Plugin #{name} successfully loaded")
            rescue Exception => ex
              @failed << name
              logger.error ex
              @plugins.delete(name)
              false
            end
	  end
        end
      end

      # Check if plugin is enabled
      def enabled?(name)
        paths = name.split(File::SEPARATOR)
        paths.inject(nil) do |path, x|
          path = path ? File.join(path, x) : x
          return false if Config.disabled_plugins.to_a.include?(path)
          path
        end
        true
      end
    end

    attr_reader :name, :file, :started
    attr_setter :author, :description, :logger

    def initialize(name, file, logger)
      @name = name
      @file = file
      @logger = logger
      @setup = nil
      @started = false
    end

    # Add setup method
    def setup(&block)
      @setup = block
    end

    # Start the plugin
    def start
      return true if @started
      instance_eval(&@setup) if @setup
      Plugin.logger.debug("Plugin #{name} successfully started")
      @started = true
    rescue Exception => ex
      Plugin.logger.error ex
      Plugin.logger.error("Plugin #{name} failed to start")
      false
    end

    # Load specified plugins and fail if
    # dependencies are missing.
    def dependencies(*list)
      @dependencies ||= []
      @dependencies += list
      list.each do |dep|
        if dep =~ /^gem:\s*(.*)\s*$/
          dep = $1.split(/\s+/)
          raise(ArgumentError, 'Invalid gem specification') if dep.length < 1
          name = dep[0]
          version = dep.length > 1 ? dep[1..-1].join(' ') : '>= 0'
          gem name, version
        else
          raise(RuntimeError, "Could not load dependency #{dep} for #{name}") if !Plugin.load(dep)
        end
      end
      @dependencies
    end

    private_class_method :new

  end
end
