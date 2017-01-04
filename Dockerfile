FROM resin/rpi-raspbian
MAINTAINER RajR

WORKDIR /data
RUN apt-get update
RUN apt-get -y -q install curl

RUN curl -s --remote-name http://packages.ntop.org/RaspberryPI/jessie_pi/armhf/nprobe/nprobe_7.5.161225-5549_armhf.deb
RUN sudo dpkg -i nprobe_7.5.161225-5549_armhf.deb || true
RUN apt-get -f install

RUN curl -s --remote-name http://packages.ntop.org/RaspberryPI/jessie_pi/armhf/ntopng/ntopng_2.5.161225-2055_armhf.deb
RUN sudo dpkg -i ntopng_2.5.161225-2055_armhf.deb || true
RUN apt-get -f install

RUN apt-get update

RUN rm -rf ntopng_2.5.161225-2055_armhf.deb
RUN rm -rf nprobe_7.5.161225-5549_armhf.deb

## ON OpenWRT-Router - enable NetFlow probes on all interfaces and point to RPI (say rpi.local) running ntopNG
# root@OpenWrt:~#  softflowd -D -v 5 -i br-lan -n rpi.local:5556 -T full 
# root@OpenWrt:~#  softflowd -D -v 5 -i eth1   -n rpi.local:5556 -T full 
# root@OpenWrt:~#  softflowd -D -v 5 -i eth0   -n rpi.local:5556 -T full

EXPOSE 3000 5556/UDP 5556/TCP

# Run
# 1. nprobe as a collector for NetFlow coming from NetFlow probes as send then to --zmq
# 2. start redis-server
# 3. Run for ever (in pro mode)- 
#    a. kill previous ntopng
#    b. start in daemon mode - ntopng to listen on --zmq tcp://127.0.0.1:5557 -e
#    c. sleep for 10mins
# 

CMD nprobe --collector-port 5556  --zmq tcp://*:5557 -G && \
    /etc/init.d/redis-server start && \
    while [ 1 ]; do \
      kill `ps -ef | grep "[0-9] ntopng -i tcp://127.0.0.1:5557" | awk '{print $2}'`; \
      ntopng -i tcp://127.0.0.1:5557 -e; sleep 600; \
    done

# On RPI (rpi.local) RUN ntopNG in docker container
# docker run --name ntopng -itd --restart=always -p 3000:3000 -p 5556:5556/udp -p 5556:5556/tcp rpi-ntopng
# UI available on http://rpi.local:3000
