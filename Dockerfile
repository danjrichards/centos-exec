FROM alfresco/alfresco-imagemagick:1.3
ENV JAVA_OPTS -Xms512m -Xmx512m

RUN rm /bin/sh && ln -s /bin/bash /bin/sh

RUN yum install -y openssh-server openssh-clients curl python iproute

RUN adduser heroku
RUN echo "alias l='ls -alh'" >> $HOME/.bashrc
ADD . $APP_HOME
ADD ./.profile.d /app/.profile.d

# override the default entrypoint in this image, which is: ["/bin/sh", "-c", "java $JAVA_OPTS -jar /usr/bin/alfresco-docker-imagemagick.jar"]
ENTRYPOINT []
USER heroku
CMD source /app/.profile.d/heroku-exec.sh && java $JAVA_OPTS -jar /usr/bin/alfresco-docker-imagemagick.jar
# CMD java $JAVA_OPTS -jar /usr/bin/alfresco-docker-imagemagick.jar
