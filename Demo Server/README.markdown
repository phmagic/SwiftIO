# Demo Server

Test echo server.

## Install with Vagrant:

Install vagrant via http://vagrantup.com or via homebrew cask:

    $ brew install cask
    $ brew cask install vagrant
    $ brew cask install virtualbox

Install a vagrant box (run following from the `Demo Server` directory)

    $ vagrant box add ubuntu/trusty64 

Start vagrant:

    $ vagrant up
    
The vagrant box will run the demo python server on port 8888. The vagrant box should be addressible with bonjour on hostname "vagrant.local."
    
Testing with netcat

    $ echo "Hello" | netcat vagrant.local. 8888
    Received 'Hello\n' from ('172.28.128.1', 57069)
    
