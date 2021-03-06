require 'brakeman/processors/base_processor'
require 'brakeman/processors/alias_processor'
require 'brakeman/tracker/library'

#Process generic library and stores it in Tracker.libs
class Brakeman::LibraryProcessor < Brakeman::BaseProcessor

  def initialize tracker
    super
    @file_name = nil
    @alias_processor = Brakeman::AliasProcessor.new tracker
    @current_module = nil
    @current_class = nil
  end

  def process_library src, file_name = nil
    @file_name = file_name
    process src
  end

  def process_class exp
    name = class_name(exp.class_name)
    parent = class_name exp.parent_name

    if @current_class
      outer_class = @current_class
      name = (outer_class.name.to_s + "::" + name.to_s).to_sym
    end

    if @current_module
      name = (@current_module.name.to_s + "::" + name.to_s).to_sym
    end

    if @tracker.libs[name]
      @current_class = @tracker.libs[name]
      @current_class.add_file @file_name, exp
    else
      @current_class = Brakeman::Library.new name, parent, @file_name, exp, @tracker
      @tracker.libs[name] = @current_class
    end

    exp.body = process_all! exp.body

    if outer_class
      @current_class = outer_class
    else
      @current_class = nil
    end

    exp
  end

  def process_module exp
    name = class_name(exp.module_name)

    if @current_module
      outer_module = @current_module
      name = (outer_module.name.to_s + "::" + name.to_s).to_sym
    end

    if @current_class
      name = (@current_class.name.to_s + "::" + name.to_s).to_sym
    end

    if @tracker.libs[name]
      @current_module = @tracker.libs[name]
      @current_module.add_file @file_name, exp
    else
      @current_module = Brakeman::Library.new name, nil, @file_name, exp, @tracker
      @tracker.libs[name] = @current_module
    end

    exp.body = process_all! exp.body

    if outer_module
      @current_module = outer_module
    else
      @current_module = nil
    end

    exp
  end

  def process_defn exp
    exp = @alias_processor.process exp

    if @current_class
      exp.body = process_all! exp.body
      @current_class.add_method :public, exp.method_name, exp, @file_name
    elsif @current_module
      exp.body = process_all! exp.body
      @current_module.add_method :public, exp.method_name, exp, @file_name
    end

    exp
  end

  def process_defs exp
    exp = @alias_processor.process exp

    if @current_class
      exp.body = process_all! exp.body
      @current_class.add_method :public, exp.method_name, exp, @file_name
    elsif @current_module
      exp.body = process_all! exp.body
      @current_module.add_method :public, exp.method_name, exp, @file_name
    end

    exp
  end
end
