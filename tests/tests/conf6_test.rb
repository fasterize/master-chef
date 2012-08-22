require File.join(File.dirname(__FILE__), '..', 'helper.rb')
require 'socket'

class TestConf6 < Test::Unit::TestCase

  include VmTestHelper
  include WaitHelper

  def test_conf6
    @vm.upload_json "conf6.json"
    @vm.run_chef

   # deploy and check node application
    exec_local "cd #{File.join(File.dirname(__FILE__), "..", "nodejs_app_test")} && TARGET=#{@vm.ip} cap deploy"

    @http.get 12345, "/"
    @http.assert_last_response_code 200
    @http.assert_last_response_body_regex /Hello World/

    hostname = @vm.capture("hostname").strip

    # check graphite
    @http.get 80, "/"
    @http.assert_last_response_code 200
    @http.assert_last_response_body_regex /Graphite Browser/

    # check collectd has sent data into graphite, using bucky
    wait "Waiting data from collected", 300, 10 do
      @http.get 80, "/render/?target=#{hostname}.cpu.0.idle&rawData=csv"
      @http.assert_last_response_code 200
      @http.assert_last_response_body_regex /#{hostname}/
    end

     # check statsd is connected to graphite
    wait "Waiting data from statsd", 300, 10 do
      @http.get 80, "/render/?target=statsd.numStats&rawData=csv"
      @http.assert_last_response_code 200
      @http.assert_last_response_body_regex /statsd.numStats/
    end

    # send data to statsd and check it's arrive in graphite
    UDPSocket.new.send("toto:1|c", 0, @vm.ip, 8125)
    wait "Waiting data sent to statsd appears in graphite", 300, 10 do
      @http.get 80, "/render/?target=stats.toto&rawData=csv"
      @http.assert_last_response_code 200
      @http.assert_last_response_body_regex /stats.toto/
    end

  end

end