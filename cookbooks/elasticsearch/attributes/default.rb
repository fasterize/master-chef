
default[:elasticsearch] = {
  :user => 'elastic',
  :url => 'http://cloud.github.com/downloads/elasticsearch/elasticsearch/elasticsearch-0.19.10.tar.gz',
  :directory => '/opt/elasticsearch',
  :options => '',
  :host => '127.0.0.1',
  :http_port => 9200,
  :tcp_port => 9300,
  :min_memory => 128,
  :max_memory => [(node['memory']['total'][0..-3].to_i / 1024) / 2, 1024].min,
  :transport_zmq => {
    :enable => true,
    :listen => 'tcp://127.0.0.1:9700',
    :url => 'http://cloud.github.com/downloads/bpaquet/transport-zeromq/transport-zeromq-0.0.4.1-SNAPSHOT.zip',
  }
}
