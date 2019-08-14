FROM alfresco/alfresco-imagemagick:1.3

# Install the CLI - see https://devcenter.heroku.com/articles/heroku-cli#other-installation-methods
RUN curl https://cli-assets.heroku.com/install.sh | sh

RUN rm /bin/sh && ln -s /bin/bash /bin/sh

ENV APP_HOME /app  
RUN mkdir $APP_HOME  
WORKDIR $APP_HOME

RUN mkdir -p /opt/heroku

RUN yum -y install epel-release
ENV JAVA_OPTS -Xms512m -Xmx512m
RUN yum install -y openssh-server openssh-clients curl python iproute

RUN echo "UsePrivilegeSeparation no" >> /etc/ssh/sshd_config

# Install python and pip
RUN yum -y install https://centos7.iuscommunity.org/ius-release.rpm
RUN yum -y install python36u python36u-devel python36u-pip
ADD ./webapp/requirements.txt /tmp/requirements.txt

# Install dependencies
RUN pip3.6 install --no-cache-dir -q -r /tmp/requirements.txt

# Add our code
ADD ./webapp /opt/webapp/
WORKDIR /opt/webapp

# Expose is NOT supported by Heroku
# EXPOSE 5000 		

# Run the image as a non-root user
# none root stuff follows
RUN useradd -m heroku
RUN usermod -d $APP_HOME heroku
RUN chown heroku $APP_HOME
USER heroku

ADD . $APP_HOME 

ADD ./.profile.d /app/.profile.d

# Run the app.  CMD is required to run on Heroku
# $PORT is set by Heroku			
ADD ./.profile.d /app/.profile.d
CMD bash /app/.profile.d/heroku-exec.sh && gunicorn --bind 0.0.0.0:$PORT wsgi

#If app is in private space uncomment line 45 and comment line 42
#CMD gunicorn --bind 0.0.0.0:$PORT wsgi && bash /app/.profile.d/heroku-exec.sh
