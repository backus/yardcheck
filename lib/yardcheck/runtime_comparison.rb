# frozen_string_literal: true

module Yardcheck
  class RuntimeComparison
    include Concord.new(:documentation, :spec_observation), Adamantium::Flat

    def invalid_returns
      each_return do |documentation, observation, documented_return|
        observation
          .to_enum(:invalid_returns, documented_return)
          .flat_map do |observed_return|
            Violation::Return.new(documentation, observation, observed_return)
          end
      end
    end

    def invalid_params
      each_param do |documentation, observation, documented_params|
        documented_params.flat_map do |name, typedef|
          observation
            .to_enum(:invalid_param_usage, name, typedef)
            .flat_map do |observed_param|
              Violation::Param.new(
                documentation:  documentation,
                observation:    observation,
                param_name:     name,
                observed_value: observed_param
              )
            end
        end
      end.flatten
    end

    private

    def each_param
      comparable_method_identifiers.map do |method_identifier|
        observation   = observation_for(method_identifier)
        documentation = documentation_for(method_identifier)

        yield(documentation, observation, documentation.params)
      end
    end

    def each_return
      comparable_method_identifiers.flat_map do |method_identifier|
        observation   = observation_for(method_identifier)
        documentation = documentation_for(method_identifier)

        yield(documentation, observation, documentation.return_type)
      end
    end

    def observation_for(identifier)
      observation_table.fetch(identifier)
    end

    def documentation_for(identifier)
      documentation_table.fetch(identifier)
    end

    def comparable_method_identifiers
      documentation_table.keys & observation_table.keys
    end
    memoize :comparable_method_identifiers

    def documentation_table
      table(documentation)
    end
    memoize :documentation_table

    def observation_table
      table(spec_observation)
    end
    memoize :observation_table

    def table(method_data_collection)
      method_data_collection.types.map { |item| [item.method_identifier, item] }.to_h
    end
  end
end # Yardcheck
