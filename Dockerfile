FROM alfresco/alfresco-imagemagick:1.3

RUN rm /bin/sh && ln -s /bin/bash /bin/sh

# RUN yum -y install epel-release
ENV JAVA_OPTS -Xms512m -Xmx512m
RUN yum install -y openssh-server openssh-clients curl python iproute
RUN echo "UsePrivilegeSeparation no" >> /etc/ssh/sshd_config

# Run the image as a non-root user
RUN adduser heroku
USER heroku
RUN echo "alias l='ls -alh'" >> /home/heroku/.bashrc

ADD . $APP_HOME 
ADD ./.profile.d /app/.profile.d

# Run the app
ENTRYPOINT []
CMD source /app/.profile.d/heroku-exec.sh && sleep 60s
