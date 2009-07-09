$:.unshift File.dirname(__FILE__)

<<<<<<< HEAD:lib/less/engine.rb
    def compile
      #
      # Parse the import statements
      #
          
      @tree = @tree.traverse :leaf do |key, value, path, node|
        if value == :import
          node.delete key
          node.replace( Engine.new( File.read( key ) ).compile.to_tree.update(node) )
        end
      end
          
      #
      # Parse the variables and mixins
      #
      # We use symbolic keys, such as :mixins, to store LESS-only data,
      # each branch has its own :mixins => [], and :variables => {}
      # Once a declaration has been recognised as LESS-specific, it is copied 
      # in the appropriate data structure in that branch. The declaration itself
      # can then be deleted.
      #
      
      @tree = @tree.traverse :leaf do |key, value, path, node|
        matched = if match = key.match( REGEX[:variable] )          
          node[:variables] ||= Tree.new
          node[:variables][ match.captures.first ] = value
        elsif value == :mixin
          node[:mixins] ||= []          
          node[:mixins] << key
        end
        node.delete key if matched # Delete the property if it's LESS-specific
      end
=======
require 'engine/builder'
require 'engine/nodes'
>>>>>>> cloudhead/master:lib/less/engine.rb

module Less
  class Engine
    attr_reader :css, :less
    
    def initialize obj
      @less = if obj.is_a? File
        @path = File.dirname(File.expand_path obj.path)
        obj.read
      elsif obj.is_a? String
        obj.dup
      else
        raise ArgumentError, "argument must be an instance of File or String!"
      end
      
      begin
        require Less::PARSER
      rescue LoadError
        Treetop.load Less::GRAMMAR
      end
            
      @parser = LessParser.new
    end
    
    def parse env = Node::Element.new
      root = @parser.parse(self.prepare)
      
      if root
        @tree = root.build env.tap {|e| e.file = @path }
      else
        raise SyntaxError, @parser.failure_message
      end
      
      log @tree.inspect
            
      @tree
    end
    alias :to_tree :parse
    
    def to_css
      "/* Generated with Less #{Less.version} */\n\n" +  
      (@css || @css = self.parse.to_css)
    end
    
    def prepare
      @less.gsub(/\r\n/, "\n").                                      # m$
            gsub(/\t/, '  ')                                        # Tabs to spaces
            #gsub(/('|")(.*?)(\1)/) { $1 + CGI.escape( $2 ) + $1 }   # Escape string values
           # gsub(/\/\/.*\n/, '').                                    # Comments //
          #  gsub(/\/\*.*?\*\//m, '')                                 # Comments /*
    end
    
    def to_tree
      @tree
    end
    
  end
end