=begin

PyCall bildet alle Python-built-in Methoden als Instanz- und Klassenmethoden ab

=end

module PyCall

  const_set(:PYTHON_VERSION, Polyglot.eval('python', 'import sys;sys.version.split(" ")[0]'))
  const_set(:PYTHON_DESCRIPTION, Polyglot.eval('python', 'import sys;sys.version'))

  require 'pycall/truffleruby/conversion'
  require 'pycall/truffleruby/pyobject_wrapper'
  require 'pycall/truffleruby/libpython'

  class PyPtr
    def initialize(*args)
      #no pointer in Truffleruby
    end
    NULL = PyCall::LibPython::API::None
  end

  def self.init(python = ENV['PYTHON'])
    @@initialized ||= false
    return false if @@initialized

    @@initialized = true
    true
  end

  require 'pycall/truffleruby/pymodule_wrapper'
  require 'pycall/truffleruby/pytypeobject_wrapper'
  require 'pycall/truffleruby/pyerror'

  module_function

  def import_module(name)
    PyModuleWrapper.wrap(Polyglot.eval('python', "import #{name}\n#{name}"))
  end

  def builtins
    @@builtins ||= PyModuleWrapper.wrap(import_module('builtins'))
  end

  def callable?(obj)
    if obj.is_a?(PyObjectWrapper)
      obj = obj.__pyptr__
    elsif !Truffle::Interop.foreign?(obj)#needs to also support PyDict_Type etc
      Polyglot.eval("python", "breakpoint()")
      raise TypeError, "unexpected argument type #{obj.class} (expected PyCall::PyPtr or its wrapper)"
    end
    @@callable ||= Polyglot.eval('python', 'callable')
    @@callable.call(obj)
  end

  def dir(obj)
    if obj.is_a? PyObjectWrapper
      @@python_dir ||= Polyglot.eval('python', 'dir')
      PyObjectWrapper.wrap(@@python_dir.call(obj.__pyptr__))
    end
  end

  def eval(expr, globals: nil, locals: nil)
    begin
      PyObjectWrapper.wrap(Polyglot.eval('python', expr))
    rescue RuntimeError => e
      raise PyCall::PyError.new(e.message, "", e.backtrace)
    end
  end

  def exec(code, globals: nil, locals: nil)
    begin
      PyObjectWrapper.wrap(Polyglot.eval('python', code))
    rescue RuntimeError => e
      raise PyCall::PyError.new(e.message, "", e.backtrace)
    end
  end

  def to_py_complex(number)#TODO: delete if Graal supports Complex Numbers in Polyglot way
    @@python_complex_helper = Polyglot.eval('python', 'lambda x,y: x+y*1j')
    @@python_complex_helper.call(number.real, number.imag)
  end

  def from_py_complex(number)#TODO: delete if Graal supports Complex Numbers in Polyglot way
    @@python_complex_split = Polyglot.eval('python', 'lambda x: (x.real, x.imag)')
    splitted = @@python_complex_split.call(number)
    splitted[0] + splitted[1] * 1i
  end

  def getattr(*args)
    obj, *rest = args
    if obj.is_a?(PyObjectWrapper)
      obj = obj.__pyptr__
    end
    @@getattr_py ||= Polyglot.eval('python', 'getattr')
    begin
      return PyObjectWrapper.wrap(@@getattr_py.call(obj, *rest))
    rescue => e
      raise PyCall::PyError.new(e.message, "", e.backtrace)
    end
  end

  def hasattr?(obj, name)
    if obj.is_a?(PyObjectWrapper)
      obj = obj.__pyptr__
    end
    @@hasattr_py ||= Polyglot.eval('python', 'hasattr')
    @@hasattr_py.call(obj, name)
  end

  def same?(left, right)
    @@pythonop_eq ||= Polyglot.eval('python', 'import operator;operator.eq')
    case left
    when PyObjectWrapper
      case right
      when PyObjectWrapper
        return @@pythonop_eq.call(left.__pyptr__, right.__pyptr__)
      end
    end
    false
  end

  def len(obj)
    obj.__len__()
  end

  def sys
    @@sys ||= PyModuleWrapper.wrap(import_module('sys'))
  end

  def copy
    @@copy_module ||= PyModuleWrapper.wrap(import_module("copy"))
  end

  def tuple(iterable=nil)
    @@tuple_py ||= Polyglot.eval('python', 'tuple')
    if iterable.nil?
      PyCall::Tuple.new
    else
      PyCall::Tuple.new(*iterable)
    end
  end

  def wrap_class(cls)
    return cls if cls.is_a? PyTypeObjectWrapper
    PyTypeObjectWrapper.new(cls)
  end

  def wrap_module(mod)
    return mod if mod.is_a? PyModuleWrapper
    PyModuleWrapper.new(mod)
  end

  def with(ctx)
    begin
      yield ctx.__enter__()
    rescue => err
      err_to_pass = err
      err_to_pass = PyCall::PyError.new('error in Python', '', []) if err.is_a? PyCall::PyError || err.message.include?("(PException)")
      if !ctx.__exit__(err.class, err_to_pass, PyCall::List.new(err.backtrace_locations))
        if err.is_a? PyCall::PyError || err.message.include?("(PException)")
          raise PyCall::PyError.new('error in Python', '', [])
          # needs this message / no backtrace by spec
        else
          puts "RubyExc"
          raise RuntimeError.new('error in Ruby')
        end
      end
    else
      ctx.__exit__(nil, nil, nil)
    end
  end

  require 'pycall/truffleruby/tuple'
  require 'pycall/truffleruby/list'
  require 'pycall/truffleruby/dict'
  require 'pycall/truffleruby/set'
  require 'pycall/truffleruby/slice'
  require 'pycall/truffleruby/pyruby_ptr'

  def self.wrap_ruby_object(ruby_object)
    PyRubyPtr.new(ruby_object)
  end
end

#require 'pycall/iruby_helper_truffleruby' if defined? IRuby