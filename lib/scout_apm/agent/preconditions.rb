module ScoutApm
  class Agent
    class Preconditions
      # The preconditions here must be a 2 element hash, with :message and :check.
      # message: Proc that takes the environment, and returns a string
      # check: Proc that takes an AgentContext and returns true if precondition was met, if false, we shouldn't start.
      PRECONDITIONS = [
        PRECONDITION_ENABLED = {
          :message => proc {|environ| "Monitoring isn't enabled for the [#{environ.env}] environment." },
          :check => proc { |context| context.config.value('monitor') },
        },

        PRECONDITION_APP_NAME = {
          :message => proc {|environ| "An application name could not be determined. Specify the :name value in scout_apm.yml." },
          :check => proc { |context| context.environment.application_name },
        },

        PRECONDITION_INTERACTIVE = {
          :message => proc {|environ| "Agent attempting to load in interactive mode." },
          :check => proc { |context| ! context.environment.interactive? },
        },

        PRECONDITION_DETECTED_SERVER = {
          :message => proc {|environ| "Deferring agent start. Standing by for first request" },
          :check => proc { |context|
            app_server_missing = !context.environment.app_server_integration(true).found?
            background_job_missing = context.environment.background_job_integrations.length == 0

            !app_server_missing && !background_job_missing
          },
        },

        PRECONDITION_ALREADY_STARTED = {
          :message => proc {|environ| "Already started agent." },
          :check => proc { |context| !context.started? },
        },

        PRECONDITION_OLD_SCOUT_RAILS = {
          :message => proc {|environ| "ScoutAPM is incompatible with the old Scout Rails plugin. Please remove scout_rails from your Gemfile" },
          :check => proc { !defined?(::ScoutRails) },
        },
      ]

      def check?(context)
        @check_result ||=
          begin
            failed_preconditions = PRECONDITIONS.inject(Array.new) { |errors, condition|
              met = condition[:check].call(context)
              errors << condition[:message].call(context.environment) unless met
              errors
            }

            if failed_preconditions.any?
              failed_preconditions.each {|msg| context.logger.warn(msg) }
              force? # if forced, return true anyway
            else
              # No errors, we met preconditions
              true
            end
          end
      end

      # XXX: Wire up options here and below in the appserver & bg server detections
      def force?
        false
      end
    end
  end
end
