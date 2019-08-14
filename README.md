# centos-exec

This proof of concept app is intended to demonstrate SSH Tunneling for Docker Containers running CentOS in Heroku.
Prompted by https://gus.lightning.force.com/lightning/r/0D5B000000vWwrs/view


First clone the code

```
git clone https://github.com/danjrichards/centos-exec
```

Create Heroku App

```
heroku create

Creating app... done, ⬢ rocky-everglades-56640
https://rocky-everglades-56640.herokuapp.com/ | https://git.heroku.com/rocky-everglades-56640.git
```


# NOTES

$HEROKU_EXEC_URL = https://exec-manager.heroku.com:443/api/v2/7e81ec1f-a7f0-413f-8c74-3fcab3c4469f
which runs:
```
if ssh -V 2>&1 | grep -q -e '^OpenSSH_7\.2.*$' -e '^OpenSSH_6\.6.*$'; then
  echo "UsePrivilegeSeparation no" >> $HOME/.ssh/sshd_config
fi
```

and further down the script:
```
ssh -o ServerAliveInterval=30 -o ServerAliveCountMax=3 \
  -o StrictHostKeyChecking=no -i ${privateKey} \
  -p ${proxyPort} -R 0.0.0.0:0:localhost:${localPort} \
  -q -N ${proxyUser}@${proxyHost} > /dev/null 2>&1
```


The https://hub.docker.com/r/alfresco/alfresco-imagemagick image specifies an Entrypoint:
"Entrypoint": [
  "/bin/sh",
  "-c",
  "java $JAVA_OPTS -jar /usr/bin/alfresco-docker-imagemagick.jar"
],


## Build Image 
- `docker build -t centos-exec .`

## Run locally
- `docker container rm cexec && docker run --name cexec -p 2022:22 -p 8090:8090 centos-exec`
- `docker ps`
- `docker exec -it cexec /bin/bash`
- `docker stop cexec /bin/bash`

---

## Scale Dynos (Optional)
```
heroku ps:scale web=1
```

## Check Dynos are up
```
heroku ps -a <APP_NAME>
```

## SSH into Dyno
```
heroku ps:exec --dyno=web.1 -a <APP_NAME> 
```







