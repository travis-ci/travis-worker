module Travis
  module Worker
    module VirtualMachine
      class BlueBox
        # This class wraps the JSON object that BlueBox returns into an object
        # so that it can be used to query its DIST, GROUP, TEMPLATE parameters
        class Template
          attr_reader :id, :status, :description, :public, :locations, :created

          # This Regexp matches the description of the Blue Box and picks out
          # interesting parts
          HYPHENATED_TEAMPLATES = ['node-js']

          DESCRIPTION_MATCH_PATTERN = /^travis # starts with travis
          (
            (-(?<dist>\w+))*? # dist is matched non-greedily, because...
            (-(?<group>\w+))? # group takes precedence over dist
            (-(?<template>(#{Regexp.new(HYPHENATED_TEAMPLATES.join("|"))})))
                                      # since node-js unfortunately has a hyphen in it,
                                      # we match it first
          |
            (-(?<alt_dist>\w+))*?
            (-(?<alt_group>\w+))?
            (-(?<alt_template>\w+))
          )
          -\d{4}(-\d{2}){4}
          /x

          def initialize(opts)
            @id          = opts.fetch 'id',          '12345678-abcd-fedc-4321-1234567890ab'
            @status      = opts.fetch 'status',      'stored'
            @description = opts.fetch 'description', 'Undefined'
            @public      = opts.fetch 'public',      false
            @locations   = opts.fetch 'locations',   ['016cdf0f-821b-4bed-8b9c-cd46f02c2363']
            @created     = opts.fetch 'created',     '2014-08-28T12:56:36-07:00'
            @match_data  = DESCRIPTION_MATCH_PATTERN.match(@description)
            @hash        = {
              'id' => @id,
              'status' => @status,
              'description' => @description,
              'public' => @public,
              'locations' => @locations,
              'created' => @created
            }
          end

          def dist
            @dist ||= (@match_data[:dist] || @match_data[:alt_dist])
          end

          def group
            @group ||= (@match_data[:group] || @match_data[:alt_group])
          end

          def template
            @template ||= (@match_data[:template] || @match_data[:alt_template])
          end

          def to_h
            @hash
          end

          def to_s
            @hash.to_s
          end

          def info
            @hash.slice('id', 'description', 'created')
          end

          def ==(other)
            to_h == other.to_h
          end
        end
      end
    end
  end
end
