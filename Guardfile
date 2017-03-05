# frozen_string_literal: true

require 'concord'

module RSpecGuard
  # Define an RSpec group for the specified path
  def self.group(dsl, path)
    dsl.group(path) { define(dsl, path) }
  end

  # Define a guard for an RSpec path
  def self.define(dsl, path)
    dsl.guard :rspec, spec_paths: [path], cmd: 'bundle exec rspec' do
      # Run all specs when spec_helper.rb changes
      dsl.watch('spec/spec_helper.rb')       { path }

      # Run all specs when a spec support file changes
      dsl.watch(%r{^spec/support/(.+)\.rb$}) { path }

      # When a spec file is changed run it
      dsl.watch(%r{^spec/.+_spec\.rb$})

      # Match all ruby files not in the spec directory
      dsl.watch(%r{\Alib/(.+)\.rb\z}, &method(:expand_match))
    end
  end
  private_class_method(:define)

  def self.expand_match(guard_matches)
    mapping = Mapping.new(guard_matches)

    warn mapping.no_match_report if mapping.files.empty?

    mapping.files
  end
  private_class_method(:expand_match)

  class Mapping
    include Concord.new(:match_result)

    GLOB_TEMPLATE = 'spec/unit/%{match}{/**/*,}_spec.rb'

    def self.yellow(text)
      "\e[0;33;49m#{text}\e[0m"
    end
    private_class_method(:yellow)

    REPORT_TEMPLATE = <<~REPORT
      Detected a file change for #{yellow('%<source_file>s')}
      Searched for tests matching #{yellow('%<spec_file_glob>s')}
      No matches found
    REPORT

    REPORTED_ATTRIBUTES = %i[source_file spec_file_glob files].freeze

    def files
      Dir[spec_file_glob]
    end

    def no_match_report
      format(REPORT_TEMPLATE, report_details)
    end

    private

    def source_file
      match_result[0]
    end

    def captured_path
      match_result[1]
    end

    def spec_file_glob
      format(GLOB_TEMPLATE, match: captured_path)
    end

    def report_details
      values =
        REPORTED_ATTRIBUTES.map do |attribute|
          __send__(attribute).inspect
        end

      REPORTED_ATTRIBUTES.zip(values).to_h
    end
  end # Mapping
  private_constant(*constants(false))
end # RSpecGuard

# Collect all spec directories with tests inside (spec/unit, spec/integration, etc)
spec_groups = Pathname.glob('spec/**/*_spec.rb').map { |path| path.descend.to_a[1].to_s }.uniq

# By default Guard will ignore improperly specified group names and silently run all groups
# instead. This checks if any groups were specified and validates them
Guard.state.session.cmdline_groups.each do |specified_group|
  next if spec_groups.include?(specified_group)

  fail "Unknown group specified: #{specified_group.inspect}! Supported groups: #{spec_groups}"
end

# Define a custom group for each test directory within spec/
spec_groups.each { |group_path| RSpecGuard.group(self, group_path) }
