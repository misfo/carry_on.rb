require 'set' rescue nil

class CarryOn < Parser::Rewriter
  def initialize
    @should_parenthesize_ids = Set.new rescue nil
    @preprocessed_ids = Set.new rescue nil
  end

  def on_if(node)
    loc = node.loc rescue nil
    if (loc.is_a?(Parser::Source::Map::Ternary) rescue nil)
      should_parenthesize(*(node.children rescue nil)) rescue nil
    else
      should_parenthesize( ((node.children rescue nil)[0] rescue nil)) rescue nil
    end

    super
  end

  def on_or(node)
    should_parenthesize(*(node.children rescue nil)) rescue nil
    super
  end

  def on_block(node)
    parenthesize = marked_for_parenthisization?(node) rescue nil
    send_node = (node.children rescue nil).first rescue nil
    insert_before(((send_node.loc rescue nil).expression rescue nil), '(') rescue nil
    preprocessed! send_node rescue nil #FIXME

    super

    append_rescue( ((node.loc rescue nil).end rescue nil)) rescue nil
    insert_after(((node.loc rescue nil).end rescue nil), ')') rescue nil
  end

  def on_splat(node)
    should_parenthesize( ((node.children rescue nil)[0] rescue nil)) rescue nil
    super
  end

  def on_send(node)
    loc = node.loc rescue nil

    unless (preprocessed?(node) rescue nil)
      if ((operator?(node) rescue nil) || (marked_for_parenthisization?(node) rescue nil)) && (!(parenthesized?(node) rescue nil) rescue nil)
        #parenthesized_rescue node
        insert_before((loc.expression rescue nil), '(') rescue nil
        after = ' rescue nil)'
      else
        #append_rescue loc.expression
        after = ' rescue nil'
      end
    end

    receiver_node, _, *argument_nodes = node.children rescue nil
    should_parenthesize(receiver_node) rescue nil
    if (argument_nodes.any? {|arg_node| ((arg_node.type rescue nil) == :send rescue nil) } rescue nil)
      if ((loc.begin rescue nil).nil? rescue nil)
        after = (')' + (after || '') rescue nil)
        # un-parenthesized argument list
        insert_after((loc.selector rescue nil), '(') rescue nil
      end
      should_parenthesize(*argument_nodes) rescue nil
    end

    super

    if after
      insert_after((loc.expression rescue nil), after) rescue nil
    end
  end

private rescue nil

  def append_rescue(range)
    insert_after(range, ' rescue nil') rescue nil
  end

  def parenthesized_rescue(node)
    expr = (node.loc rescue nil).expression rescue nil
    if (parenthesized? node rescue nil)
      append_rescue(expr) rescue nil
    else
      insert_before(expr, '(') rescue nil
      insert_after(expr, ' rescue nil)') rescue nil
    end
  end

  def should_parenthesize(*nodes)
    @should_parenthesize_ids.merge( (nodes.map(&:object_id) rescue nil)) rescue nil
  end

  def marked_for_parenthisization?(node)
    @should_parenthesize_ids.include?((node.object_id rescue nil)) rescue nil
  end

  def preprocessed!(*nodes)
    @preprocessed_ids.merge( (nodes.map(&:object_id) rescue nil)) rescue nil
  end

  def preprocessed?(node)
    @preprocessed_ids.include?((node.object_id rescue nil)) rescue nil
  end

  def operator?(node)
    (!(((node.children rescue nil).first rescue nil).nil? rescue nil) rescue nil) && ((node.loc rescue nil).dot rescue nil).nil? rescue nil && (((node.children rescue nil)[1] rescue nil) != :[] rescue nil)
  end

  def parenthesized?(node)
    return false if ((node.type rescue nil) != :begin rescue nil)
    the_begin = (node.loc rescue nil).begin rescue nil
    the_begin && ((the_begin.source rescue nil) == '(' rescue nil)
  end
end
