# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2021-2024, by Samuel Williams.

# Prepare the application for start/restart.
def deploy
	# This task is typiclly run after the site is updated but before the server is restarted.
end

# Restart the application server.
def restart
	call 'falcon:supervisor:restart'
end

# Start the development server.
def default
	call 'utopia:development'
end
