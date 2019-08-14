FROM alfresco/alfresco-imagemagick:1.3
ENV JAVA_OPTS -Xms512m -Xmx512m

RUN rm /bin/sh && ln -s /bin/bash /bin/sh

RUN yum install -y openssh-server openssh-clients curl python iproute
RUN echo "UsePrivilegeSeparation no" >> /etc/ssh/sshd_config

RUN adduser heroku
USER heroku
RUN mkdir $HOME/.ssh
RUN echo "UsePrivilegeSeparation no" >> $HOME/.ssh/sshd_config
RUN echo "alias l='ls -alh'" >> $HOME/.bashrc
ADD . $APP_HOME
ADD ./.profile.d /app/.profile.d

# override the default entrypoint in this image, which runs: /bin/sh -c "java $JAVA_OPTS -jar /usr/bin/alfresco-docker-imagemagick.jar"
ENTRYPOINT []
CMD source /app/.profile.d/heroku-exec.sh && sleep 60s
