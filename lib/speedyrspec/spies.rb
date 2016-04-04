module SpeedyTest
  # A spy with no functionality
  class DummySpy
    def start
      puts 'Starting with DummySpy'
    end

    def finish; end
    def test_starts(_); end
    def test_ends(_); end
  end

  class TracingSpy
    def start
      puts 'Starting test suite with tracing enabled'
      @tracer = set_tracer
      @dependency = Hash.new{|h, k| h[k] = Set.new}
    end

    def finish
      File.write(SpeedyTest.trace_file, @dependency.to_json)
    end

    def test_starts(example)
      deduce_workingdir(example) unless @working_dir
      @current_test = example.file_path
      @tracer.enable
    end

    def test_ends(example)
      @tracer.disable
    end

    private

      def deduce_workingdir(example)
        fp = example.metadata[:file_path]
        path = example.metadata[:absolute_file_path]
        @working_dir = path[0, path.index(fp[1, fp.length])]
        @working_dir_length = @working_dir.length
      end

      def set_tracer
        TracePoint.new(*%i[call b_call]) do |tp|
          unless tp.path.index(@working_dir).nil?
            file = tp.path
            @dependency[file].add(@current_test)
          end
        end
      end
  end
end
