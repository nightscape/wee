require 'thread'
require 'wee/id_generator'
require 'wee/lru_cache'

module Wee

  #
  # A Wee::Application manages all Session's of a single application.  It
  # dispatches the request to the correct handler by examining the request.
  #
  class Application

    class SessionCache < Wee::LRUCache
      def garbage_collect
        delete_if {|id, session| session.dead? }
      end
    end

    #
    # Creates a new application. The block, when called, must
    # return a new Session instance. 
    #
    #   Wee::Application.new { Wee::Session.new(root_component) }
    #
    def initialize(max_sessions=10_000, &block)
      @session_factory = block || raise(ArgumentError)
      @session_ids ||= Wee::IdGenerator::Secure.new
      @sessions = SessionCache.new(max_sessions)
      @mutex = Mutex.new
    end

    #
    # Garbage collect dead sessions
    #
    def cleanup_sessions
      @mutex.synchronize { @sessions.garbage_collect }
    end
    
    #
    # Handles a web request
    #
    def call(env)
      request = Wee::Request.new(env)

      if request.session_id
        session = @mutex.synchronize { @sessions[request.session_id] }
        if session and session.alive?
          session.call(env)
        else
          url = request.build_url(:session_id => nil, :page_id => nil)
          Wee::RefreshResponse.new("Invalid or expired session", url).finish
        end
      else
        session = new_session()
        url = request.build_url(:session_id => session.id, :page_id => nil)
        Wee::RedirectResponse.new(url).finish
      end
    end

    protected

    def new_session
      session = @session_factory.call
      session.application = self
      insert_session(session)
      return session
    end

    def insert_session(session, retries=3)
      retries.times do
        @mutex.synchronize do
          id = @session_ids.next
          if @sessions[id].nil?
            @sessions[id] = session
            session.id = id
            return
          end
        end
      end
      raise
    end

  end # class Application

end # module Wee
