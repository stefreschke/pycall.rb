=begin

PyCall bildet alle Python-built-in Methoden als Instanz- und Klassenmethoden ab

=end
module PyCall

  def self.const_missing(name)
    case name
    when :PyPtr, :PyTypePtr, :PyObjectWrapper, :PYTHON_DESCRIPTION, :PYTHON_VERSION
      PyCall.init
      const_get(name)
    else
      super
    end
  end

  module LibPython
    def self.const_missing(name)
      case name
      when :API, :Conversion, :Helpers, :PYTHON_DESCRIPTION, :PYTHON_VERSION
        PyCall.init
        const_get(name)
      else
        super
      end
    end
  end

  def self.init(python = ENV['PYTHON'])
    class << PyCall
      remove_method :const_missing
    end
    class << PyCall::LibPython
      remove_method :const_missing
    end

    ENV['PYTHONPATH'] = [ File.expand_path('../python', __FILE__), ENV['PYTHONPATH'] ].compact.join(File::PATH_SEPARATOR)
    const_set(:PYTHON_VERSION, Polyglot.eval('python', 'import sys;sys.version.split(" ")[0]'))
    const_set(:PYTHON_DESCRIPTION, LPolyglot.eval('python', 'import sys;sys.version'))
    true
  end

  module_function

  def import_module(name)
     Polyglot.eval('python', "import #{name}\n#{name}")
  end

  def builtins
    @@builtins ||= import_module('builtins')
  end

  def callable?(obj)
    #@@callable ||= Polyglot.eval('python', 'callable')
    #@@callable(obj)
  end

  def dir(obj)
    obj.__dir__()
  end

  def eval(expr, globals: nil, locals: nil)
    Polyglot.eval('python', expr)
  end

  def exec(code, globals: nil, locals: nil)
    Polyglot.eval('python', expr)
  end

  def getattr(*args)
    obj, *rest = args
    obj.__getattr__(rest)
  end

  def hasattr?(obj, name)
    obj.__hasattr__(name)
  end

  def len(obj)
    obj.__len__()
  end

  def sys
    @@sys ||= import_module('sys')
  end

  def tuple(iterable=nil)
    #@@tuple_py ||= Polyglot.eval('python', 'tuple')
    #@@tuple_py(*iterable)
  end

  def with(ctx)
    begin
      yield ctx.__enter__()
    rescue Exception => err
      # TODO: support telling what exception has been catched
      raise err unless ctx.__exit__(err.class, err, err.backtrace_locations)
    else
      ctx.__exit__(nil, nil, nil)
    end
  end
end

require 'pycall/iruby_helper_truffleruby' if defined? IRuby