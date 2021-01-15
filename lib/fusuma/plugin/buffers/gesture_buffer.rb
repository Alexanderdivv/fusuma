# frozen_string_literal: true

require_relative './buffer'

module Fusuma
  module Plugin
    module Buffers
      # manage events and generate command
      class GestureBuffer < Buffer
        DEFAULT_SOURCE = 'libinput_gesture_parser'
        DEFAULT_SECONDS_TO_KEEP = 0.1

        def config_param_types
          {
            'source': [String],
            'seconds_to_keep': [Float, Integer]
          }
        end

        # @param event [Event]
        # @return [Buffer, false]
        def buffer(event)
          # TODO: buffering events into buffer plugins
          # - gesture event buffer
          # - window event buffer
          # - other event buffer
          return if event&.tag != source

          if bufferable?(event)
            @events.push(event)
            self
          else
            clear
            false
          end
        end

        def clear_expired(current_time: Time.now)
          @seconds_to_keep ||= (config_params(:seconds_to_keep) || DEFAULT_SECONDS_TO_KEEP)
          @events.each do |e|
            break if current_time - e.time < @seconds_to_keep

            MultiLogger.debug("#{self.class.name}##{__method__}")

            @events.delete(e)
          end
        end

        # @param attr [Symbol]
        # @return [Float]
        def sum_attrs(attr)
          @events.map { |gesture_event| gesture_event.record.direction[attr].to_f }
                 .inject(:+)
        end

        # @param attr [Symbol]
        # @return [Float]
        def avg_attrs(attr)
          sum_attrs(attr).to_f / @events.length
        end

        # return [Integer]
        def finger
          @events.last.record.finger.to_i
        end

        # @example
        #  event_buffer.gesture
        #  => 'swipe'
        # @return [String]
        def gesture
          @events.last.record.gesture
        end

        def empty?
          @events.empty?
        end

        def select_by_events(&block)
          return enum_for(:select_by_events) unless block_given?

          events = @events.select(&block)
          self.class.new events
        end

        def bufferable?(event)
          case event.record.status
          when 'begin', 'end'
            false
          else
            true
          end
        end
      end
    end
  end
end
