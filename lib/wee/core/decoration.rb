# Abstract base class of all decorations. Forwards the methods
# #process_callbacks, #render and #backtrack_state to the next decoration in
# the chain. Subclasses should provide special behaviour in these methods,
# otherwise the decoration does not make sense.
#
# For example, a HeaderFooterDecoration class could draw a header and footer
# around the decorations or components below itself:
#
#   class HeaderFooterDecoration < Wee::Decoration
#     def render(rendering_context)
#       with_renderer_for(rendering_context) do |r|
#         render_header_on(r)
#         super(rendering_context)
#         render_footer_on(r)
#       end
#     end
#
#     def render_header_on(r)
#       r.text "header
#     end
#
#     def render_footer_on(r)
#       ...
#     end
#   end

class Wee::Decoration < Wee::Presenter

  # Points to the next decoration in the chain. A decoration is responsible for
  # all decorations or components "below" it (everything that follows this
  # decoration in the chain). In other words, it's the owner of everything
  # "below" itself.

  attr_accessor :owner   

  # Forwards method call to the next decoration in the chain.

  def process_callbacks(callback_stream)
    @owner.process_callbacks(callback_stream)
  end

  # Forwards method call to the next decoration in the chain.

  def render(rendering_context)
    @owner.render(rendering_context)
  end

  # Forwards method call to the next decoration in the chain.

  def backtrack_state(snapshot)
    @owner.backtrack_state(snapshot)
    snapshot.add(self)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # :section: Snapshot
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  # We have to save the @owner attribute to be able to correctly backtrack
  # calls, as method Wee::Component#call modifies it in the call to
  # <tt>component.remove_decoration(answer)</tt>. Removing the
  # answer-decoration has the advantage to be able to call a component more
  # than once!

  def take_snapshot
    @owner
  end

  def restore_snapshot(snap)
    @owner = snap
  end

end

# A Wee::Delegate breaks the decoration chain and forwards the methods
# #process_callbacks, #render and #backtrack_state to the corresponding *chain*
# method of it's _delegate_ component (a Wee::Component).

class Wee::Delegate < Wee::Decoration
  def initialize(delegate)
    @delegate = delegate
  end

  # Forwards method to the corresponding *chain* method of the _delegate_
  # component.

  def process_callbacks(callback_stream)
    @delegate.process_callback_chain(callback_stream)
  end

  # Forwards method to the corresponding *chain* method of the _delegate_
  # component.

  def render(rendering_context)
    @delegate.render_chain(rendering_context)
  end

  # Forwards method to the corresponding *chain* method of the _delegate_
  # component. We also take snapshots of all non-visible components, thus we
  # follow the @owner (via super). 

  def backtrack_state(snapshot)
    super
    @delegate.backtrack_state_chain(snapshot)
  end
end

# A Wee::AnswerDecoration is wrapped around a component that will call
# Component#answer. This makes it possible to use such components without the
# need to call them (Component#call), e.g. as child components of other
# components.

class Wee::AnswerDecoration < Wee::Decoration

  # When a component answers, <tt>on_answer.call(args)</tt> will be executed
  # (unless nil), where +args+ are the arguments passed to Component#answer.
  # Note that no snapshot of on_answer is taken, so you should avoid modifying
  # it!

  attr_accessor :on_answer

  def process_callbacks(callback_stream)
    args = catch(:wee_answer) { super; nil }
    if args != nil
      # return to the calling component 
      @on_answer.call(*args) if @on_answer
    end
  end
end
