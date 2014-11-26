require 'set'

class CarryOn < Parser::Rewriter
  def initialize
    @should_parenthesize_ids = Set.new
    @preprocessed_ids = Set.new
  end

  def on_if(node)
    loc = node.loc
    if loc.is_a?(Parser::Source::Map::Ternary)
      should_parenthesize(*node.children)
    else
      should_parenthesize node.children[0]
    end

    super
  end

  def on_or(node)
    should_parenthesize(*node.children)
    super
  end

  def on_block(node)
    parenthesize = marked_for_parenthisization?(node)
    send_node = node.children.first
    insert_before(send_node.loc.expression, '(')
    preprocessed! send_node #FIXME

    super

    append_rescue node.loc.end
    insert_after(node.loc.end, ')')
  end

  def on_splat(node)
    should_parenthesize node.children[0]
    super
  end

  def on_send(node)
    loc = node.loc

    unless preprocessed?(node)
      if (operator?(node) || marked_for_parenthisization?(node)) && !parenthesized?(node)
        #parenthesized_rescue node
        insert_before(loc.expression, '(')
        after = ' rescue nil)'
      else
        #append_rescue loc.expression
        after = ' rescue nil'
      end
    end

    receiver_node, _, *argument_nodes = node.children
    should_parenthesize(receiver_node)
    if argument_nodes.any? {|arg_node| arg_node.type == :send }
      if loc.begin.nil?
        after = ')' + (after || '')
        # un-parenthesized argument list
        insert_after(loc.selector, '(')
      end
      should_parenthesize(*argument_nodes)
    end

    super

    if after
      insert_after(loc.expression, after)
    end
  end

private

  def append_rescue(range)
    insert_after(range, ' rescue nil')
  end

  def parenthesized_rescue(node)
    expr = node.loc.expression
    if parenthesized? node
      append_rescue(expr)
    else
      insert_before(expr, '(')
      insert_after(expr, ' rescue nil)')
    end
  end

  def should_parenthesize(*nodes)
    @should_parenthesize_ids.merge nodes.map(&:object_id)
  end

  def marked_for_parenthisization?(node)
    @should_parenthesize_ids.include?(node.object_id)
  end

  def preprocessed!(*nodes)
    @preprocessed_ids.merge nodes.map(&:object_id)
  end

  def preprocessed?(node)
    @preprocessed_ids.include?(node.object_id)
  end

  def operator?(node)
    !node.children.first.nil? && node.loc.dot.nil? && node.children[1] != :[]
  end

  def parenthesized?(node)
    return false if node.type != :begin
    the_begin = node.loc.begin
    the_begin && the_begin.source == '('
  end
end
