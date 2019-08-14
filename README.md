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
```

# Check Dynos are up

```
heroku ps -a <APP_NAME>
```
# SSH into Dyno

```
heroku ps:exec --dyno=web.1 -a <APP_NAME> 
```







