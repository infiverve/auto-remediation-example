#begin
@log.trace("Started executing 'example:apache2_service' flintbit...")

@status_check_command="sudo service apache2 status"
@start_service_command="sudo service apache2 start"

def call_connector(connector_name,target,username,password,command,timeout)
  response = @call.connector(connector_name)
                  .set("target",target)
                  .set("username",username)
                  .set("password",password)
                  .set("command",command)
                  .set("timeout",timeout)
                  .sync
  return response
end

#Flintbit Input Parameters
@connector_name=@input.get("connector_name")     #Name of the SSH Connector
@target=@input.get("target")                     #Target machine where the command will be executed
@username=@input.get("username")                 #Target username
@password=@input.get("password")                 #Target password
@timeout=@input.get("timeout")                   #Timeout in milliseconds, taken by

if @connector_name.nil? || @connector_name.empty?
   @connector_name="ssh"
end
if @target.nil? || @target.empty?
   @output.exit(1,"missing required parameter: target")
end
if @username.nil? || @username.empty?
   @output.exit(1,"missing required parameter: username")
end
if @password.nil? || @password.empty?
   @output.exit(1,"missing required parameter: password")
end
if @timeout.nil? || @timeout.empty?
   @timeout=60000
end


@log.debug("flintbit input parameters are, connector name :: #{@connector_name} |
	                                         target ::         #{@target} |
                                           username ::         #{@username} |
                                           password ::         #{@password}")

@log.info("checking the status of apache2 service...")
status_check_response = call_connector(@connector_name,@target,@username,@password,@status_check_command,@timeout)

#Connector Response Meta Parameters
@response_exitcode=status_check_response.exitcode              #Exit status code
@response_message=status_check_response.message                #Execution status messages

#Connector Response Parameters
@result=status_check_response.get("result")             #Response Body

if @response_exitcode == 0
  @log.debug("successfully checked apache2 service status, where exitcode :: #{@response_exitcode} |
                                                                message :: #{@response_message} |
                                                                result:: #{@result}")

  if @result.include? "apache2 is not running"
        @log.info("apache2 service is not running..")
        @log.info("starting apache2 service...")
        response = call_connector(@connector_name,@target,@username,@password,@start_service_command,@timeout)
        @response_exitcode=response.exitcode
        @response_message=response.message
        @result=response.get("result")

        if @response_exitcode == 0
          @log.debug("successfully started apache2 service where, exitcode :: #{@response_exitcode} |
                                                                  message :: #{@response_message} |
                                                                  result:: #{@result}")
          @log.info("apache2 service is running on #{@target}...")
          @output.set("result",@result)
          @log.trace("Finished executing 'example:apache2_service' flintbit with success...")
        else
          @log.error("failed to start apache2 service where, exitcode :: #{@response_exitcode} |
                                                             message :: #{@response_message} |
                                                             error:: #{@result}")
          @output.set("error",@response_message)
          @output.exit(1,@response_message)
          @log.trace("finished executing 'example:apache2_service' flintbit with error...")
        end
  else
        @log.info("apache2 service is already running on #{@target}...")
        @output.set("result",@result)
        @log.trace("finished executing 'example:apache2_service' flintbit with success...")
  end

else
  @log.error("failed to check apache2 service status where, exitcode :: #{@response_exitcode} |
                                                            message :: #{@response_message}")
  @output.set("error",@response_message)
  @log.trace("finished executing 'example:apache2_service' flintbit with error...")
end
#end
