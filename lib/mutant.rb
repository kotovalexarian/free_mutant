# encoding: utf-8

require 'stringio'
require 'set'
require 'adamantium'
require 'ice_nine'
require 'abstract_type'
require 'equalizer'
require 'digest/sha1'
require 'inflecto'
require 'parser'
require 'parser/current'
require 'parser_extensions'
require 'unparser'
require 'ice_nine'
require 'diff/lcs'
require 'diff/lcs/hunk'
require 'anima'
require 'concord'
require 'morpher'

# Library namespace
module Mutant
  # The frozen empty string used within mutant
  EMPTY_STRING = ''.freeze
  # The frozen empty array used within mutant
  EMPTY_ARRAY = [].freeze

  symbolset = ->(strings) { strings.map(&:to_sym).to_set.freeze }

  SCOPE_OPERATOR     = '::'.freeze

  # Set of nodes that cannot be on the LHS of an assignment
  NOT_ASSIGNABLE         = symbolset.(%w[int float str dstr class module self nil])
  # Set of op-assign types
  OP_ASSIGN              = symbolset.call(%w[or_asgn and_asgn op_asgn])
  # Set of node types that are not valid when emitted standalone
  NOT_STANDALONE         = symbolset.(%w[splat restarg block_pass])
  INDEX_OPERATORS        = symbolset.(%w[[] []=])
  UNARY_METHOD_OPERATORS = symbolset.(%w[~@ +@ -@ !])

  # Operators ruby implementeds as methods
  METHOD_OPERATORS = symbolset.(%w[
    <=> === []= [] <= >= == !~ != =~ <<
    >> ** * % / | ^ & < > + - ~@ +@ -@ !
  ])

  BINARY_METHOD_OPERATORS = (
    METHOD_OPERATORS - (INDEX_OPERATORS + UNARY_METHOD_OPERATORS)
  ).to_set.freeze

  OPERATOR_METHODS = (
    METHOD_OPERATORS + INDEX_OPERATORS + UNARY_METHOD_OPERATORS
  ).to_set.freeze

  # Nodes that are NOT handled by mutant.
  #
  # not - 1.8 only, mutant does not support 1.8
  #
  NODE_BLACKLIST = symbolset.(%w[not])

  # Nodes that are NOT generated by parser but used by mutant / unparser.
  NODE_EXTRA = symbolset.(%w[empty])

  # All node types mutant handles
  NODE_TYPES = ((Parser::Meta::NODE_TYPES + NODE_EXTRA) - NODE_BLACKLIST).to_set.freeze

  # Lookup constant for location
  #
  # @param [String] location
  #
  # @return [Object]
  #
  # @api private
  #
  def self.constant_lookup(location)
    location.split(SCOPE_OPERATOR).reduce(Object) do |parent, name|
      parent.const_get(name, nil)
    end
  end

  # Perform self zombification
  #
  # @return [self]
  #
  # @api private
  #
  def self.zombify
    Zombifier.run('mutant', :Zombie)
    self
  end

  # Define instance of subclassed superclass as constant
  #
  # @param [Class] superclass
  # @param [Symbol] name
  #
  # @return [self]
  #
  # @api private
  #
  def self.singleton_subclass_instance(name, superclass, &block)
    klass = Class.new(superclass) do
      def inspect
        self.class.name
      end

      define_singleton_method(:name) do
        "#{superclass.name}::#{name}".freeze
      end
    end
    klass.class_eval(&block)
    superclass.const_set(name, klass.new)
    self
  end

end # Mutant

