require 'redis'

require 'rubbis/server'

TEST_PORT = 6380

describe 'Rubbis', :acceptance do
 
  def client
    Redis.new(host: 'localhost', port: TEST_PORT)
  end

  def with_server
    server_thread = Thread.new do
      server = Rubbis::Server.new(TEST_PORT)
      server.listen
    end

    wait_for_open_port TEST_PORT

    yield
  rescue TimeoutError
    server_thread.value unless server_thread.alive?
    raise
  ensure
    Thread.kill(server_thread) if server_thread
  end

  def wait_for_open_port(port)
    time = Time.now
    while !check_port(port) && time > Time.now - 1
      sleep 0.01
    end

    raise TimeoutError unless check_port(port)
  end

  def check_port(port)
    `nc -z localhost #{port}`
    $?.success?
  end

  it 'responds to ping' do
    with_server do
    	c = client
    	c.without_reconnect do
		    expect(c.ping).to eq("PONG")
		    expect(c.ping).to eq("PONG")
		  end
    end
  end

  it 'responds to echo' do
  	with_server do
  		expect(client.echo("TEST")).to eq("TEST")
  		expect(client.echo("TEST")).to eq("TEST")
  	end
  end


  it 'supports multiple clients' do
  	with_server do
  		expect(client.echo("TEST")).to eq("TEST")
  	end
  end


end
