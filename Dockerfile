FROM ubuntu:14.04

# The following two sections adapted from https://github.com/Grokzen/docker-redis-cluster/blob/master/Dockerfile
# Initial update and install of dependency that can add apt-repos
RUN apt-get -y update && apt-get install -y software-properties-common python-software-properties

# Add global apt repos
RUN add-apt-repository -y "deb http://archive.ubuntu.com/ubuntu trusty multiverse" && \
    add-apt-repository -y "deb http://archive.ubuntu.com/ubuntu trusty-updates multiverse" && \
    add-apt-repository -y "deb http://archive.ubuntu.com/ubuntu trusty-backports multiverse"
RUN apt-get update && apt-get -y upgrade

# Install packages needed by seafile
RUN apt-get install -y wget python python-setuptools python-imaging sqlite3 apache2 python-flup libapache2-mod-fastcgi expect

# Install seafile
RUN mkdir /seafile && cd /seafile && wget https://bintray.com/artifact/download/seafile-org/seafile/seafile-server_4.2.3_x86-64.tar.gz && tar xaf seafile-server_4.2.3_x86-64.tar.gz

# Run the seafile installation script
ADD seafile-install.expect /seafile/seafile-server-4.2.3/
RUN cd /seafile/seafile-server-4.2.3 && ls && expect seafile-install.expect


###############################################################
## Now, configure apache for seafile according to these instructions
## http://manual.seafile.com/deploy/deploy_with_apache.html

ADD apache2/ /etc/apache2/
RUN rm /etc/apache2/sites-enabled/* && a2ensite seafile-ssl && a2enmod rewrite && a2enmod proxy_http && a2enmod ssl
RUN echo "FILE_SERVER_ROOT = 'https://127.0.0.1/seafhttp'" >> /seafile/seahub_settings.py
RUN sed -i "s/SERVICE_URL.*/SERVICE_URL = https:\/\/127.0.0.1/" /seafile/ccnet/ccnet.conf
RUN ln -s /seafile/seafile-server-latest/seahub/media/ /var/www/html

## To actually run seafile:
# /etc/init.d/apache2 start
# /root/seafile-4.2.3/seafile.sh start
# /root/seafile-4.2.3/seahub.sh start-fastcgi