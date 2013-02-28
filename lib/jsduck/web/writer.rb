require 'jsduck/exporter/app'
require 'jsduck/format/batch'
require 'jsduck/util/md5'
require 'jsduck/class_writer'
require 'jsduck/inline_examples'
require 'jsduck/web/template'
require 'jsduck/web/index_html'
require 'jsduck/web/data'
require 'jsduck/web/source'
require 'fileutils'

module JsDuck
  module Web

    # Performs the generation of docs web app.
    class Writer
      def initialize(relations, assets, parsed_files, opts)
        @relations = relations
        @assets = assets
        @parsed_files = parsed_files
        @opts = opts
      end

      def write
        clean_output_dir

        write_template_files
        write_app_data
        write_index_html

        # class-formatting is done in parallel which breaks the links
        # between source files and classes. Therefore it MUST to be done
        # after writing sources which needs the links to work.
        write_source if @opts.source
        format_classes

        write_inline_examples if @opts.tests

        write_classes

        @assets.write
      end

      def write_template_files
        Web::Template.new(@opts).write
      end

      def write_app_data
        filename = @opts.output_dir+"/data.js"
        Web::Data.new(@relations, @assets, @opts).write(filename)
        # Rename the file and remember the name for use in IndexHtml.write
        @opts.data_path = Util::MD5.rename(filename)
      end

      def write_index_html
        Web::IndexHtml.new(@assets, @opts).write
      end

      def write_source
        source_writer = Web::Source.new(@parsed_files)
        source_writer.write(@opts.output_dir + "/source")
      end

      def write_inline_examples
        examples = InlineExamples.new
        examples.add_classes(@relations)
        examples.add_guides(@assets.guides)
        examples.write(@opts.output_dir+"/inline-examples.js")
      end

      def write_classes
        class_writer = ClassWriter.new(Exporter::App, @relations, @opts)
        class_writer.write(@opts.output_dir+"/output", ".js")
      end

      # -- util routines --

      def clean_output_dir
        FileUtils.rm_rf(@opts.output_dir)
      end

      def format_classes
        Format::Batch.format_all!(@relations, @assets, @opts)
      end

    end

  end
end