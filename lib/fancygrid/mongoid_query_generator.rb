require "active_support/hash_with_indifferent_access"

module Fancygrid
  class MongoidQueryGenerator#:nodoc:
    
    OPERATOR_NAMES = [
      :equal, :not_equal, :less, :less_equal, :greater, :greater_equal, :starts_with, :ends_with, 
      :like, :is_null, :is_not_null, :is_true, :is_not_true, :is_false, :is_not_false, :in, :not_in
    ]
    
    attr_accessor :query, :fancygrid

    def initialize(options=nil, grid=nil)
      options ||= {}
      options = ActiveSupport::HashWithIndifferentAccess.new(options)
      
      self.query = {}
      self.fancygrid = grid
      
      self.select(options[:select])
      self.apply_pagination(options[:pagination])
      self.apply_search_conditions(options[:operator] || :and, options[:conditions])
      self.apply_sort_order(options[:order])
    end
    
    def parse_options(options=nil)#:nodoc:
      options ||= {}
      [:conditions, :order, :limit, :offset].each do |option|
        self.send(option, options[option]) unless options[option].nil?
      end
    end
    
    # Takes a hash like { :page => 2, :per_page => 20 } and translates it into :limit and :offset options which are
    # then applied to the final query
    #
    def apply_pagination(options=nil)
      options ||= {}
      options = ActiveSupport::HashWithIndifferentAccess.new(options)
      self.limit(options[:per_page].to_i)
      self.skip(options[:page].to_i * self.limit())
    end
    
    # Takes a hash like { :column => "users.name", :order => "asc" } and translates it into the :order option and
    # then applies it to the final query
    #
    def apply_sort_order(options=nil)
      self.order_by([[options[:column], options[:order].to_sym]]) if options
    end
    
    # Takes an operator and an conditions hash like { :<table> => { :<column> => [{ :oparator => <op>, :value => <value> }] } }
    # and converts them into a query joined by the given operator
    #
    def apply_search_conditions(operator, search_conditions)
      return unless search_conditions
      search_conditions = search_conditions.flatten
      
      conditions = {}
      
      
      search_conditions.each do |options|
        next unless options
        condition = get_condition(options[:column], options[:operator], options[:value])
        conditions = join_conditions(:and, conditions, condition)
      end
      
      conditions
    end
    
    # Joins two conditions arrays or strings with the given operator
    #
    # === Example
    #
    #    condition1 = {first_name: first_name}
    #    condition2 = {last_name: last_name}
    #
    #    join_conditions(:and, condition1, condition2)
    #    # => {first_name: first_name, last_name: last_name}
    #
    def join_conditions(operator, conditions1, conditions2)
      if conditions1.empty?
        return {} if conditions2.empty?
        return conditions2
      elsif conditions2.empty?
        return conditions1
      end
      if operator.to_sym == :or
        return {
          '$or' => [
            conditions1,
            conditions2,
          ]
        }
      else
        conditions.merge conditions2
      end
    end
    
    def append_conditions(operator, conditions)
      self.query[:conditions] = join_conditions(operator, self.query[:conditions], conditions)
    end
    
    # A hash like { :user_name => user_name }
    #
    def conditions(conditions=nil)
      if conditions
        append_conditions(:and, conditions)
      end
      self.query[:conditions]
    end
    
    # An SQL fragment like “created_at DESC, name”. 
    #
    def order(order_by=nil)
      self.query[:order] = order_by if order_by
      self.query[:order]
    end
    
    # An integer determining the limit on the number of rows that should be returned.
    #
    def limit(num=nil)
      self.query[:limit] = num if num
      self.query[:limit]
    end
    
    # An integer determining the offset from where the rows should be fetched. So at 5, it would skip rows 0 through 4.
    #
    def offset(num=nil)
      self.query[:offset] = num if num
      self.query[:offset]
    end
    
    private
      def get_regexp(query, pre='', post='')
        begin
          regex = /#{pre}#{query}#{post}/
          # supplied string is valid regex (without the forward slashes) - use it as such
          regex
        rescue
          # not a valid regexp -treat as literal search string
          /#{pre}#{Regexp.escape(query)}#{post}/
        end
      end

    
    def get_condition(column, operator, value)
      operator = case operator.to_s
      when "equal"
        value
      when "not_equal"
        {'$ne' => value}
      when "less"
        {'$lt' => value}
      when "less_equal"
        {'$lte' => value}
      when "greater"
        {'$gt' => value}
      when "greater_equal"
        {'$gte' => value}
      when "starts_with"
        get_regexp value, '^', ''
      when "ends_with"
        get_regexp value, '', '$'
      when "like"
        get_regexp value
      when "is_null"
        {'$exists' => false}
      when "is_not_null"
        {'$exists' => true}
      when "is_true"
        true
      when "is_not_true"
        {'$ne' => true}
      when "is_false"
        false
      when "is_not_false"
        {'$ne' => false}
      when "in"
        value = value.split(",")
        {'$in' => value}
      when "not_in"
        value = value.split(",")
        {'$nin' => value}
      else
        value
      end
      
      {column => operator}
    end
  end
end