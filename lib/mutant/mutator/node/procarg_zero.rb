# frozen_string_literal: true

module Mutant
  class Mutator
    class Node
      class ProcargZero < self
        handle :procarg0

        children :argument

      private

        # Emit mutations
        #
        # @return [undefined]
        def dispatch
          name = Mutant::Util.one(argument.children)

          emit_type(s(:arg, :"_#{name}")) unless name.to_s.start_with?('_')
        end
      end # ProcargZero
    end # Node
  end # Mutator
end # Mutant
