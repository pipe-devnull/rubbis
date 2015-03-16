require 'socket'
require 'date'

module Rubbis
	class Server

		def initialize(port)
			@port = port
		end

		def listen

			readable = []
			clients = {}
			server = TCPServer.new(port)
			readable << server

			loop do
				ready_to_read, _ = IO.select(readable + clients.keys)

				ready_to_read.each do |socket|
					case socket
					when server
						child_socket = socket.accept
						clients[child_socket] = Handler.new(child_socket)
					else
						clients[socket].process!
					end
				end
			end
		ensure
			(readable + clients.keys).each do |socket|
				socket.close
			end
		end

		class Handler
			attr_reader :client

			def initialize(socket)
				@client = socket
				@buffer = ""
			end

			def process!
				header = client.gets.to_s

				return unless header[0] == '*'

				num_args = header[1..-1].to_i

				cmd = num_args.times.map do
					len = client.gets[1..-1].to_i
					client.read(len + 2).chomp
				end

				response = case cmd[0].downcase
				when 'ping' then "+PONG\r\n"
				when 'echo' then "$#{cmd[1].length}\r\n#{cmd[1]}\r\n"
				when 'time' then "+#{DateTime.now.to_s}\r\n"
				end

				client.write response
			end
			
	end

		private 

		attr_reader :port
	
	end
end
