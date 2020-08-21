module PyCall

  const_set(:PYTHON_VERSION, Polyglot.eval('python', 'import sys;sys.version.split(" ")[0]'))
  const_set(:PYTHON_DESCRIPTION, Polyglot.eval('python', 'import sys;sys.version'))

  class PyPtr
    def initialize(*args)
      @__pyptr__ = args.first
    end

    def none?
      @__pyptr__.nil?
    end

    def nil?
      @__pyptr__.nil?
    end

    NULL = PyCall::PyPtr.new(Polyglot.eval('python', 'None'))
  end
  require 'pycall/truffleruby/conversion'
  require 'pycall/truffleruby/pyobject_wrapper'
  PyCall::Conversion.use_wrappers(PyCall::PyObjectWrapper)
  require 'pycall/truffleruby/libpython'

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
    begin
      if obj == PyCall::LibPython::API::PyDict_Type
        return true
      elsif obj == PyCall::LibPython::API::PyBool_Type 
        return true
      elsif obj == PyCall::LibPython::API::PyString_Type 
        return true
      elsif obj == PyCall::LibPython::API::PyFloat_Type 
        return true
      end
    rescue => e #obj== might be undefined
    end
    if obj.is_a?(PyObjectWrapper)
      obj = obj.__pyptr__
    elsif !Truffle::Interop.foreign?(obj)
      raise TypeError, "unexpected argument type " + obj.class.to_s + " (expected PyCall::PyPtr or its wrapper)"
    end
    Polyglot.eval('python', 'callable').call(obj)
  end

  def dir(obj)
    if obj.is_a? PyObjectWrapper
      PyObjectWrapper.wrap(Polyglot.eval('python', 'dir').call(obj.__pyptr__))
    end
  end

  def eval(expr, globals: nil, locals: nil)
    begin
      PyObjectWrapper.wrap(Polyglot.eval('python', expr))
    rescue RuntimeError => e
      raise PyCall::PyError.new(e.message, '', e.backtrace)
    end
  end

  def exec(code, globals: nil, locals: nil)
    begin
      PyObjectWrapper.wrap(Polyglot.eval('python', code))
    rescue RuntimeError => e
      raise PyCall::PyError.new(e.message, '', e.backtrace)
    end
  end

  def to_py_complex(number)#TODO: remove if Truffle supports Complex Numbers in a Polyglot way
    @@to_python_complex ||= Polyglot.eval('python', 'lambda x,y: x+y*1j')
    @@to_python_complex.call(number.real, number.imag)
  end

  def from_py_complex(number)#TODO: remove if Truffle supports Complex Numbers in a Polyglot way
    @@from_python_complex ||= Polyglot.eval('python', 'lambda x: (x.real, x.imag)')
    splitted = @@from_python_complex.call(number)
    splitted[0] + splitted[1] * 1i
  end

  def getattr(*args)
    obj, *rest = args
    if obj.is_a?(PyObjectWrapper)
      obj = obj.__pyptr__
    end
    begin
      return PyObjectWrapper.wrap(Polyglot.eval('python', 'getattr').call(obj, *rest))
    rescue => e
      raise PyCall::PyError.new(e.message, "", e.backtrace)
    end
  end

  def hasattr?(obj, name)
    if obj.is_a?(PyObjectWrapper)
      obj = obj.__pyptr__
    end
    Polyglot.eval('python', 'hasattr').call(obj, name)
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
    @@copy_module ||= PyModuleWrapper.wrap(import_module('copy'))
  end

  def tuple(iterable=nil)
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
      yield PyObjectWrapper.wrap(ctx.__enter__())
    rescue => err
      is_py_err = err.is_a? PyCall::PyError || err.message.include?('(PException)')
      err_to_pass = err
      err_to_pass = PyCall::PyError.new('error in Python', '', []) if is_py_err

      stack = PyCall::List.new(PyObjectWrapper.unwrap(err.backtrace_locations))
      if !ctx.__exit__(err_to_pass.class, err_to_pass, stack)
        if is_py_err
          raise PyCall::PyError.new('error in Python', '', [])
          # needs this message / no backtrace by spec
        else
          raise RuntimeError.new('error in Ruby')
        end
      end
    else
      ctx.__exit__(nil, nil, nil)
    end
  end

  require 'pycall/truffleruby/tuple'
  PyCall::Conversion.set_tuple_wrapper(PyCall::Tuple)
  require 'pycall/truffleruby/list'
  PyCall::Conversion.set_list_wrapper(PyCall::List)
  require 'pycall/truffleruby/dict'
  PyCall::Conversion.set_dict_wrapper(PyCall::Dict)
  require 'pycall/truffleruby/set'
  PyCall::Conversion.set_set_wrapper(PyCall::Set)
  require 'pycall/truffleruby/slice'
  PyCall::Conversion.set_slice_wrapper(PyCall::Slice)
  require 'pycall/truffleruby/pyruby_ptr'
  PyCall::Conversion.set_ruby_wrapper(PyCall::PyRubyPtr)

  def self.wrap_ruby_object(ruby_object)
    PyRubyPtr.new(ruby_object)
  end
end

#require 'pycall/iruby_helper_truffleruby' if defined? IRuby