require 'mutant/version'
require 'mutant/cache'
require 'mutant/delegator'
require 'mutant/node_helpers'
require 'mutant/warning_filter'
require 'mutant/warning_expectation'
require 'mutant/walker'
require 'mutant/require_highjack'
require 'mutant/isolation'
require 'mutant/mutator'
require 'mutant/mutation'
require 'mutant/mutation/evil'
require 'mutant/mutation/neutral'
require 'mutant/mutator/registry'
require 'mutant/mutator/util'
require 'mutant/mutator/util/array'
require 'mutant/mutator/util/symbol'
require 'mutant/mutator/node'
require 'mutant/mutator/node/generic'
require 'mutant/mutator/node/literal'
require 'mutant/mutator/node/literal/boolean'
require 'mutant/mutator/node/literal/range'
require 'mutant/mutator/node/literal/symbol'
require 'mutant/mutator/node/literal/string'
require 'mutant/mutator/node/literal/fixnum'
require 'mutant/mutator/node/literal/float'
require 'mutant/mutator/node/literal/array'
require 'mutant/mutator/node/literal/hash'
require 'mutant/mutator/node/literal/regex'
require 'mutant/mutator/node/literal/nil'
require 'mutant/mutator/node/argument'
require 'mutant/mutator/node/arguments'
require 'mutant/mutator/node/blockarg'
require 'mutant/mutator/node/begin'
require 'mutant/mutator/node/binary'
require 'mutant/mutator/node/const'
require 'mutant/mutator/node/dstr'
require 'mutant/mutator/node/dsym'
require 'mutant/mutator/node/kwbegin'
require 'mutant/mutator/node/named_value/access'
require 'mutant/mutator/node/named_value/constant_assignment'
require 'mutant/mutator/node/named_value/variable_assignment'
require 'mutant/mutator/node/next'
require 'mutant/mutator/node/break'
require 'mutant/mutator/node/noop'
require 'mutant/mutator/node/or_asgn'
require 'mutant/mutator/node/and_asgn'
require 'mutant/mutator/node/defined'
require 'mutant/mutator/node/op_asgn'
require 'mutant/mutator/node/conditional_loop'
require 'mutant/mutator/node/yield'
require 'mutant/mutator/node/super'
require 'mutant/mutator/node/zsuper'
require 'mutant/mutator/node/restarg'
require 'mutant/mutator/node/send'
require 'mutant/mutator/node/send/binary'
require 'mutant/mutator/node/send/attribute_assignment'
require 'mutant/mutator/node/send/index'
require 'mutant/mutator/node/when'
require 'mutant/mutator/node/define'
require 'mutant/mutator/node/mlhs'
require 'mutant/mutator/node/nthref'
require 'mutant/mutator/node/masgn'
require 'mutant/mutator/node/return'
require 'mutant/mutator/node/block'
require 'mutant/mutator/node/if'
require 'mutant/mutator/node/case'
require 'mutant/mutator/node/splat'
require 'mutant/mutator/node/resbody'
require 'mutant/mutator/node/rescue'
require 'mutant/mutator/node/match_current_line'
require 'mutant/config'
require 'mutant/loader'
require 'mutant/context'
require 'mutant/context/scope'
require 'mutant/subject'
require 'mutant/subject/method'
require 'mutant/subject/method/instance'
require 'mutant/subject/method/singleton'
require 'mutant/matcher'
require 'mutant/matcher/chain'
require 'mutant/matcher/method'
require 'mutant/matcher/method/finder'
require 'mutant/matcher/method/singleton'
require 'mutant/matcher/method/instance'
require 'mutant/matcher/methods'
require 'mutant/matcher/namespace'
require 'mutant/matcher/scope'
require 'mutant/matcher/filter'
require 'mutant/matcher/null'
require 'mutant/expression'
require 'mutant/expression/method'
require 'mutant/expression/namespace'
require 'mutant/killer'
require 'mutant/test'
require 'mutant/strategy'
require 'mutant/runner'
require 'mutant/runner/config'
require 'mutant/runner/subject'
require 'mutant/runner/mutation'
require 'mutant/runner/killer'
require 'mutant/cli'
require 'mutant/color'
require 'mutant/diff'
require 'mutant/reporter'
require 'mutant/reporter/null'
require 'mutant/reporter/trace'
require 'mutant/reporter/cli'
require 'mutant/reporter/cli/registry'
require 'mutant/reporter/cli/printer'
require 'mutant/reporter/cli/report'
require 'mutant/reporter/cli/report/config'
require 'mutant/reporter/cli/report/subject'
require 'mutant/reporter/cli/report/mutation'
require 'mutant/reporter/cli/progress'
require 'mutant/reporter/cli/progress/config'
require 'mutant/reporter/cli/progress/subject'
require 'mutant/reporter/cli/progress/mutation'
require 'mutant/reporter/cli/progress/noop'
require 'mutant/zombifier'
require 'mutant/zombifier/file'
