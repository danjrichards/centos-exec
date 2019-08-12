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

# Build Image 

- `docker build -t centos-exec .`

# Deploy 

- `heroku container:login`
- `heroku container:push web -a <APP_NAME>`
- `heroku container:release web -a <APP_NAME>`

# Scale Dynos (Optional)

```
heroku ps:scale web=1

Scaling dynos... done, now running web at 1:Standard-1X
```

# Check Dynos are up

```
heroku ps -a <APP_NAME>

=== web (Standard-1X): /bin/sh -c gunicorn\ --bind\ 0.0.0.0:\$PORT\ wsgi\ \&\&\ bash\ /app/.profile.d/heroku-exec.sh (3)
web.1: up 2019/01/13 00:48:24 +0530 (~ 12m ago)
```
# SSH into Dyno

```
heroku ps:exec --dyno=web.1 -a <APP_NAME>

Establishing credentials... done
Connecting to web.1 on ⬢ exec-docker... 
~ $ 
```







