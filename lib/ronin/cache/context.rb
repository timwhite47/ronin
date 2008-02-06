#
#--
# Ronin - A ruby development platform designed for information security
# and data exploration tasks.
#
# Copyright (c) 2006-2008 Hal Brodigan (postmodern.mod3 at gmail.com)
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
#++
#

require 'ronin/cache/extensions/kernel'
require 'ronin/cache/exceptions/context_not_found'
require 'ronin/cache/extensions/context'
require 'ronin/extensions/meta'

module Ronin
  module Cache
    module Context
      #
      # Returns a Hash of all defined contexts.
      #
      def Context.contexts
        @@contexts ||= {}
      end

      #
      # Returns +true+ if there is a context defined with the specified
      # _name_, returns +false+ otherwise.
      #
      def Context.is_context?(name)
        ObjectContext.contexts.has_key?(name.to_sym)
      end

      #
      # Load all contexts from the specified _path_, returning an Array of
      # the loaded contexts.
      #
      #   Context.load_contexts('/path/to/my_context.rb') # => [...]
      #
      def Context.load_contexts(path)
        path = File.expand_path(path)
        contexts = []

        Context.load_contexts(path).each do |id,block|
          unless Context.is_context?(id)
            raise(ContextNotFound,"unknown context '#{id}'",caller)
          end

          new_context = Context.contexts[id].new
          new_context.instance_eval(&block)

          contexts << new_context
        end

        return contexts
      end

      #
      # Loads the context of the specified _name_, from the sepcified
      # _path_ with the given _args_. If no contexts were defined with the
      # specified _name_, a ContextNotFound exception will be raised.
      #
      #   Context.load_context('notes','/path/to/my_notes.rb') # => [...]
      #
      def Context.load_context(name,path,*args)
        type = type.to_sym

        unless Context.is_context?(type)
          raise(ContextNotFound,"unknown context '#{type}'",caller)
        end

        return Context.contexts[type].load_context(path,*args)
      end

      #
      # Converts the name of the _base_ class to a context name, in string
      # form.
      #
      #   Context.namify(Ronin::Resources) # => "ronin_resources"
      #
      #   Context.namify(Analysis::Audio) # => "ronin_analysis_audio"
      #
      def Context.namify(base)
        # similar to the way Og tableizes Class names
        base.to_s.downcase.gsub(/::/,'_').gsub(/^ronin_/,'').to_sym
      end


      def Context.load_contexts(path)
        path = File.expand_path(path)

        unless File.file?(path)
          raise(ContextNotFound,"context '#{path}' doest not exist",caller)
        end

        # push on the path to load
        ronin_pending_contexts.unshift(path)

        load(path)

        # pop off the path to load
        ronin_pending_contexts.shift

        # return the loaded contexts
        return ronin_contexts
      end
    end
  end
end
