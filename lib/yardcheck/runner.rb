# frozen_string_literal: true

module Yardcheck
  class Runner
    include Concord.new(:observations, :output)

    def self.run(args)
      options = { rspec: 'spec' }

      parser =
        OptionParser.new do |opt|
          opt.on('--namespace NS', 'Namespace to check documentation for and watch methods calls for') do |arg|
            options[:namespace] = arg
          end

          opt.on('--include PATH', 'Path to add to load path') do |arg|
            options[:include] = arg
          end

          opt.on('--require LIB', 'Library to require') do |arg|
            options[:require] = arg
          end

          opt.on('--rspec ARGS', 'Arguments to give to rspec') do |arg|
            options[:rspec] = arg
          end
        end

      parser.parse(args)

      namespace, include_path, require_target, rspec = arguments = options.fetch_values(:namespace, :include, :require, :rspec)

      fail 'All arguments are required' if arguments.any?(&:nil?)

      $LOAD_PATH.unshift(include_path)
      require require_target

      rspec = rspec.split(' ')

      observations =
        Yardcheck::SpecObserver
          .run(rspec, namespace)
          .associate_with(Yardcheck::Documentation.parse)

      new(observations, $stderr)
    end

    def check
      observations
        .flat_map(&:violations)
        .uniq
        .compact
        .map(&:warning)
        .each(&method(:warn))
    end

    private

    def warn(message)
      output.puts(message)
    end
  end # Runner
end # Yardcheck
