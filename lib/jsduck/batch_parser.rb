require 'jsduck/util/parallel'
require 'jsduck/util/io'
require 'jsduck/source/file'
require 'jsduck/aggregator'
require 'jsduck/ignore'
require 'jsduck/enum'
require 'jsduck/accessors'
require 'jsduck/ext4_events'
require 'jsduck/override'
require 'jsduck/class'
require 'jsduck/relations'
require 'jsduck/logger'
require 'jsduck/inherit_doc'
require 'jsduck/importer'
require 'jsduck/return_values'
require 'jsduck/lint'
require 'jsduck/circular_deps'

module JsDuck

  # Performs the parsing of all input files.  Input files are read
  # from options object (originating from command line).
  class BatchParser
    def initialize(opts)
      @opts = opts
    end

    # Array of Source::File objects.
    # Available after calling the #run method.
    attr_reader :parsed_files

    # Parses the files and returns instance of Relations class.
    def run
      @parsed_files = parallel_parse(@opts.input_files)
      result = aggregate(@parsed_files)
      @relations = filter_classes(result)
      apply_extra_processing
      return @relations
    end

    private

    # Parses the files in parallel using as many processes as available CPU-s
    def parallel_parse(filenames)
      Util::Parallel.map(filenames) do |fname|
        Logger.log("Parsing", fname)
        begin
          Source::File.new(Util::IO.read(fname), fname, @opts)
        rescue
          Logger.fatal_backtrace("Error while parsing #{fname}", $!)
          exit(1)
        end
      end
    end

    # Aggregates parsing results sequencially
    def aggregate(parsed_files)
      agr = Aggregator.new
      parsed_files.each do |file|
        Logger.log("Aggregating", file.filename)
        agr.aggregate(file)
      end
      agr.classify_orphans
      agr.create_global_class
      classes = agr.classes

      Ignore.new(classes).process_all!
      Accessors.new(classes).process_all!
      Ext4Events.new(classes, @opts).process_all!
      Enum.new(classes).process_all!
      # Ignore override classes after applying them to actual classes
      @opts.external_classes += Override.new(classes).process_all!

      classes.values
    end

    # Turns all aggregated data into Class objects.
    # Depending on --ignore-global either keeps or discards the global class.
    # Warnings for global members are printed regardless of that setting,
    # but of course can be turned off using --warnings=-global
    def filter_classes(docs)
      classes = []
      docs.each do |d|
        cls = Class.new(d)
        if d[:name] != "global"
          classes << cls
        else
          # add global class only if --ignore-global not specified
          classes << cls unless @opts.ignore_global

          # Print warning for each global member
          cls.all_local_members.each do |m|
            type = m[:tagname].to_s
            name = m[:name]
            file = m[:files][0]
            Logger.warn(:global, "Global #{type}: #{name}", file[:filename], file[:linenr])
          end
        end
      end
      Relations.new(classes, @opts.external_classes)
    end

    # Do all kinds of post-processing on relations.
    def apply_extra_processing
      CircularDeps.new(@relations).process_all!
      InheritDoc.new(@relations).process_all!
      Importer.new(@relations, @opts).process_all!
      ReturnValues.new(@relations).process_all!
      Lint.new(@relations).process_all!
    end

  end

end
