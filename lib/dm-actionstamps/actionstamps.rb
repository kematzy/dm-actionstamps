
require 'dm-core'

module DataMapper 
  module Actionstamps 
    
    ##
    # Provider method, used to setup the +current_user+ information.
    #  
    # ==== Examples
    # 
    #   class User
    #     <snip...>
    #     
    #     provides_actionstamps
    #     
    #   end
    #     
    #     => creates the :current_user & :current_user= methods
    # 
    #   class Client
    #     <snip...>
    #     
    #     provides_actionstamps
    #     
    #   end
    #     
    #     => creates the :current_client & :current_client= methods
    # 
    # 
    # @api public
    def provides_actionstamps 
      @actionstamps_class = self
      
      extend DataMapper::Actionstamps::ClassMethods
      
      class_eval(<<-END, __FILE__, __LINE__)
        def self.current_#{name.downcase}=(user)
          Thread.current["#{name.downcase}_#{self.object_id}_actionstamp"] = user
        end
        def self.current_#{name.downcase}
          Thread.current["#{name.downcase}_#{self.object_id}_actionstamp"]
        end
      END
    end
    
    
    ##
    # The Receiver Model receives the actionstamps and defines the
    # 
    # ==== Examples
    # 
    #   class Bill
    #     include DataMapper::Resource
    #     property :id,     Serial
    #     property :amount, Integer
    #     ...<snip>
    #     
    #     actionstamps :by, Client
    #     
    #   end
    #     
    #     => creates the :created_by and :updated_by fields.
    # 
    #   actionstamps :by_id, Author
    # 
    # 
    # @api public/private
    def actionstamps(*args)
      # set default args if none passed in
      args = [:by, ::User ] if args.empty?
      # if invalid args, just bail out
      if ( args[0].is_a?(Hash) || nil ) || ( args[1].is_a?(Hash) || args[1].is_a?( Symbol) || args[1].is_a?(String) || nil )
        raise ArgumentError, "Invalid arguments passed: syntax: actionstamps :by, ModelName"
      end
      
      configs = { :suffix => args[0], :model => args[1] }
      
      # do we have the fields :created_? / :updated_? declared, if not we declare them
      if properties.any? { |p| p.name.to_s =~ /^(created|updated)_#{Regexp.escape(configs[:suffix].to_s)}$/ }
        # if they are declared then we use them
        raise ArgumentError, "Full functionality NOT implemented yet. Please DO NOT declare your created_#{configs[:suffix]} / updated_#{configs[:suffix]} properties, they will be automatically declared by this plugin."
      else
        property "created_#{configs[:suffix]}".to_sym, Integer#, :default => 1
        property "updated_#{configs[:suffix]}".to_sym, Integer#, :default => 1
      end
      
      @actionstamps_receiver_properties = ["created_#{configs[:suffix]}".to_sym, "updated_#{configs[:suffix]}".to_sym ]
      @actionstamps_model_class = configs[:model].to_s.capitalize
      
      extend DataMapper::Actionstamps::ClassMethods
      include DataMapper::Actionstamps::ReceiverMethods
      
      
      class_eval(<<-END, __FILE__, __LINE__)
        def set_actionstamps
          self.created_#{configs[:suffix].to_s} = #{configs[:model]}.current_#{configs[:model].to_s.downcase}.id if #{configs[:model]}.current_#{configs[:model].to_s.downcase} && self.new? && self.created_#{configs[:suffix].to_s}.nil?
          self.updated_#{configs[:suffix].to_s} = #{configs[:model]}.current_#{configs[:model].to_s.downcase}.id if #{configs[:model]}.current_#{configs[:model].to_s.downcase}
        end
      END
      
    end #/def actionstamps
    
    module ClassMethods
      attr_reader :actionstamps_class
    end #/module ClassMethods
    
    
    module ReceiverMethods
      
      def self.included(model)
        model.before :save, :set_actionstamps_on_save
        model.extend DataMapper::Actionstamps::ClassMethods
      end
      
      ##
      # Saves the record with the created_? / updated_? attributes set to the current time.
      #  
      # ==== Examples
      # 
      #   @model.touch
      # 
      # @api public
      def touch 
        set_actionstamps
        save
      end
      
      
      private
        
        ##
        # Callback method
        #  
        # ==== Examples
        # 
        #   before :save, :set_actionstamps_on_save
        #   
        # 
        # @api public
        def set_actionstamps_on_save 
          return unless dirty?
          set_actionstamps
        end
        
        
    end #/module ReceiverMethods
    
  end #/module Actionstamps
  
end #/module DataMapper