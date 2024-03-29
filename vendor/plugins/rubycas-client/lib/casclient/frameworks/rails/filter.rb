module CASClient
  module Frameworks
    module Rails
      class Filter
        cattr_reader :config, :log, :client
        
        # These are initialized when you call configure.
        @@config = nil
        @@client = nil
        @@log = nil
        
        class << self
          def filter(controller)
            raise "Cannot use the CASClient filter because it has not yet been configured." if config.nil?
            
            last_st = controller.session[:cas_last_valid_ticket]
            
            return false if single_sign_out(controller)

            st = read_ticket(controller)
            
            if st && last_st && 
                last_st.ticket == st.ticket && 
                last_st.service == st.service
              # warn() rather than info() because we really shouldn't be re-validating the same ticket. 
              # The only situation where this is acceptable is if the user manually does a refresh and 
              # the same ticket happens to be in the URL.
              log.warn("Re-using previously validated ticket since the ticket id and service are the same.")
              st = last_st
            elsif last_st &&
                !config[:authenticate_on_every_request] && 
                controller.session[client.username_session_key]
              # Re-use the previous ticket if the user already has a local CAS session (i.e. if they were already
              # previously authenticated for this service). This is to prevent redirection to the CAS server on every
              # request.
              # This behaviour can be disabled (so that every request is routed through the CAS server) by setting
              # the :authenticate_on_every_request config option to false. 
              log.debug "Existing local CAS session detected for #{controller.session[client.username_session_key].inspect}. "+
                "Previous ticket #{last_st.ticket.inspect} will be re-used."
              st = last_st
            end
            
            if st
              client.validate_service_ticket(st) unless st.has_been_validated?
              vr = st.response
              
              if st.is_valid?
                log.info("Ticket #{st.ticket.inspect} for service #{st.service.inspect} belonging to user #{vr.user.inspect} is VALID.")
                controller.session[client.username_session_key] = vr.user
                controller.session[client.extra_attributes_session_key] = vr.extra_attributes
                
                # RubyCAS-Client 1.x used :casfilteruser as it's username session key,
                # so we need to set this here to ensure compatibility with configurations
                # built around the old client.
                controller.session[:casfilteruser] = vr.user
                
                # Store the ticket in the session to avoid re-validating the same service
                # ticket with the CAS server.
                controller.session[:cas_last_valid_ticket] = st
                
                if vr.pgt_iou
                  log.info("Receipt has a proxy-granting ticket IOU. Attempting to retrieve the proxy-granting ticket...")
                  pgt = client.retrieve_proxy_granting_ticket(vr.pgt_iou)
                  if pgt
                    log.debug("Got PGT #{pgt.ticket.inspect} for PGT IOU #{pgt.iou.inspect}. This will be stored in the session.")
                    controller.session[:cas_pgt] = pgt
                    # For backwards compatibility with RubyCAS-Client 1.x configurations...
                    controller.session[:casfilterpgt] = pgt
                  else
                    log.error("Failed to retrieve a PGT for PGT IOU #{vr.pgt_iou}!")
                  end
                end
                
                f = store_service_session_lookup(st, controller.session.session_id)
                log.debug("Wrote service session lookup file to #{f.inspect} with session id #{controller.session.session_id.inspect}.")
                
                return true
              else
                log.warn("Ticket #{st.ticket.inspect} failed validation -- #{vr.failure_code}: #{vr.failure_message}")
                redirect_to_cas_for_authentication(controller)
                return false
              end
            else
              if returning_from_gateway?(controller)
                log.info "Returning from CAS gateway without authentication."
                
                if use_gatewaying?
                  log.info "This CAS client is configured to use gatewaying, so we will permit the user to continue without authentication."
                  return true
                else
                  log.warn "The CAS client is NOT configured to allow gatewaying, yet this request was gatewayed. Something is not right!"
                end
              end
              
              redirect_to_cas_for_authentication(controller)
              return false
            end
          end
          
          def configure(config)
            @@config = config
            @@config[:logger] = RAILS_DEFAULT_LOGGER unless @@config[:logger]
            @@client = CASClient::Client.new(config)
            @@log = client.log
          end
          
          def use_gatewaying?
            @@config[:use_gatewaying]
          end
          
          # Clears the given controller's local Rails session, does some local 
          # CAS cleanup, and redirects to the CAS logout page. Additionally, the
          # <tt>request.referer</tt> value from the <tt>controller</tt> instance 
          # is passed to the CAS server as a 'destination' parameter. This 
          # allows RubyCAS server to provide a follow-up login page allowing
          # the user to log back in to the service they just logged out from 
          # using a different username and password. Other CAS server 
          # implemenations may use this 'destination' parameter in different 
          # ways. 
          # If given, the optional <tt>service</tt> URL overrides 
          # <tt>request.referer</tt>.
          def logout(controller, service = nil)
            referer = controller.request.referer
            st = controller.session[:cas_last_valid_ticket]
            delete_service_session_lookup(st) if st
            controller.send(:reset_session)
            controller.send(:redirect_to, client.logout_url(referer))
          end
          
          def redirect_to_cas_for_authentication(controller)
            service_url = read_service_url(controller)
            redirect_url = client.add_service_to_login_url(service_url)
            
            if use_gatewaying?
              controller.session[:cas_sent_to_gateway] = true
              redirect_url << "&gateway=true"
            else
              controller.session[:cas_sent_to_gateway] = false
            end
            
            if controller.session[:previous_redirect_to_cas] &&
                controller.session[:previous_redirect_to_cas] > (Time.now - 1.second)
              log.warn("Previous redirect to the CAS server was less than a second ago. The client at #{controller.request.remote_ip.inspect} may be stuck in a redirection loop!")
              controller.session[:cas_validation_retry_count] ||= 0
              
              if controller.session[:cas_validation_retry_count] > 3
                log.error("Redirection loop intercepted. Client at #{controller.request.remote_ip.inspect} will be redirected back to login page and forced to renew authentication.")
                redirect_url += "&renew=1&redirection_loop_intercepted=1"
              end
              
              controller.session[:cas_validation_retry_count] += 1
            else
              controller.session[:cas_validation_retry_count] = 0
            end
            controller.session[:previous_redirect_to_cas] = Time.now
            
            log.debug("Redirecting to #{redirect_url.inspect}")
            controller.send(:redirect_to, redirect_url)
          end
          
          private
          def single_sign_out(controller)
            # Avoid calling raw_post (which may consume the post body) if
            # this seems to be a file upload
            if content_type = controller.request.headers["CONTENT_TYPE"] &&
                content_type =~ %r{^multipart/}
              return false
            end
            
            if controller.request.post? &&
                controller.request.raw_post =~ 
                  /^<samlp:LogoutRequest.*?<samlp:SessionIndex>(.*)<\/samlp:SessionIndex>/m
              # TODO: Maybe check that the request came from the registered CAS server? Although this might be
              #       pointless since it's easily spoofable...
              si = $~[1]
              log.debug "Intercepted logout request for CAS session #{si.inspect}."
              
              required_sess_store = CGI::Session::ActiveRecordStore
              current_sess_store  = ActionController::Base.session_options[:database_manager]
              
              if current_sess_store == required_sess_store
                session_id = read_service_session_lookup(si)
                session = CGI::Session::ActiveRecordStore::Session.find_by_session_id(session_id)
                session.destroy
                log.debug("Destroyed session id #{session_id.inspect} corresponding to service ticket #{si.inspect}.")
                
                return true
              else
                log.error "Cannot process logout request because this Rails application's session store is "+
                  " #{current_sess_store.name.inspect}. Single Sign-Out only works with the "+
                  " #{required_sess_store.name.inspect} session store."
                
                return false
              end
            else
              return false
            end
          end
          
          def read_ticket(controller)
            ticket = controller.params[:ticket]
            
            return nil unless ticket
            
            log.debug("Request contains ticket #{ticket.inspect}.")
            
            if ticket =~ /^PT-/
              ProxyTicket.new(ticket, read_service_url(controller), controller.params[:renew])
            else
              ServiceTicket.new(ticket, read_service_url(controller), controller.params[:renew])
            end
          end
          
          def returning_from_gateway?(controller)
            controller.session[:cas_sent_to_gateway]
          end
          
          def read_service_url(controller)
            if config[:service_url]
              log.debug("Using explicitly set service url: #{config[:service_url]}")
              return config[:service_url]
            end
            
            params = controller.params.dup
            params.delete(:ticket)
            service_url = controller.url_for(params)
            log.debug("Guessed service url: #{service_url.inspect}")
            return service_url
          end
          
          # Creates a file in tmp/sessions linking a SessionTicket
          # with the local Rails session id. The file is named
          # cas_sess.<session ticket> and its text contents is the corresponding 
          # Rails session id.
          # Returns the filename of the lookup file created.
          def store_service_session_lookup(st, sid)
            st = st.ticket if st.kind_of? ServiceTicket
            f = File.new(filename_of_service_session_lookup(st), 'w')
            f.write(sid)
            f.close
            return filename_of_service_session_lookup(st)
          end
          
          # Returns the local Rails session ID corresponding to the given
          # ServiceTicket. This is done by reading the contents of the
          # cas_sess.<session ticket> file created in a prior call to 
          # #store_service_session_lookup.
          def read_service_session_lookup(st)
            st = st.ticket if st.kind_of? ServiceTicket
            return IO.read(filename_of_service_session_lookup(st))
          end
          
          # Removes a stored relationship between a ServiceTicket and a local
          # Rails session id. This should be called when the session is being
          # closed.
          #
          # See #store_service_session_lookup.
          def delete_service_session_lookup(st)
            st = st.ticket if st.kind_of? ServiceTicket
            File.delete(filename_of_service_session_lookup(st))
          end
          
          # Returns the path and filename of the service session lookup file.
          # The returned path is relative, starting at RAILS_ROOT, so you may
          # need to prepend RAILS_ROOT to the return value and/or call
          # File.expand_path.
          def filename_of_service_session_lookup(st)
            st = st.ticket if st.kind_of? ServiceTicket
            return "tmp/sessions/cas_sess.#{st}"
          end
        end
      end
    
      class GatewayFilter < Filter
        def self.use_gatewaying?
          return true unless @@config[:use_gatewaying] == false
        end
      end
    end
  end
end